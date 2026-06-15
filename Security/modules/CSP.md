# CSP (Content Security Policy) — Deep Module

## Threat Description

Content Security Policy is a browser security mechanism that mitigates XSS, data injection, and clickjacking attacks by controlling which resources the browser is allowed to load and execute.

**Purpose**: Defense-in-depth against XSS. Even if an attacker finds an injection point, CSP prevents execution of injected scripts.

---

## CSP Header Format

```
Delivered as HTTP response header:
Content-Security-Policy: directive1 source1 source2; directive2 source3;

Or as HTML meta tag (limited — cannot use frame-ancestors, report-uri, sandbox):
<meta http-equiv="Content-Security-Policy" content="default-src 'self';">

RULE: Prefer HTTP header over meta tag (more directives supported, harder to bypass).
```

---

## Key Directives

### Source Directives

```
default-src     Fallback for all resource types not explicitly set
script-src      JavaScript sources
style-src       CSS sources
img-src         Image sources
font-src        Font sources
connect-src     AJAX, WebSocket, EventSource, fetch() destinations
media-src       Audio/video sources
object-src      Plugin sources (Flash, Java — should be 'none')
frame-src       iframe sources
child-src       Web workers + iframes (deprecated, use worker-src + frame-src)
worker-src      Web worker / Service worker / Shared worker sources
manifest-src    Web app manifest source
base-uri        Restrict <base> tag URLs
form-action     Restrict form submission targets
frame-ancestors Restrict who can embed this page (replaces X-Frame-Options)
```

### Source Values

```
'none'              Block all sources for this directive
'self'              Same origin only (scheme + host + port)
'unsafe-inline'     Allow inline scripts/styles (DEFEATS CSP PURPOSE — avoid)
'unsafe-eval'       Allow eval(), new Function(), etc. (dangerous — avoid)
'strict-dynamic'    Trust scripts loaded by already-trusted scripts
'unsafe-hashes'     Allow specific inline event handlers by hash
https:              Any HTTPS source
data:               data: URIs (use cautiously — XSS vector for scripts)
blob:               blob: URIs
'nonce-{random}'    Allow specific inline elements with matching nonce
'sha256-{hash}'     Allow specific inline elements with matching hash
*.example.com       Wildcard subdomain
https://cdn.example.com  Specific origin
```

---

## Recommended Policies

### Strict Policy (Best Security)

```
Content-Security-Policy:
  default-src 'none';
  script-src 'strict-dynamic' 'nonce-{RANDOM}';
  style-src 'self' 'nonce-{RANDOM}';
  img-src 'self' data: https:;
  font-src 'self' https://fonts.gstatic.com;
  connect-src 'self' https://api.example.com;
  frame-src 'none';
  object-src 'none';
  base-uri 'self';
  form-action 'self';
  frame-ancestors 'none';
  upgrade-insecure-requests;

Implementation:
1. Generate random nonce on EVERY response (not per session)
2. Add nonce to all <script> and <style> tags
3. 'strict-dynamic' allows scripts loaded by nonced scripts to execute

<script nonce="RANDOM_NONCE_HERE">
  // This script is allowed
  // Scripts dynamically loaded by this script are also allowed ('strict-dynamic')
</script>
```

### Moderate Policy (Compatibility)

```
Content-Security-Policy:
  default-src 'self';
  script-src 'self' https://cdn.example.com;
  style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
  img-src 'self' data: https:;
  font-src 'self' https://fonts.gstatic.com;
  connect-src 'self' https://api.example.com;
  frame-src 'none';
  object-src 'none';
  base-uri 'self';
  form-action 'self';
  frame-ancestors 'none';

WARNING: 'unsafe-inline' for styles weakens protection but is often necessary
         for CSS-in-JS libraries and inline styles.
```

### Report-Only Mode (Testing)

