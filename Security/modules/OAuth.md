# OAuth 2.0 / OpenID Connect Security — Deep Module

## Threat Description

OAuth 2.0 is an authorization framework; OpenID Connect (OIDC) adds authentication. Misconfigured OAuth/OIDC implementations lead to account takeover, token theft, and unauthorized access.

---

## OAuth 2.0 Flows & Security

### Authorization Code Flow (Recommended for Web Apps)

```
RULE: Use Authorization Code flow with PKCE for ALL client types.

Flow:
1. Client generates code_verifier (random 43-128 chars) and code_challenge (SHA256 of verifier)
2. Client redirects user to authorization server:
   /authorize?response_type=code&client_id=X&redirect_uri=Y&code_challenge=Z&code_challenge_method=S256&state=RANDOM&scope=openid profile email
3. User authenticates and consents
4. Authorization server redirects to redirect_uri with ?code=AUTH_CODE&state=RANDOM
5. Client validates state parameter (CSRF protection)
6. Client exchanges code for tokens:
   POST /token { grant_type: authorization_code, code: AUTH_CODE, redirect_uri: Y, code_verifier: ORIGINAL_VERIFIER, client_id: X, client_secret: SECRET }
7. Authorization server validates code_verifier against stored code_challenge
8. Authorization server returns: access_token, refresh_token, id_token

Security requirements:
- ALWAYS use PKCE (even for confidential clients)
- ALWAYS validate state parameter
- ALWAYS use exact redirect_uri matching (no wildcards)
- Exchange code for tokens server-side (client_secret stays on server)
- Auth code is single-use and short-lived (10 minutes max)
```

### PKCE (Proof Key for Code Exchange)

```
RULE: PKCE is MANDATORY for all OAuth clients (public AND confidential).

code_verifier:
- Random string, 43-128 characters
- Characters: [A-Z] [a-z] [0-9] - . _ ~
- Generated fresh for each authorization request

code_challenge:
- SHA256(code_verifier) then base64url-encode
- Method: S256 (NEVER use "plain" method in production)

Purpose:
- Prevents authorization code interception attacks
- Even if attacker intercepts the code, they can't exchange it without code_verifier
- Essential for mobile/SPA apps where client_secret can't be kept secret
```

### Implicit Flow (DEPRECATED)

```
RULE: NEVER use Implicit flow. It is deprecated and insecure.

Problems:
- Access token exposed in URL fragment (browser history, logs, referrer)
- No refresh tokens
- No PKCE support
- Token exposed to JavaScript (XSS risk)

Migration: Use Authorization Code + PKCE instead.
```

### Client Credentials Flow

```
Use for: Machine-to-machine (M2M) communication, no user involved.

Security:
- Client secret is a credential — protect like a password
- Use short-lived access tokens (1 hour max)
- Restrict scopes to minimum required
- Use mTLS for additional security
- Rotate client secrets regularly
- Monitor for unusual token requests
```

---

## Security Checklist

### 1. Redirect URI Validation

```
RULE: Validate redirect_uri with EXACT matching. No wildcards. No partial matches.

SAFE:
  Registered: https://app.example.com/callback
  Requested:  https://app.example.com/callback  → ✓ Exact match

UNSAFE:
  Registered: https://app.example.com/
  Requested:  https://app.example.com/callback   → ✗ Prefix match is dangerous
  Requested:  https://app.example.com.evil.com   → ✗ Subdomain attack

  Registered: https://*.example.com/callback      → ✗ Wildcard is dangerous
  (Attacker creates subdomain: https://attacker.example.com/callback)

RULE: Register ALL redirect URIs explicitly. No dynamic registration.
RULE: Use HTTPS for all redirect URIs (except localhost for development).
RULE: Validate redirect_uri on both authorization AND token exchange.
```

### 2. State Parameter (CSRF Protection)

