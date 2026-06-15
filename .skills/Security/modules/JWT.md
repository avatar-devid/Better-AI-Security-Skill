# JWT (JSON Web Token) Security — Deep Module

## Threat Description

JWTs are widely used for stateless authentication but are frequently misconfigured, leading to authentication bypass, privilege escalation, and token forgery.

**CWE**: CWE-347 (Improper Verification of Cryptographic Signature)

---

## JWT Structure

```
header.payload.signature

Header:  { "alg": "HS256", "typ": "JWT" }
Payload: { "sub": "user123", "role": "user", "iat": 1700000000, "exp": 1700003600 }
Signature: HMAC-SHA256(base64url(header) + "." + base64url(payload), secret)

Each part is base64url-encoded. The signature ensures integrity.
```

---

## JWT Vulnerabilities & Prevention

### 1. Algorithm Confusion Attack

```
THREAT: Attacker changes "alg" header to bypass signature verification.

Attack "none" algorithm:
  Header: { "alg": "none" }
  → Some libraries accept unsigned tokens if "none" algorithm is allowed

Attack HS256/RS256 confusion:
  Server uses RS256 (asymmetric — signs with private key, verifies with public key)
  Attacker changes to HS256 (symmetric) and signs with the PUBLIC key
  Server verifies using public key as HMAC secret → signature valid!

Prevention:
  RULE: ALWAYS specify the expected algorithm when verifying. Never trust the token's "alg" header.

  // Node.js (jsonwebtoken)
  jwt.verify(token, secret, { algorithms: ['HS256'] })  // ✓ Explicit algorithm

  // NEVER
  jwt.verify(token, secret)  // ✗ Trusts token's alg header

  // Python (PyJWT)
  jwt.decode(token, key, algorithms=["RS256"])  // ✓ Explicit

  // Java (jjwt)
  Jwts.parserBuilder().setSigningKey(key).build().parseClaimsJws(token)  // ✓ Key implies algorithm

  // C# (Microsoft.IdentityModel)
  new TokenValidationParameters { ValidAlgorithms = new[] { "RS256" } }  // ✓ Explicit

RULE: Disable "none" algorithm entirely.
RULE: Use asymmetric algorithms (RS256, ES256, EdDSA) for distributed systems.
RULE: Use symmetric algorithms (HS256, HS384, HS512) only for single-server scenarios.
```

### 2. Weak Signing Secret

```
THREAT: Weak HMAC secrets can be brute-forced offline.

Attack: Extract JWT → brute-force the HMAC secret offline → forge tokens.
Tools: hashcat, jwt-cracker, jwt_tool

Prevention:
- Use minimum 256-bit random secret for HMAC (32+ random bytes)
- Generate with CSPRNG: crypto.randomBytes(64).toString('hex')
- NEVER use human-readable passwords as JWT secrets
- NEVER use short strings ("secret", "password", "jwt-key")
- Prefer asymmetric algorithms (RS256, ES256) — no shared secret needed
- Rotate secrets periodically (support multiple active keys via "kid" header)
```

### 3. Missing Expiration

```
RULE: ALL JWTs MUST have an expiration claim (exp).

Access token: 5-15 minutes (short-lived)
Refresh token: 7-30 days (long-lived, stored securely)
ID token: 5-60 minutes

ALWAYS validate expiration:
  jwt.verify(token, secret, { algorithms: ['HS256'], clockTolerance: 30 })
  // 30 seconds tolerance for clock skew

Also validate:
- iat (issued at): Reject tokens issued in the future
- nbf (not before): Token not valid before this time
```

### 4. Token Storage

```
RULE: Store tokens securely based on the client type.

Web applications:
  ✓ HttpOnly Secure SameSite cookie (best — immune to XSS)
  ✗ localStorage (accessible to XSS — full token theft)
  ✗ sessionStorage (accessible to XSS, cleared on tab close)
  △ In-memory variable (safe from XSS, lost on refresh — use with refresh token in cookie)

Mobile applications:
  ✓ iOS Keychain / Android Keystore (encrypted, hardware-backed)
  ✗ AsyncStorage / SharedPreferences (not encrypted by default)
  ✗ In files on disk (accessible on rooted/jailbroken devices)

Desktop applications:
  ✓ OS credential store (Windows Credential Manager, macOS Keychain)
  ✗ Config files (even in user directory)
  ✗ Registry without DPAPI (Windows)
```

