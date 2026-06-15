# Security — Authentication & Authorization

## Scope

This module covers identity verification (authentication) and access control (authorization): login, registration, password management, multi-factor authentication, role-based access, and federated identity.

## Sub-Router

```
IF task contains [JWT, JSON Web Token, Access Token, Refresh Token, Bearer Token, Token Validation, Token Expiry]
    LOAD modules/JWT.md

IF task contains [OAuth, OAuth2, OpenID Connect, OIDC, SSO, Single Sign-On, Social Login, Google Login, GitHub Login, SAML, LDAP, Active Directory]
    LOAD modules/OAuth.md

IF task contains [Password, Passphrase, Credential, Hashing, bcrypt, argon2, scrypt, PBKDF2, Password Policy, Password Reset, Forgot Password]
    LOAD modules/Password.md

IF task contains [MFA, 2FA, Two-Factor, Multi-Factor, TOTP, Authenticator, OTP, SMS Code, WebAuthn, FIDO, Passkey, Biometric, Backup Code]
    LOAD modules/MFA.md

IF task contains [Role, Permission, RBAC, ABAC, ACL, Admin, Moderator, Policy, Guard, Gate, Authorize, Can, Cannot, Ability, Claim]
    LOAD modules/RBAC.md
```

## Universal Auth Security Rules

### 1. Authentication Fundamentals

```
RULE: Authentication is identity verification. Authorization is access control.
      They are separate concerns — implement them separately.

Authentication flow:
1. User provides credentials (password, token, biometric)
2. Server verifies credentials
3. Server issues session/token
4. Client presents session/token on subsequent requests
5. Server validates session/token on every request

NEVER:
- Trust client-side authentication state
- Store authentication state only in client
- Skip re-authentication for sensitive operations
```

### 2. Login Security

```
RULE: Login endpoints are the #1 target. Protect aggressively.

Checklist:
- Rate limit login attempts (5-10 per minute per IP+username combo)
- Account lockout after N failures (10-15 attempts, time-based unlock)
- Use constant-time comparison for credentials
- Generic error messages ("Invalid email or password" — never reveal which)
- Log all login attempts (success and failure) with IP, timestamp, user agent
- Re-validate session after login (prevent session fixation)
- Require CAPTCHA after N failed attempts

Brute force protection layers:
1. Rate limit per IP
2. Rate limit per username
3. Progressive delay (exponential backoff)
4. CAPTCHA trigger
5. Account lockout (temporary, never permanent)
6. Alert on distributed brute force (many IPs, same username)
```

### 3. Registration Security

```
RULE: Registration is a data creation endpoint. Validate thoroughly.

Checklist:
- Validate email format AND verify via confirmation link
- Enforce password policy (see modules/Password.md)
- Rate limit registration (3-5 per hour per IP)
- CAPTCHA on registration form
- Prevent username enumeration (don't reveal if email exists)
  Response: "If this email is registered, you'll receive a confirmation"
- Normalize email (lowercase, trim)
- Check for disposable email domains (optional but recommended)
- Sanitize display name / username
- Set default role to lowest privilege
```

### 4. Session Post-Login

```
RULE: Regenerate session ID immediately after successful login.
RULE: Invalidate all previous sessions on password change.
RULE: Provide "logout everywhere" functionality.

Session checks on every request:
1. Is session valid (not expired)?
2. Is user account still active?
3. Has user's role/permission changed? (reload if needed)
4. Is the session bound to the same IP/User-Agent? (optional, strict mode)
```

### 5. Password Reset

```
RULE: Password reset is a critical flow. Secure it properly.

Flow:
1. User requests reset → generic response ("if email exists, we sent a link")
2. Generate cryptographically random token (min 32 bytes, URL-safe base64)
3. Hash token before storing in database (SHA-256)
4. Set token expiry (15-30 minutes)
5. Send reset link via email (HTTPS only)
6. On reset page: validate token, enforce password policy
7. After reset: invalidate token, invalidate all sessions, log event
8. Rate limit: 3 requests per hour per email

NEVER:
- Send password in email
- Use sequential or predictable tokens
- Use user ID or timestamp as token
- Allow token reuse
- Keep token valid after password is changed
```

### 6. Account Recovery

```
RULE: Account recovery must be as secure as login.

- Security questions: AVOID (easily researched/guessed)
- Email-based recovery: Primary method, secure the email link
- SMS-based recovery: Acceptable but vulnerable to SIM swap
- Admin-assisted recovery: Require identity verification
- Recovery codes: Pre-generated, one-time use, stored hashed
```

### 7. Privilege Escalation Prevention

```
RULE: Users must not be able to elevate their own privileges.

Checklist:
- Never trust client-provided role/permission data
- Validate role changes through separate admin authorization
- Log all privilege changes
- Require re-authentication for privilege-changing operations
- Separate admin endpoints with additional authentication
- Use different session/token for admin operations (step-up auth)
```

### 8. Account Enumeration Prevention

```
RULE: Never reveal whether an account exists.

Affected endpoints:
- Login: "Invalid email or password" (not "user not found")
- Registration: "If not already registered, check your email"
- Password reset: "If this email exists, we sent a reset link"
- Username check: Avoid real-time availability check (or rate limit heavily)

Timing attack prevention:
- Use constant-time comparison
- Add artificial delay to make response times consistent
- Hash a dummy value when user doesn't exist (same computation time)
```

### 9. Sensitive Operation Re-authentication

```
RULE: Require fresh authentication for high-risk actions.

Actions requiring re-auth:
- Change password
- Change email
- Enable/disable MFA
- Delete account
- Change payment method
- Access security settings
- Export personal data
- Generate API keys
- Modify admin settings

Implementation:
- Prompt for current password
- Or require fresh MFA verification
- Set a "re-auth window" (5-15 minutes)
- Log the re-authentication event
```

### 10. Impersonation & Delegation

```
IF the system supports admin impersonation or delegated access:

RULE: Impersonation must be logged separately from normal access.
RULE: Impersonating user should have a clear visual indicator.
RULE: Certain actions should be blocked during impersonation (password change, MFA change).
RULE: Impersonation sessions should have shorter timeout.
RULE: Log both the admin and the impersonated user in audit trail.
```
