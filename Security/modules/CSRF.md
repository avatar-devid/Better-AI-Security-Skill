# CSRF (Cross-Site Request Forgery) — Deep Module

## Threat Description

CSRF tricks an authenticated user's browser into sending an unwanted request to a web application where the user is logged in. The attacker forges a request using the victim's session.

**Impact**: Unauthorized state changes — password changes, email changes, fund transfers, data deletion, privilege escalation.

**CWE**: CWE-352 (Cross-Site Request Forgery)

---

## How CSRF Works

```
1. User logs into example.com (session cookie set)
2. User visits evil.com (attacker-controlled)
3. evil.com contains: <img src="https://example.com/transfer?to=attacker&amount=1000">
   OR: <form action="https://example.com/transfer" method="POST">...</form> with auto-submit
4. Browser automatically sends example.com cookies with the request
5. example.com processes the request as if the user intended it
```

---

## Prevention Methods

### 1. SameSite Cookies (Primary Defense)

```
RULE: Set SameSite attribute on all session cookies.

SameSite=Strict:
- Cookie NOT sent on any cross-site request
- Strongest protection but may break legitimate flows
- Links from external sites won't carry the cookie (user appears logged out)

SameSite=Lax (Recommended default):
- Cookie sent on top-level navigation GET requests (links from external sites work)
- Cookie NOT sent on cross-site POST, iframe, AJAX, image requests
- Good balance of security and usability

SameSite=None; Secure:
- Cookie sent on all requests (cross-site included)
- Only use if cross-site cookies are genuinely needed (SSO, embedded widgets)
- MUST be combined with Secure flag

Set-Cookie: session=abc123; SameSite=Lax; Secure; HttpOnly; Path=/
```

### 2. CSRF Tokens (Synchronizer Token Pattern)

```
RULE: Include a unique, unpredictable token in every state-changing request.

Server-side flow:
1. Generate cryptographically random token (32+ bytes)
2. Store token in session (server-side)
3. Include token in every form and AJAX request
4. Validate token on every state-changing request (POST, PUT, DELETE, PATCH)
5. Reject request if token missing or invalid

Token delivery methods:

A. Hidden form field:
<form method="POST" action="/transfer">
  <input type="hidden" name="_csrf" value="RANDOM_TOKEN_HERE">
  ...
</form>

B. Custom HTTP header (for AJAX):
fetch('/api/transfer', {
  method: 'POST',
  headers: {
    'X-CSRF-Token': csrfToken,  // from meta tag or cookie
    'Content-Type': 'application/json'
  },
  body: JSON.stringify(data)
});

C. Meta tag (for SPA):
<meta name="csrf-token" content="RANDOM_TOKEN_HERE">
const token = document.querySelector('meta[name="csrf-token"]').content;

Token validation rules:
- Token MUST be unique per session (not per request — that breaks back button)
- Token MUST be cryptographically random (not derived from session ID)
- Token MUST be validated server-side (never client-side only)
- Reject if token missing, empty, or mismatched
- Do NOT put token in URL (leaked via Referer header)
```

### 3. Double Submit Cookie Pattern

```
Use when server-side session storage is not available (stateless APIs):

Flow:
1. Server sets a random token in a cookie: csrf_token=RANDOM
2. Client reads the cookie (JavaScript) and sends it as a header or form field
3. Server compares cookie value with header/form value
4. Attacker cannot read the cookie from another domain (Same-Origin Policy)

Signed variant (recommended):
1. Server generates: token = HMAC-SHA256(session_id + timestamp, secret_key)
2. Server sets cookie: csrf_token=token
3. Client sends token as header
4. Server recomputes HMAC and compares

Advantages:
- Stateless (no server-side token storage)
- Works with load balancers and distributed systems

Requirements:
- Cookie MUST NOT be HttpOnly (JavaScript needs to read it)
- Cookie MUST have SameSite=Lax or Strict
- Use HMAC-signed variant for stronger security
```

### 4. Origin / Referer Validation

