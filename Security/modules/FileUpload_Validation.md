# File Upload Validation — Deep Module

## Scope

Deep validation techniques for uploaded files: MIME type verification, magic bytes, content analysis, and decompression bomb prevention.

---

## Validation Layers

### 1. Extension Whitelist

```
RULE: Only allow explicitly expected file extensions.

const ALLOWED_EXTENSIONS = {
  image: ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'],
  document: ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt', '.csv'],
  video: ['.mp4', '.webm', '.mov'],
  audio: ['.mp3', '.wav', '.ogg', '.m4a']
};

function validateExtension(filename, category) {
  const ext = path.extname(filename).toLowerCase();
  return ALLOWED_EXTENSIONS[category]?.includes(ext) || false;
}

NEVER allow:
  .exe .bat .cmd .sh .ps1 .msi .dll .so .dylib     — Executables
  .php .jsp .asp .aspx .py .rb .pl .cgi .war        — Server scripts
  .html .htm .xhtml .xml .svg (unless sanitized)     — Can contain scripts
  .htaccess .web.config .env .ini .conf              — Server config
  .jar .class .com .scr .pif .vbs .wsf .js           — Code execution

Double extension prevention:
  file.php.jpg → check ALL extensions, not just the last one
  file.jpg.php → reject (server may execute based on last extension)
  
  function hasDoubleExtension(filename) {
    const parts = filename.split('.');
    return parts.length > 2;  // Reject or strip extra extensions
  }
```

### 2. Magic Bytes Validation

```
RULE: Verify file content matches expected type via magic bytes (file signature).

Magic bytes map:
  JPEG:  [0xFF, 0xD8, 0xFF]
  PNG:   [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
  GIF87: [0x47, 0x49, 0x46, 0x38, 0x37, 0x61]
  GIF89: [0x47, 0x49, 0x46, 0x38, 0x39, 0x61]
  PDF:   [0x25, 0x50, 0x44, 0x46]
  ZIP:   [0x50, 0x4B, 0x03, 0x04]  (also DOCX, XLSX, PPTX, JAR)
  WEBP:  [0x52, 0x49, 0x46, 0x46, .., .., .., .., 0x57, 0x45, 0x42, 0x50]
  MP4:   [..., 0x66, 0x74, 0x79, 0x70] at offset 4
  MP3:   [0xFF, 0xFB] or [0x49, 0x44, 0x33] (ID3 tag)
  WAV:   [0x52, 0x49, 0x46, 0x46, .., .., .., .., 0x57, 0x41, 0x56, 0x45]

Libraries for detection:
  Node.js: file-type, mmmagic
  Python:  python-magic, filetype
  Java:    Apache Tika
  C#:      Mime-Detective
  Go:      http.DetectContentType(), gabriel-vasile/mimetype
  PHP:     finfo_file()

// Node.js example
const { fileTypeFromBuffer } = require('file-type');
const type = await fileTypeFromBuffer(buffer);
if (!type || !ALLOWED_MIMES.includes(type.mime)) {
  throw new Error('Invalid file type');
}
```

### 3. Content-Type Header Validation

```
RULE: Content-Type is a SECONDARY check. Never rely on it alone.

The client can set any Content-Type — it's trivially spoofed.

Use as additional validation layer:
  if (req.file.mimetype !== detectedMimeType) {
    // Mismatch between declared and actual type → suspicious
    reject();
  }
```

### 4. Image-Specific Validation

```
RULE: Re-process images to neutralize embedded payloads.

Image bombs / decompression bombs:
- A 42KB PNG can decompress to 1 GB+ in memory
- Check pixel dimensions BEFORE full decompression

// Node.js (sharp)
const metadata = await sharp(buffer).metadata();
if (metadata.width > 10000 || metadata.height > 10000) reject();
if (metadata.width * metadata.height > 100_000_000) reject();  // 100 MP limit

// Re-encode to strip metadata and payloads
const clean = await sharp(buffer)
  .resize(maxWidth, maxHeight, { fit: 'inside', withoutEnlargement: true })
  .flatten({ background: '#ffffff' })  // Remove alpha for JPEG
  .jpeg({ quality: 85 })              // Re-encode
  .toBuffer();

EXIF stripping:
- GPS coordinates (privacy risk)
- Camera serial number
- Embedded thumbnails (may contain different image)
- Software/edit history

SVG validation (if SVG allowed):
- SVGs can contain <script>, <foreignObject>, event handlers
- Parse and whitelist allowed SVG elements
- Remove all <script>, <style>, event handlers (onclick, onload)
- Remove <foreignObject>, <use> with external references
- Or better: convert SVG to PNG server-side
```

### 5. Document Validation

```
IF accepting documents (PDF, DOCX, XLSX):

PDF risks:
- JavaScript in PDF (disable execution)
- External links and form actions
- Embedded files
- Launch actions (can execute programs)
- Use a PDF sanitizer or re-render PDFs

Office document risks (DOCX, XLSX, PPTX):
- Macro-enabled formats (.docm, .xlsm) → BLOCK
- OLE objects (embedded executables)
- External data connections
- DDE (Dynamic Data Exchange) attacks
- Use file-type detection to distinguish .docx from .docm

Validation:
- Check that ZIP-based formats (DOCX, XLSX) are valid ZIP files
- Scan for macros and reject if found
- Check for OLE objects
- Scan with antivirus
```

### 6. Archive Validation

```
IF accepting archives (ZIP, TAR, RAR):

Zip bomb detection:
- Check compression ratio (reject if > 100:1)
- Check uncompressed size before extraction
- Limit number of files in archive
- Limit nesting depth (zip within zip)
- Set maximum extraction size
- Extract to a size-limited temp directory

Zip slip (path traversal in archive):
- Archive entry names can contain: ../../../etc/passwd
- ALWAYS validate entry paths before extraction
- Ensure extracted paths stay within target directory
- Resolve symlinks and check final path

// Safe extraction
for (const entry of archive.entries()) {
  const fullPath = path.resolve(targetDir, entry.name);
  if (!fullPath.startsWith(path.resolve(targetDir))) {
    throw new Error('Path traversal detected in archive');
  }
}
```

---

## References

- OWASP File Upload Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html
- File Signatures Database: https://www.garykessler.net/library/file_sigs.html