```
Use Report-Only to test CSP without breaking anything:

Content-Security-Policy-Report-Only:
  default-src 'self';
  script-src 'self';
  report-uri /csp-report;
  report-to csp-endpoint;

Reports are sent as JSON:
{
  "csp-report": {
    "document-uri": "https://example.com/page",
    "violated-directive": "script-src 'self'",
    "blocked-uri": "https://evil.com/script.js",
    "original-policy": "default-src 'self'; script-src 'self'"
  }
}

RULE: Deploy CSP in Report-Only first, monitor for 1-2 weeks, then enforce.
```

---

## Nonce Implementation

```
RULE: Generate a new nonce for EVERY HTTP response. Never reuse.

Server-side nonce generation:
- Node.js:   crypto.randomBytes(16).toString('base64')
- Python:    secrets.token_urlsafe(16)
- Java:      SecureRandom → Base64
- C#:        RandomNumberGenerator → Base64
- PHP:       base64_encode(random_bytes(16))

Framework integration:

Express.js:
app.use((req, res, next) => {
  res.locals.nonce = crypto.randomBytes(16).toString('base64');
  res.setHeader('Content-Security-Policy',
    `script-src 'nonce-${res.locals.nonce}' 'strict-dynamic'; ...`);
  next();
});
// In template: <script nonce="<%= nonce %>">

Django:
# django-csp package handles nonce generation automatically
# {{ request.csp_nonce }} in templates

Next.js:
// next.config.js → headers() function
// Or use middleware to set CSP with nonce
// Read nonce from headers in components
```

---

## CSP for Single Page Applications (SPA)

```
SPAs have unique CSP challenges:

React/Vue/Angular with build tools:
- Scripts are in separate files (good — no inline scripts)
- Styles may be injected inline by bundlers (problem)
- Use nonce for style injection: configure Webpack/Vite to use nonce

Webpack nonce:
// Set __webpack_nonce__ before any imports
__webpack_nonce__ = document.querySelector('meta[name="csp-nonce"]').content;

Vite:
// Use vite-plugin-csp for nonce injection

React (Create React App):
// Built-in support: INLINE_RUNTIME_CHUNK=false in .env

Angular:
// angular.json: set "extractCss": true to avoid inline styles
// Use ng-csp attribute on <html> tag

Avoid 'unsafe-inline' for scripts. If impossible:
- Use hash-based CSP ('sha256-HASH_OF_INLINE_SCRIPT')
- Or nonce-based CSP
- 'unsafe-inline' is ignored when nonce or hash is present (with 'strict-dynamic')
```

---

## Common CSP Mistakes

```
1. Using 'unsafe-inline' for scripts (defeats XSS protection)
2. Using 'unsafe-eval' (allows eval-based XSS)
3. Whitelisting entire CDN domains (CDN may host malicious scripts)
   Use 'strict-dynamic' + nonce instead
4. Using wildcard (*) in script-src
5. Missing default-src (resources not covered by specific directives are allowed)
6. Forgetting object-src 'none' (Flash-based XSS)
7. Forgetting base-uri 'self' (base tag hijacking)
8. Not setting frame-ancestors (clickjacking)
9. Same nonce for all requests (defeats purpose)
10. CSP in meta tag only (missing frame-ancestors support)
11. Not monitoring CSP reports (missing violations)
12. Overly permissive connect-src (data exfiltration)
```

---

## CSP Evaluation Tools

```
- Google CSP Evaluator: https://csp-evaluator.withgoogle.com/
- Mozilla Observatory: https://observatory.mozilla.org/
- Report URI: https://report-uri.com/
- CSP Analyzer browser extensions
- SecurityHeaders.com: https://securityheaders.com/
```

---

## References

- MDN CSP: https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
- OWASP CSP Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Content_Security_Policy_Cheat_Sheet.html
- Google CSP guide: https://csp.withgoogle.com/docs/index.html
- W3C CSP Level 3: https://www.w3.org/TR/CSP3/
