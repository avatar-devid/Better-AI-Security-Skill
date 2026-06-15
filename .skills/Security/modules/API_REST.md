# API REST Security — Deep Module

## Scope

Security specific to RESTful HTTP APIs: endpoint design, input validation, CORS, versioning, and HTTP method security.

---

## REST-Specific Security Rules

### 1. HTTP Method Security

```
RULE: Use correct HTTP methods and enforce them.

GET:     Read-only. MUST NOT change state. Safe to cache/retry.
POST:    Create resource. Not idempotent.
PUT:     Full resource update. Idempotent.
PATCH:   Partial update. May not be idempotent.
DELETE:  Remove resource. Idempotent.
OPTIONS: CORS preflight. No auth needed.
HEAD:    Like GET but no body. Same auth as GET.

RULE: Block unused HTTP methods (405 Method Not Allowed).
RULE: TRACE and TRACK must be disabled (XST attack vector).
RULE: GET requests MUST NOT change state (CSRF risk — browsers send GET freely).
```

### 2. URL and Path Security

```
RULE: Never expose sensitive data in URLs.

URLs are logged in:
- Server access logs
- Proxy logs
- Browser history
- Referrer headers
- CDN logs

NEVER put in URL:
- Passwords, tokens, API keys → use headers
- PII (email, phone, SSN) → use request body
- Session IDs → use cookies

SAFE URL patterns:
  GET  /api/v1/users/{userId}           (user ID is non-sensitive)
  POST /api/v1/users/{userId}/actions   (sensitive data in body)

Use opaque IDs in URLs:
  ✓ /api/users/a1b2c3d4-e5f6   (UUID — not guessable)
  ✗ /api/users/1                (sequential — enumerable → IDOR)
```

### 3. Input Validation Patterns

```
Path parameters:
- Validate format (UUID, integer, slug)
- Reject path traversal (../, ..\, %2e%2e)
- Whitelist allowed characters

Query parameters:
- Validate type (number, string, boolean, date)
- Enforce length limits
- Validate against enum for known values
- Default values for optional params (server-controlled)
- Reject unknown parameters (strict mode) or ignore them

Request body:
- Schema validation (JSON Schema, Zod, Joi, Pydantic)
- Reject unknown fields (no mass assignment)
- Enforce required fields
- Type check every field
- Length limits on strings
- Range limits on numbers
- Array length limits
- Nesting depth limits (max 5-10 levels)
- Reject null bytes in strings

Content-Type enforcement:
- Verify Content-Type header matches expected format
- Reject requests with unexpected Content-Type
- For JSON APIs: require application/json
```

### 4. Response Security

```
Minimal response pattern:
- Return only requested fields (field selection)
- Never return internal fields (password hash, internal_id, __v)
- Use DTOs/serializers to control output shape
- Consistent error format (never leak stack traces)
- Pagination: enforce max page size server-side

Response headers:
  Content-Type: application/json; charset=utf-8
  X-Content-Type-Options: nosniff
  Cache-Control: no-store (for sensitive data)
  X-Request-Id: {unique-id} (for correlation, not internal IDs)

Error responses:
  // SAFE
  { "error": { "code": "NOT_FOUND", "message": "Resource not found" } }

  // UNSAFE — leaks internals
  { "error": "Table 'prod_db.users' doesn't exist", "stack": "..." }
```

### 5. CORS Configuration

```
RULE: Configure CORS explicitly for every API.

Strict configuration:
  Access-Control-Allow-Origin: https://app.example.com  (specific origin)
  Access-Control-Allow-Methods: GET, POST, PUT, DELETE
  Access-Control-Allow-Headers: Content-Type, Authorization
  Access-Control-Allow-Credentials: true  (only if cookies/auth needed)
  Access-Control-Max-Age: 3600  (cache preflight for 1 hour)
  Access-Control-Expose-Headers: X-Request-Id

NEVER:
  Access-Control-Allow-Origin: *              (with credentials)
  Access-Control-Allow-Headers: *             (too permissive)
  Access-Control-Allow-Methods: *             (too permissive)
  Origin header reflected without validation   (any origin allowed)

Public APIs (no auth, no cookies):
  Access-Control-Allow-Origin: *              (acceptable ONLY for truly public read-only APIs)
  Access-Control-Allow-Credentials: false     (must be false with wildcard)
```

### 6. Pagination & Filtering Security

```
Pagination:
- Enforce maximum page size (e.g., max 100 items)
- Use cursor-based pagination for large datasets (not offset)
- Default to small page size (20-25)
- Validate page/limit parameters as positive integers
- Don't reveal total count if it's sensitive information

Filtering:
- Whitelist allowed filter fields
- Whitelist allowed operators (eq, gt, lt, contains)
- Don't allow filtering on sensitive fields (password, token)
- Validate filter values (type, format, length)
- Prevent ReDoS in text search (limit regex complexity or don't use regex)

Sorting:
- Whitelist allowed sort fields
- Validate sort direction (ASC/DESC only)
- Default sort order if not specified
- Index sorted columns for performance (prevent DoS via slow queries)
```

### 7. Bulk Operations Security

```
IF API supports bulk/batch operations:

- Limit batch size (max 100 items per request)
- Validate every item in the batch individually
- Authorize every item individually (user may own some but not all)
- Use transactions for atomic bulk operations
- Return per-item status (which succeeded, which failed)
- Rate limit batch endpoints more aggressively
- Log bulk operations specially (potential for mass data exfiltration/modification)
```

### 8. File Download via API

```
IF API serves file downloads:

- Validate file path / ID (prevent path traversal)
- Check authorization for the specific file
- Set Content-Disposition: attachment (force download, prevent browser rendering)
- Set correct Content-Type
- Set X-Content-Type-Options: nosniff
- Stream files for large downloads (don't load entire file into memory)
- Rate limit download endpoints
- Log all file access
```

---

## References

- OWASP REST Security Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html
- OWASP API Security Top 10: https://owasp.org/API-Security/
