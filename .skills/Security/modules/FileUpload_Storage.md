# File Upload Storage — Deep Module

## Scope

Secure storage, serving, and access control for uploaded files: path traversal prevention, signed URLs, CDN security, and isolation.

---

## Storage Security Rules

### 1. Storage Location

```
RULE: Store uploaded files OUTSIDE the web root.

Web root storage (DANGEROUS):
  /var/www/html/uploads/user_file.php  → directly executable!

Safe storage:
  /var/data/uploads/{uuid}.{ext}       → not web-accessible
  s3://bucket-name/uploads/{uuid}.{ext} → cloud storage

Serve files through an application controller:
  GET /api/files/:fileId → controller checks auth → streams file from storage
```

### 2. File Naming

```
RULE: NEVER use the original file name for storage.

// Generate safe file name
const fileId = crypto.randomUUID();
const ext = getValidatedExtension(detectedMimeType);
const storagePath = `${fileId}.${ext}`;

// Store original name in database (sanitized) for display
const sanitizedName = originalName
  .replace(/[^a-zA-Z0-9._-]/g, '_')
  .substring(0, 255);

await db.files.create({
  id: fileId,
  originalName: sanitizedName,
  storagePath: storagePath,
  userId: req.user.id,
  mimeType: detectedMimeType,
  size: buffer.length
});
```

### 3. Path Traversal Prevention

```
RULE: Validate all file paths to prevent directory traversal.

Attack examples:
  filename: ../../../etc/passwd
  filename: ..\..\..\..\windows\system32\config\sam
  filename: ....//....//etc/passwd  (double encoding)
  filename: %2e%2e%2f%2e%2e%2fetc%2fpasswd  (URL encoded)

Prevention:
  const safePath = path.resolve(UPLOAD_DIR, filename);
  if (!safePath.startsWith(path.resolve(UPLOAD_DIR))) {
    throw new Error('Path traversal detected');
  }

  // Additional checks
  if (filename.includes('..') || filename.includes('\0')) {
    throw new Error('Invalid filename');
  }
```

### 4. Cloud Storage (S3, GCS, Azure Blob)

```
RULE: Use cloud storage with proper access controls.

S3 configuration:
  - Block all public access (default)
  - Enable server-side encryption (SSE-S3 or SSE-KMS)
  - Enable versioning (accidental deletion recovery)
  - Enable access logging
  - Set lifecycle rules (auto-delete temp files)
  - Use IAM roles (not access keys) for application access
  - Separate buckets for public and private files

Signed URLs for access:
  // Generate presigned URL (expires in 15 minutes)
  const url = await s3.getSignedUrl('getObject', {
    Bucket: 'my-bucket',
    Key: storagePath,
    Expires: 900  // 15 minutes
  });

  // For uploads (presigned PUT)
  const uploadUrl = await s3.getSignedUrl('putObject', {
    Bucket: 'my-bucket',
    Key: storagePath,
    ContentType: 'image/jpeg',
    Expires: 300  // 5 minutes
  });

RULE: Use signed URLs with short expiry for private files.
RULE: Never make storage buckets publicly accessible unless files are truly public.
```

### 5. CDN Security

```
IF serving files through a CDN:

For private files:
  - Use signed URLs or signed cookies
  - Set short expiry (15-60 minutes)
  - Include IP restriction if possible
  - Use custom origin headers for origin validation

For public files:
  - Set appropriate Cache-Control headers
  - Use a separate domain for user-uploaded content (sandbox domain)
  - Set Content-Disposition: attachment for downloads
  - Set X-Content-Type-Options: nosniff

Separate domain for user content:
  Main app: app.example.com
  User content: content.example-cdn.com (different domain entirely)
  This prevents cookie theft if user content contains XSS.
```

### 6. File Serving Headers

```
RULE: Set security headers when serving files.

// Forced download (safest)
Content-Disposition: attachment; filename="safe_name.ext"
Content-Type: application/octet-stream
X-Content-Type-Options: nosniff

// Inline display (for images, PDFs)
Content-Disposition: inline; filename="safe_name.ext"
Content-Type: image/jpeg  (correct, verified MIME type)
X-Content-Type-Options: nosniff
Content-Security-Policy: sandbox

// For user HTML/SVG (if allowed, serve from sandbox domain)
Content-Security-Policy: sandbox; default-src 'none'; img-src 'self'; style-src 'unsafe-inline'
X-Content-Type-Options: nosniff
```

### 7. Access Control

```
RULE: Check authorization before serving every file.

async function serveFile(req, res) {
  const file = await db.files.findById(req.params.fileId);
  if (!file) return res.status(404).send('Not found');
  
  // Authorization check
  if (file.visibility === 'private' && file.userId !== req.user?.id) {
    return res.status(403).send('Forbidden');
  }
  
  // Stream file with security headers
  res.set({
    'Content-Type': file.mimeType,
    'Content-Disposition': `inline; filename="${file.sanitizedName}"`,
    'X-Content-Type-Options': 'nosniff',
    'Cache-Control': 'private, max-age=3600'
  });
  
  const stream = storage.getReadStream(file.storagePath);
  stream.pipe(res);
}
```

### 8. Cleanup and Lifecycle

```
RULE: Implement file lifecycle management.

Temporary files:
  - Delete after processing (success or failure)
  - Cleanup cron job for orphaned temp files (older than 1 hour)
  - Monitor temp directory size

Permanent files:
  - Set retention policy based on business rules
  - Implement soft delete (mark deleted, hard delete after 30 days)
  - Handle cascade deletion (user deleted → delete their files)
  - Log all deletion events

Storage quota:
  - Set per-user storage limits
  - Track usage per user/tenant
  - Reject uploads when quota exceeded
  - Alert on rapid storage growth (potential abuse)
```

---

## References

- OWASP File Upload Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html
- AWS S3 Security Best Practices: https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html