```
RULE: ALWAYS use the state parameter.

Generate:
  const state = crypto.randomBytes(32).toString('hex');
  // Store in session: req.session.oauth_state = state;

Validate on callback:
  if (req.query.state !== req.session.oauth_state) {
    throw new Error('CSRF detected — state mismatch');
  }
  delete req.session.oauth_state;

RULE: State must be:
- Cryptographically random
- Bound to user's session
- Single-use (delete after validation)
- Not predictable or reusable
```

### 3. Token Validation (OIDC ID Token)

```
RULE: Validate ALL claims in the ID token.

Required validations:
1. Verify signature (using provider's JWKS)
2. iss: Matches expected issuer URL
3. aud: Contains your client_id
4. exp: Not expired
5. iat: Not too far in the past
6. nonce: Matches the nonce you sent (replay protection)
7. at_hash: Matches hash of access_token (if present)

if (idToken.aud !== CLIENT_ID) throw new Error('Invalid audience');
if (idToken.iss !== EXPECTED_ISSUER) throw new Error('Invalid issuer');
if (idToken.nonce !== session.nonce) throw new Error('Nonce mismatch');
```

### 4. Scope Management

```
RULE: Request minimum required scopes.

- Request only scopes the application actually needs
- Don't request "admin" or broad scopes for regular user operations
- Display requested scopes in consent screen (transparency)
- Re-request scopes if needs change (incremental consent)
- Validate token scopes on resource server before granting access

Common OIDC scopes:
  openid    → required for OIDC (returns sub claim)
  profile   → name, picture, etc.
  email     → email, email_verified
  offline_access → refresh token
```

### 5. Token Storage & Handling

```
Web app (server-side):
- Store tokens in server-side session (never in browser)
- Exchange code on server side (client_secret stays secret)
- Proxy API calls through your server (token never reaches browser)

SPA (client-side):
- Use Authorization Code + PKCE
- Store access token in memory only (lost on refresh)
- Use refresh token in HttpOnly cookie or use silent refresh
- Use BFF (Backend for Frontend) pattern for better security

Mobile:
- Use Authorization Code + PKCE
- Use custom URL schemes or App Links for redirect
- Store tokens in platform secure storage (Keychain/Keystore)
- Use PKCE (no client_secret in mobile apps)
```

### 6. Social Login Security

```
IF implementing social login (Google, GitHub, Facebook, Apple):

RULE: Verify email ownership — don't trust email claims blindly.

Vulnerability:
  1. Attacker creates account on Provider A with victim's email (unverified)
  2. Attacker logs into your app via Provider A social login
  3. Victim later logs in via Provider B (same email, verified)
  4. App links accounts → attacker has access to victim's account

Prevention:
  - Only trust email from providers that verify it (check email_verified claim)
  - Don't auto-link accounts by email across providers
  - Require additional verification when linking accounts
  - Use provider's unique user ID (sub), not email, as primary identifier

Apple Sign In specific:
  - Email may be private relay (@privaterelay.appleid.com)
  - User data only provided on first authorization (store it)
  - Validate identity token server-side
```

### 7. Authorization Server Security (If Building Your Own)

```
IF building your own OAuth/OIDC provider:

RULE: Consider using a proven library/service instead (Keycloak, Auth0, Ory Hydra).

If you must build:
- Auth codes: single-use, 10-minute expiry, bound to client_id + redirect_uri + PKCE
- Store auth codes hashed (like passwords)
- Token endpoint: require client authentication
- CORS: restrict to registered origins
- Rate limit token endpoint
- Log all token issuance events
- Support token revocation endpoint (RFC 7009)
- Support token introspection endpoint (RFC 7662)
- Implement JWKS rotation
- Use signed and/or encrypted JWTs
```

---

## References

- OAuth 2.0 Security Best Current Practice: https://tools.ietf.org/html/draft-ietf-oauth-security-topics
- OWASP OAuth Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/OAuth_Cheat_Sheet.html
- RFC 6749 (OAuth 2.0): https://tools.ietf.org/html/rfc6749
- RFC 7636 (PKCE): https://tools.ietf.org/html/rfc7636
- OpenID Connect Core: https://openid.net/specs/openid-connect-core-1_0.html
