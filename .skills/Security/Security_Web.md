# Security — Web

## Scope

This module covers security for browser-rendered content: HTML pages, SPAs, SSR apps, forms, search interfaces, rich text editors, and template engines.

## Sub-Router

```
IF task contains [HTML, Template, Rich Text, Markdown, User Content Display, innerHTML, dangerouslySetInnerHTML, v-html, [innerHTML]]
    LOAD modules/XSS.md

IF task contains [Form, POST, State Change, Delete, Update, Action, Submit]
    LOAD modules/CSRF.md

IF task contains [Script Policy, Inline Script, External Resource, iframe, embed, object, CSP]
    LOAD modules/CSP.md

IF task contains [Cookie, Set-Cookie, Remember Me]
    LOAD modules/Cookie.md
```

## Universal Web Security Rules

These rules apply to ALL web tasks regardless of sub-module:

### 1. Output Encoding

```
RULE: Never render user-controlled data without context-appropriate encoding.

- HTML Body    → HTML-encode ( < > & " ' )
- HTML Attribute → Attribute-encode + always quote attributes
- JavaScript   → JS-encode or use JSON.stringify()
- URL Parameter → URL-encode (encodeURIComponent)
- CSS Value    → CSS-encode or use whitelist
```

### 2. HTTP Security Headers

```
MANDATORY headers for every web response:

Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
Content-Security-Policy: [see modules/CSP.md for details]
```

### 3. Input Validation

```
RULE: Validate ALL input on the server side. Client-side validation is UX only.

- Type check (string, number, boolean, date)
- Length limit (min/max)
- Format validation (regex for emails, URLs, phone numbers)
- Range check (min/max for numbers, dates)
- Whitelist where possible (enum values, allowed characters)
- Reject null bytes (\0)
```

### 4. DOM Security

```
DANGEROUS — avoid or sanitize:
- element.innerHTML = userInput
- document.write(userInput)
- eval(userInput)
- setTimeout/setInterval with string argument
- new Function(userInput)
- location.href = userInput (open redirect)
- window.open(userInput)
- postMessage without origin check

SAFE alternatives:
- element.textContent = userInput
- createElement + appendChild
- DOMPurify.sanitize(userInput) for HTML
- URL validation with whitelist for redirects
```

### 5. Third-Party Resources

```
RULE: All external scripts/styles MUST use Subresource Integrity (SRI).

<script src="https://cdn.example.com/lib.js"
        integrity="sha384-HASH"
        crossorigin="anonymous"></script>

RULE: Minimize third-party dependencies. Each dependency is an attack surface.
RULE: Pin versions. Never use "latest" in production.
```

### 6. Sensitive Data in Frontend

```
NEVER expose in client-side code:
- API keys / secrets
- Database connection strings
- Internal URLs / IP addresses
- Admin endpoints
- User PII beyond what's displayed
- Encryption keys
- Server configuration

Use environment variables and server-side proxies instead.
```

### 7. Error Handling

```
RULE: Never expose stack traces, SQL errors, or internal paths to users.

Production error responses:
- Generic error message to user
- Unique error ID for correlation
- Full details logged server-side only
```

### 8. Clickjacking Prevention

```
RULE: Set X-Frame-Options: DENY (or SAMEORIGIN if iframes needed).
RULE: Use CSP frame-ancestors directive.
RULE: For legacy browsers, use frame-busting JavaScript as fallback.
```

### 9. Open Redirect Prevention

```
RULE: Never redirect to user-controlled URLs without validation.

Safe patterns:
- Whitelist allowed redirect domains
- Use relative paths only
- Map redirect targets to enum values (redirect=dashboard, not redirect=https://evil.com)
- Validate URL starts with / and does not start with // or /\
```

### 10. HTML Sanitization

```
IF accepting rich text / HTML from users:
- Use a proven sanitizer (DOMPurify, Bleach, Sanitize)
- Whitelist allowed tags and attributes (do NOT blacklist)
- Strip all event handlers (onclick, onerror, onload, etc.)
- Strip all javascript: and data: URIs in href/src
- Strip all <script>, <style>, <iframe>, <object>, <embed>, <form>
- Re-sanitize on every render, not just on save
```
