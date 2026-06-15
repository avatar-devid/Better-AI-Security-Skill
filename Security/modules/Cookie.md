# Cookie Security — Deep Module

## Threat Description

Cookies are the primary mechanism for maintaining session state. Insecure cookie configuration leads to session hijacking, CSRF, and data exposure.

**CWE**: CWE-614 (Sensitive Cookie in HTTPS Session Without 'Secure' Attribute), CWE-1004 (Sensitive Cookie Without 'HttpOnly' Flag)

---

## Cookie Security Attributes

### Secure Flag

```
RULE: ALL cookies containing sensitive data MUST have the Secure flag.

Set-Cookie: session=abc123; Secure

Effect: Cookie is only sent over HTTPS connections.
Without it: Cookie can be intercepted via HTTP (MITM attack, network sniffing).

MANDATORY for:
- Session cookies
- Authentication tokens
- CSRF tokens
- Any cookie with sensitive data
```

### HttpOnly Flag

```
RULE: Session cookies MUST have the HttpOnly flag.

Set-Cookie: session=abc123; HttpOnly

Effect: Cookie cannot be accessed via JavaScript (document.cookie).
Without it: XSS can steal session cookies.

MANDATORY for:
- Session ID cookies
- Authentication cookies
- Remember-me tokens

NOT for:
- CSRF tokens using double-submit pattern (JS needs to read them)
- Preferences cookies that JavaScript needs to access
```

### SameSite Attribute

```
RULE: Set SameSite on ALL cookies.

Set-Cookie: session=abc123; SameSite=Lax

SameSite=Strict:
- Never sent on cross-site requests
- Best security but breaks some UX (external links don't maintain session)

SameSite=Lax (Recommended):
- Sent on top-level GET navigations (links work)
- NOT sent on cross-site POST, iframes, AJAX, images
- Good default for session cookies

SameSite=None:
- Sent on all cross-site requests
- REQUIRES Secure flag
- Only use for legitimate cross-site scenarios (SSO, embedded widgets)

Default behavior (if not set):
- Modern browsers default to Lax
- Old browsers default to None (insecure)
- ALWAYS set explicitly
```

### Domain Attribute

```
RULE: Set Domain as restrictively as possible.

Set-Cookie: session=abc123; Domain=example.com
→ Cookie sent to example.com AND all subdomains (*.example.com)

Set-Cookie: session=abc123
→ Cookie sent ONLY to the exact domain that set it (no subdomains)

RULE: Omit Domain attribute unless subdomains genuinely need the cookie.
      This prevents subdomain takeover from accessing parent domain cookies.
```

### Path Attribute

```
Set-Cookie: session=abc123; Path=/app

Effect: Cookie sent only for requests to /app and subpaths.

Use case: Restrict cookie to specific application path.
Default: Path of the URL that set the cookie.
Recommendation: Use Path=/ for session cookies (consistent behavior).
```

### Max-Age / Expires

```
RULE: Set appropriate expiry for all cookies.

Session cookies (no Max-Age/Expires):
- Deleted when browser closes
- Use for session tokens (combined with server-side timeout)

Persistent cookies (Max-Age or Expires set):
- Remember-me: Max-Age=2592000 (30 days)
- Preferences: Max-Age=31536000 (1 year)
- NEVER set very long expiry for session cookies

Delete a cookie:
Set-Cookie: session=; Max-Age=0; Path=/; Secure; HttpOnly
```

---

## Cookie Prefixes

```
Modern browsers support cookie prefixes for additional security:

__Secure- prefix:
- Cookie MUST have Secure flag
- Cookie MUST be set over HTTPS
Set-Cookie: __Secure-session=abc123; Secure; Path=/

__Host- prefix (most restrictive):
- Cookie MUST have Secure flag
- Cookie MUST be set over HTTPS
- Cookie MUST NOT have Domain attribute (exact host only)
- Cookie Path MUST be /
Set-Cookie: __Host-session=abc123; Secure; Path=/

RULE: Use __Host- prefix for session cookies when possible.
      This prevents subdomain attacks and domain scope manipulation.
```

---

## Recommended Cookie Configuration

```
Session cookie (most secure):
Set-Cookie: __Host-session=RANDOM_ID; Secure; HttpOnly; SameSite=Lax; Path=/; Max-Age=3600

Remember-me cookie:
Set-Cookie: __Secure-remember=HASHED_TOKEN; Secure; HttpOnly; SameSite=Lax; Path=/; Max-Age=2592000

CSRF cookie (double-submit pattern):
Set-Cookie: __Host-csrf=RANDOM_TOKEN; Secure; SameSite=Lax; Path=/
(Note: no HttpOnly — JavaScript needs to read it)

Preference cookie:
Set-Cookie: theme=dark; Secure; SameSite=Lax; Path=/; Max-Age=31536000
(No HttpOnly needed — not sensitive; no __Host prefix — may need subdomain access)
```

---

## Cookie Limits and Constraints

```
Browser limits:
- Maximum cookie size: ~4096 bytes per cookie
- Maximum cookies per domain: ~50 (varies by browser)
- Maximum total cookies: ~3000

If you need more data:
- Store data server-side (session store)
- Use a single session ID cookie → lookup server-side data
- Do NOT split data across many cookies (fragile, hits limits)
```

---

## Third-Party Cookie Deprecation

```
IMPORTANT: Third-party cookies are being phased out.

Impact:
- Chrome: Blocking third-party cookies (Privacy Sandbox)
- Safari: Already blocks third-party cookies (ITP)
- Firefox: Already blocks third-party cookies (ETP)

If your application relies on third-party cookies:
- SSO: Migrate to token-based auth or use Storage Access API
- Analytics: Use first-party cookies or server-side tracking
- Embedded widgets: Use Storage Access API or postMessage
- Advertising: Use Privacy Sandbox APIs (Topics, Attribution Reporting)

RULE: Design new applications without relying on third-party cookies.
```

---

## Common Cookie Security Mistakes

```
1. Missing Secure flag (cookie sent over HTTP)
2. Missing HttpOnly on session cookies (XSS can steal them)
3. Missing SameSite attribute (CSRF vulnerability)
4. Overly broad Domain (*.example.com when only www needed)
5. Storing sensitive data directly in cookie value (instead of session ID → server lookup)
6. Not encrypting cookie values that contain data
7. Using predictable cookie values (sequential IDs, timestamps)
8. Not clearing cookies on logout
9. Setting very long expiry on session cookies
10. Storing JWT in cookies without proper flags
11. Cookie bombing (attacker sets cookies for parent domain → DoS)
12. Not using __Host- prefix when possible
```

---

## References

- OWASP Session Management Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html
- MDN Set-Cookie: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie
- RFC 6265bis: https://httpwg.org/http-extensions/draft-ietf-httpbis-rfc6265bis.html
