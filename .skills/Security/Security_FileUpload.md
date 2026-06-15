# Security — File Upload

## Scope

This module covers security for any file upload feature: images, documents, media, attachments, and user-generated content stored as files.

## Sub-Router

```
IF task contains [Validate, MIME, Extension, File Type, File Size, Magic Bytes, Image Processing, Resize, Thumbnail]
    LOAD modules/FileUpload_Validation.md

IF task contains [Storage, S3, Blob, CDN, File Path, Directory, Serve File, Download, Static File, File Access]
    LOAD modules/FileUpload_Storage.md
```

## Universal File Upload Security Rules

### 1. Never Trust Client Data

```
RULE: Every file attribute sent by the client can be spoofed.

Untrusted attributes:
- File name → can contain path traversal (../../etc/passwd)
- File extension → can be faked (.jpg but actually .php)
- Content-Type header → can be spoofed (image/jpeg but actually application/x-php)
- File size (Content-Length) → can be manipulated

ALWAYS validate server-side. Client-side validation is UX only.
```

### 2. File Name Security

```
RULE: Never use the original file name for storage.

Safe file naming:
1. Generate random file name: UUID v4 or CSPRNG
2. Determine extension from validated file content (not from client)
3. Final name: {random_id}.{validated_extension}
4. Store original name in database (sanitized) for display only

If original name must be preserved:
- Strip path components (no / or \ or ..)
- Remove null bytes (\0)
- Whitelist allowed characters (alphanumeric, hyphen, underscore, dot)
- Limit length (max 255 characters)
- Prevent double extensions (file.php.jpg → reject or strip)
```

### 3. File Size Limits

```
RULE: Enforce file size limits at multiple layers.

Layers:
1. Web server level (Nginx: client_max_body_size, Apache: LimitRequestBody)
2. Application middleware (before file reaches handler)
3. Application handler (per file type)
4. Storage quota (per user / per tenant)

Recommended limits:
- Profile picture: 5 MB
- Document: 25 MB
- Video: 500 MB
- Generic attachment: 10 MB

RULE: Reject oversized files as early as possible (streaming check, not full read).
RULE: Track storage usage per user to prevent abuse.
```

### 4. File Type Validation

```
RULE: Validate file type using multiple methods (defense in depth).

Validation layers:
1. Extension whitelist (ONLY allow expected extensions)
2. Content-Type header check (secondary check only)
3. Magic bytes / file signature validation (primary check)
4. Deep content validation (optional but recommended)

Magic bytes examples:
- JPEG: FF D8 FF
- PNG: 89 50 4E 47
- GIF: 47 49 46 38
- PDF: 25 50 44 46
- ZIP: 50 4B 03 04
- DOCX: 50 4B 03 04 (ZIP-based, needs deeper check)

NEVER allow:
- Executable files (.exe, .bat, .cmd, .sh, .ps1, .msi, .dll, .so)
- Script files (.php, .jsp, .asp, .aspx, .py, .rb, .pl, .cgi)
- HTML files (.html, .htm, .svg with scripts, .xml)
- Server config (.htaccess, web.config, .env)
```

### 5. Image-Specific Security

```
IF uploading images:

RULE: Re-process images to strip metadata and embedded payloads.

Checklist:
- Strip EXIF data (may contain GPS, device info, embedded thumbnails)
- Re-encode the image (read pixels, write new file)
- Resize to maximum dimensions (prevent decompression bombs)
- Validate image dimensions (max width/height)
- Check pixel count limit (width × height ≤ max_pixels)
- Reject animated images with too many frames
- Convert to safe format (re-encode as JPEG/PNG/WebP)
- Use a sandboxed image processing library

Decompression bomb prevention:
- JPEG: 100 MP max
- PNG: 25 MP max (PNG decompression is more expensive)
- GIF: 50 frames max, 25 MP max per frame
```

### 6. Storage Architecture

```
RULE: Store uploaded files outside the web root.

Architecture:
1. Upload to temporary directory (server-side)
2. Validate file (type, size, content)
3. Process file (resize, strip metadata, scan)
4. Move to permanent storage (outside web root or cloud storage)
5. Serve through a controller that checks authorization

NEVER:
- Store files in the web-accessible directory
- Allow directory listing where files are stored
- Use predictable file paths (sequential IDs)
- Serve files without access control checks

Recommended storage:
- Cloud object storage (S3, GCS, Azure Blob) with signed URLs
- Dedicated file server with access control
- CDN with signed URLs for public files
```

### 7. Virus / Malware Scanning

```
RULE: Scan uploaded files for malware when feasible.

Options:
- ClamAV (open source, self-hosted)
- VirusTotal API (cloud-based, rate limited)
- Cloud provider scanning (S3 Malware Protection, etc.)

Flow:
1. Upload to quarantine storage
2. Trigger virus scan
3. If clean → move to permanent storage
4. If infected → delete + log + notify user
5. If scan unavailable → hold in quarantine + alert admin
```

### 8. File Serving Security

```
RULE: Serve files with proper security headers.

Headers for served files:
- Content-Disposition: attachment; filename="safe_name.ext" (force download)
  OR Content-Disposition: inline (only for safe types: images, PDF)
- Content-Type: correct MIME type (never application/octet-stream for known types)
- X-Content-Type-Options: nosniff
- Cache-Control: appropriate caching policy
- Content-Security-Policy: sandbox (for inline display)

For user-uploaded HTML/SVG (if allowed):
- Serve from a separate domain (sandbox domain)
- Use Content-Security-Policy: sandbox
- Use X-Content-Type-Options: nosniff
- Never execute scripts from user-uploaded content
```

### 9. Temporary File Cleanup

```
RULE: Clean up temporary upload files.

- Set maximum age for temp files (1 hour)
- Run cleanup job periodically (cron / scheduled task)
- Delete temp files after processing (success or failure)
- Handle cleanup in error paths (try/finally)
- Monitor temp directory size
- Alert on growing temp directory (potential leak)
```

### 10. Audit Trail

```
RULE: Log all file upload/download/delete operations.

Log fields:
- Timestamp
- User ID
- Action (upload, download, delete, share)
- File ID / path
- File name (original + stored)
- File size
- File type (validated)
- Source IP
- Success/failure
- Scan result (if malware scan enabled)
```