### 5. Refresh Token Security

```
RULE: Use the access token + refresh token pattern.

Flow:
1. Login → receive access_token (5-15 min) + refresh_token (7-30 days)
2. Use access_token for API requests
3. When access_token expires → use refresh_token to get new access_token
4. Server validates refresh_token → issues new access_token + new refresh_token
5. Old refresh_token is invalidated (rotation)

Refresh token rules:
- Store refresh tokens in database (for revocation)
- Hash refresh tokens before storing (like passwords)
- Rotate on every use (one-time use)
- Detect reuse of old refresh tokens → revoke ALL tokens for the user (compromise detected)
- Bind to device/IP (optional, strict mode)
- Absolute expiry (30 days max, even if continuously refreshed)
- Revoke on password change
- Revoke on explicit logout
```

### 6. Claim Validation

```
RULE: Validate ALL relevant claims, not just the signature.

Required validations:
- exp (expiration): Token not expired
- iss (issuer): Token from expected issuer
- aud (audience): Token intended for this service
- sub (subject): Valid user ID
- iat (issued at): Not issued in the future
- nbf (not before): Currently valid

jwt.verify(token, secret, {
  algorithms: ['RS256'],
  issuer: 'https://auth.example.com',
  audience: 'https://api.example.com',
  clockTolerance: 30
});

NEVER trust claims without verification:
- Don't use "role" claim without server-side verification for sensitive operations
- Don't use "email" claim as verified without checking "email_verified" claim
- Don't use "sub" claim to authorize access without checking against resource ownership
```

### 7. Token Revocation

```
CHALLENGE: JWTs are stateless — you can't "invalidate" them before expiry.

Revocation strategies:

A. Short expiry + refresh token (recommended):
   - Access tokens: 5-15 minutes, not revocable (acceptable risk)
   - Refresh tokens: stored in DB, revocable immediately
   - On security event → revoke refresh tokens → user locked out within 15 min

B. Token blacklist:
   - Store revoked token JTI (JWT ID) in Redis/cache
   - Check blacklist on every request
   - Blacklist entries expire when token would naturally expire
   - Fast but adds statefulness

C. Token versioning:
   - Store "token version" per user in database
   - Include version in JWT claims
   - On revocation: increment user's token version
   - Reject tokens with old version

D. Key rotation:
   - Rotate signing key → all old tokens invalid
   - Nuclear option — affects all users
   - Use only for emergency (key compromise)
```

### 8. JWK / JWKS Security

```
IF using asymmetric algorithms with JWKS (JSON Web Key Set):

- Serve JWKS over HTTPS only
- Cache JWKS with appropriate TTL (5-15 minutes)
- Validate "kid" (key ID) header against known keys
- Never accept keys from untrusted JWKS endpoints
- Limit key types and algorithms accepted
- Rotate keys periodically (include old key in JWKS during transition)
- Monitor JWKS endpoint for unauthorized changes
```

---

## JWT Security Checklist

```
1. ✓ Specify algorithm explicitly when verifying (never trust token's alg)
2. ✓ Disable "none" algorithm
3. ✓ Use strong secret (256+ bits random) for HMAC, or asymmetric keys
4. ✓ Set short expiration (5-15 min for access tokens)
5. ✓ Validate exp, iss, aud, sub claims
6. ✓ Store tokens securely (HttpOnly cookies for web, keychain for mobile)
7. ✓ Implement refresh token rotation
8. ✓ Detect refresh token reuse (compromise indicator)
9. ✓ Revoke tokens on password change and logout
10. ✓ Don't store sensitive data in JWT payload (it's only base64, not encrypted)
11. ✓ Use JWE (encrypted JWT) if payload must be confidential
12. ✓ Include jti (JWT ID) for revocation tracking
13. ✓ Log token issuance and refresh events
14. ✓ Implement key rotation strategy
```

---

## References

- OWASP JWT Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html
- RFC 7519 (JWT): https://tools.ietf.org/html/rfc7519
- JWT Best Practices (RFC 8725): https://tools.ietf.org/html/rfc8725
- Auth0 JWT Handbook: https://auth0.com/resources/ebooks/jwt-handbook