```
Additional defense layer (not primary):

Check Origin header:
- Verify Origin header matches expected domain
- If Origin is missing, check Referer header
- If both missing, block the request (or allow with extra caution)

Implementation:
const allowedOrigins = ['https://example.com', 'https://www.example.com'];
const origin = req.headers.origin || req.headers.referer;
if (!origin || !allowedOrigins.some(allowed => origin.startsWith(allowed))) {
  return res.status(403).json({ error: 'CSRF validation failed' });
}

Limitations:
- Origin header may be absent in some browsers/privacy modes
- Referer can be stripped by Referrer-Policy
- Use as supplementary check, not sole defense
```

### 5. Custom Request Headers

```
For API-only applications (no form submissions):

RULE: Require a custom header that cannot be set by simple requests.

Example: Require X-Requested-With: XMLHttpRequest
- Simple requests (forms, images) cannot set custom headers
- CORS preflight required for custom headers from other origins
- If CORS is not misconfigured, cross-origin requests with custom headers are blocked

This works ONLY if:
- CORS is properly configured (no wildcard with credentials)
- The API does not accept simple content types (form-urlencoded, multipart)
- All clients can send custom headers (no browser form submissions)
```

---

## Framework CSRF Support

```
Express.js:    csurf middleware (deprecated) → use csrf-csrf or lusca
               Alternative: SameSite cookies + custom header check

Django:        {% csrf_token %} in templates (built-in middleware)
               CsrfViewMiddleware enabled by default
               CSRF_COOKIE_SAMESITE = 'Lax'

Rails:         protect_from_forgery with: :exception (built-in)
               csrf_meta_tags in layout
               Automatic token validation

Laravel:       @csrf in Blade templates (built-in middleware)
               VerifyCsrfToken middleware
               X-CSRF-TOKEN header support

Spring:        CsrfFilter enabled by default (Spring Security)
               _csrf.token in forms
               CookieCsrfTokenRepository for SPA

ASP.NET:       @Html.AntiForgeryToken() in views
               [ValidateAntiForgeryToken] attribute on actions
               Built-in middleware in ASP.NET Core

Next.js:       No built-in CSRF — use csrf-csrf or iron-session
               API routes need manual protection
               SameSite cookies recommended

NestJS:        csurf middleware or custom guard
               @nestjs/csrf
```

---

## Endpoints That Need CSRF Protection

```
MUST protect (state-changing):
- POST, PUT, PATCH, DELETE requests
- Login / Logout
- Password change
- Email change
- Profile update
- Payment / Transfer
- Settings changes
- Account deletion
- Admin actions
- File upload
- Form submissions

Safe to skip (read-only):
- GET requests (if they don't change state)
- HEAD, OPTIONS requests
- Public API endpoints with no session auth
- Webhook endpoints (authenticated via signature, not cookie)
```

---

## Common CSRF Mistakes

```
1. Protecting only POST, forgetting PUT/DELETE/PATCH
2. Not validating CSRF token on AJAX requests
3. Using predictable tokens (timestamp, sequential)
4. Token not bound to session (reusable across sessions)
5. Token in URL (leaked via Referer header, browser history, logs)
6. CORS misconfiguration allowing credentialed cross-origin requests
7. SameSite=None without Secure flag
8. Excluding specific routes from CSRF without good reason
9. Accepting application/x-www-form-urlencoded without CSRF token on API
10. Not regenerating CSRF token on login (session fixation + CSRF combo)
```

---

## Testing for CSRF

```
Manual testing:
1. Capture a state-changing request (Burp Suite / DevTools)
2. Remove CSRF token → Does the request succeed? (vulnerability)
3. Modify CSRF token → Does the request succeed? (vulnerability)
4. Use token from different session → Does it work? (vulnerability)
5. Replay old token → Does it work? (may be acceptable if session-bound)

Automated tools:
- Burp Suite CSRF PoC Generator
- OWASP ZAP
- CSRFTester
```

---

## References

- OWASP CSRF Prevention Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html
- CWE-352: https://cwe.mitre.org/data/definitions/352.html
- SameSite Cookies Explained: https://web.dev/samesite-cookies-explained/
