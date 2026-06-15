# MFA (Multi-Factor Authentication) — Deep Module

## Threat Description

Single-factor authentication (password only) is insufficient. MFA adds additional verification layers, dramatically reducing account takeover even when passwords are compromised.

---

## MFA Methods (Strongest to Weakest)

### 1. WebAuthn / FIDO2 / Passkeys (Strongest)

```
RECOMMENDED: Hardware security keys and platform authenticators.

How it works:
- Uses public key cryptography
- Private key never leaves the device
- Resistant to phishing (origin-bound)
- Resistant to replay attacks
- No shared secrets

Implementation:
- Server: Generate challenge → send to client
- Client: navigator.credentials.create() (registration) or .get() (authentication)
- Server: Verify assertion signature with stored public key

Libraries:
- Node.js: @simplewebauthn/server
- Python: py_webauthn
- Java: webauthn4j
- .NET: Fido2NetLib
- Go: github.com/go-webauthn/webauthn

Passkeys:
- Cross-device passkeys (synced via iCloud Keychain, Google Password Manager)
- Device-bound passkeys (hardware security keys like YubiKey)
- Both are phishing-resistant

RULE: Offer WebAuthn/Passkeys as the primary MFA option.
```

### 2. TOTP (Time-Based One-Time Password)

```
Standard authenticator app codes (Google Authenticator, Authy, 1Password).

How it works:
- Server and client share a secret key
- Both compute HMAC-SHA1(secret, floor(time / 30)) → 6-digit code
- Codes change every 30 seconds
- Allow 1-step time window tolerance (previous + current + next code)

Implementation:
- Generate secret: random 20 bytes, encode as base32
- Create otpauth:// URI for QR code
- Verify: compare submitted code with computed code (±1 step)

URI format:
  otpauth://totp/AppName:user@email.com?secret=BASE32SECRET&issuer=AppName&algorithm=SHA1&digits=6&period=30

Security rules:
- Store secret encrypted (not plain text)
- Rate limit TOTP verification (5 attempts per minute)
- Lock account after 10 consecutive TOTP failures
- Allow clock skew of ±1 step (±30 seconds)
- Mark TOTP as used (prevent replay within time window)
- Show secret only once during setup (never display again)

Libraries:
- Node.js: otplib, speakeasy
- Python: pyotp
- Java: GoogleAuth
- C#: Otp.NET
- Go: pquerna/otp
```

### 3. SMS OTP (Weakest — Use as Fallback Only)

```
WARNING: SMS is vulnerable to SIM swapping, SS7 attacks, and interception.

If SMS must be used:
- Use as fallback only (not primary MFA)
- Limit SMS code validity to 5 minutes
- Single-use codes only
- Rate limit: 3 SMS per hour per phone number
- 6-digit codes minimum
- Don't include the code in the SMS preview (use format: "Your code is at the end of this message. Do not share it. Code: 123456")
- Monitor for SIM swap patterns (sudden carrier change)
- Log all SMS OTP events

RULE: Prefer TOTP or WebAuthn over SMS.
RULE: If offering SMS, also offer TOTP/WebAuthn and encourage upgrade.
```

---

## Implementation Security

### Backup / Recovery Codes

```
RULE: Generate recovery codes during MFA setup.

- Generate 8-10 recovery codes
- Each code: 8-12 alphanumeric characters (e.g., ABCD-1234-EFGH)
- Hash codes before storing (like passwords)
- Single-use (each code works once)
- Show codes only once during setup
- Encourage user to save them securely (print or password manager)
- Log recovery code usage (security event)
- Allow regeneration (invalidates all previous codes)

Display format:
  Your recovery codes (save these securely):
  1. ABCD-1234-EFGH
  2. IJKL-5678-MNOP
  3. QRST-9012-UVWX
  ... (8-10 codes)
  
  Each code can only be used once.
  If you lose these codes, you may lose access to your account.
```

### MFA Enrollment Flow

```
Secure enrollment:
1. Require current password before enabling MFA
2. Generate secret / register authenticator
3. Verify that the user can produce a valid code (test before activating)
4. Generate and display backup codes
5. Require user to confirm they saved backup codes
6. Activate MFA
7. Log the enrollment event

RULE: User must successfully verify a code during setup (prove they have the authenticator).
RULE: Show backup codes AFTER successful verification.
```

### MFA Verification Flow

```
On login with MFA:
1. User provides username + password → validated
2. If MFA enabled → prompt for MFA code (separate step)
3. User submits TOTP / WebAuthn / recovery code
4. Server validates code
5. If valid → create authenticated session
6. If invalid → increment failure counter → rate limit

Security:
- MFA prompt is a SEPARATE step (don't combine with password)
- Rate limit MFA attempts (5 per minute, lockout after 10)
- Don't reveal which MFA method is configured (prevents targeted attacks)
- Log all MFA verification attempts (success and failure)
- Lockout: temporary (15-30 minutes), not permanent
```

### MFA Bypass Prevention

```
RULE: MFA must not be bypassable.

Common bypass vulnerabilities:
1. MFA not checked on alternative login paths (API, mobile, SSO)
   → Check MFA on ALL authentication paths
2. MFA check skipped for "remembered" devices without proper token
   → Use secure device token (cryptographic, time-limited)
3. MFA removed without re-authentication
   → Require password + existing MFA to disable MFA
4. Session created before MFA verification
   → Create unauthenticated session → upgrade after MFA
5. Direct API access without MFA
   → Enforce MFA state on all authenticated endpoints
6. Password reset bypasses MFA
   → Require MFA verification during password reset (if user has MFA)
7. Account recovery bypasses MFA
   → Recovery codes ARE MFA (they count as the second factor)
```

### Device Trust / "Remember This Device"

```
IF offering "remember this device" (skip MFA on trusted devices):

Implementation:
1. After successful MFA → generate device token
2. Device token: cryptographically random, 32+ bytes
3. Hash token before storing (associate with user + device fingerprint)
4. Set cookie: Secure, HttpOnly, SameSite=Strict, Max-Age=30 days
5. On next login: if valid device token → skip MFA
6. Limit trusted devices (max 5-10)
7. Show list of trusted devices in settings
8. Allow revoking individual devices
9. Revoke ALL trusted devices on password change or security event

RULE: "Remember this device" reduces security. Make it opt-in.
RULE: Still require MFA for sensitive operations (even on trusted devices).
```

---

## References

- OWASP MFA Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Multifactor_Authentication_Cheat_Sheet.html
- NIST SP 800-63B (Authenticator Requirements): https://pages.nist.gov/800-63-3/sp800-63b.html
- WebAuthn Guide: https://webauthn.guide/
- RFC 6238 (TOTP): https://tools.ietf.org/html/rfc6238
