# Secret Management — Deep Module

## Threat Description

Hardcoded secrets, leaked API keys, and improperly stored credentials are among the most common security failures. A single exposed secret can compromise an entire system.

---

## Rules

### 1. Never Hardcode Secrets

```
ABSOLUTE RULE: No secrets in source code, ever.

✗ NEVER:
  const API_KEY = "sk_live_abc123def456";
  const DB_PASSWORD = "super_secret_password";
  DATABASE_URL = "postgres://admin:password@db:5432/prod"

✓ USE:
  const API_KEY = process.env.API_KEY;
  const DB_PASSWORD = vault.getSecret("db/password");

Scan for secrets:
  Tools: gitleaks, trufflehog, detect-secrets, git-secrets
  Run in CI/CD pipeline AND as pre-commit hook

  # Pre-commit hook
  npx gitleaks detect --source . --verbose
```

### 2. Secret Storage Solutions

```
Production (by preference):
1. Cloud KMS + Secrets Manager (AWS Secrets Manager, GCP Secret Manager, Azure Key Vault)
2. HashiCorp Vault (self-hosted, feature-rich)
3. Infisical (open source, developer-friendly)
4. Doppler (cloud-hosted, team-oriented)

Development:
- .env files (local only — NEVER commit)
- .env.example (committed — shows required variables WITHOUT values)
- Docker secrets (for containerized development)

RULE: .env MUST be in .gitignore
RULE: .env.example should document all required variables
```

### 3. Secret Rotation

```
RULE: All secrets must be rotatable. Plan for rotation before you need it.

Rotation schedule:
- API keys: every 90 days
- Database passwords: every 90 days
- Encryption keys: every 1-2 years (with key versioning)
- TLS certificates: every 90 days (Let's Encrypt) to 1 year
- JWT signing keys: every 6-12 months
- Service account credentials: every 90 days

Rotation process:
1. Generate new secret
2. Deploy new secret alongside old (dual-read period)
3. Update all consumers to use new secret
4. Verify new secret works
5. Revoke old secret
6. Log the rotation event

Auto-rotation:
- AWS Secrets Manager supports automatic rotation via Lambda
- Vault supports dynamic secrets (auto-generated, auto-expired)
- Use short-lived credentials where possible (STS tokens, IAM roles)
```

### 4. Emergency Procedures

```
IF a secret is leaked (committed to repo, exposed in logs, etc.):

Immediate actions (within minutes):
1. Revoke the compromised secret immediately
2. Generate new secret
3. Deploy new secret to all services
4. Check for unauthorized usage during exposure window
5. Rotate any secondary secrets that may be derived or related

Follow-up:
6. Investigate how the leak occurred
7. Implement prevention (pre-commit hooks, secret scanning)
8. Check git history (secret may be in old commits even if removed)
9. If committed to public repo: consider ALL versions of that secret compromised forever
   (git history is permanent, even after force-push)

Git history cleanup (if secret was committed):
  git filter-branch or BFG Repo-Cleaner
  BUT: if it was pushed to a public repo, assume it's compromised
```

### 5. Environment Separation

```
RULE: Use different secrets for each environment.

Environments:
- development: local/mock secrets
- staging: real but non-production secrets
- production: production secrets (most restricted)

NEVER:
- Use production secrets in development
- Use production database credentials in staging
- Share secrets between environments
- Copy production secrets to local machine

Access control:
- Developers: development + staging secrets
- CI/CD: staging + production secrets (minimal)
- Operations: production secrets (with audit trail)
- Nobody should know production secrets by heart
```

### 6. Application Configuration

```
// Config hierarchy (later overrides earlier):
1. Default values in code (non-sensitive only)
2. Config files (non-sensitive only)
3. Environment variables (secrets)
4. Secret manager (most sensitive secrets)

// Example (Node.js)
const config = {
  port: parseInt(process.env.PORT) || 3000,           // Default in code
  logLevel: process.env.LOG_LEVEL || 'info',           // Env var
  dbUrl: process.env.DATABASE_URL,                     // Required env var
  apiKey: await vault.getSecret('api/stripe/key'),     // From secret manager
};

// Validate all required config on startup
const required = ['DATABASE_URL', 'JWT_SECRET', 'API_KEY'];
for (const key of required) {
  if (!process.env[key]) {
    console.error(`Missing required environment variable: ${key}`);
    process.exit(1);
  }
}
```

---

## References

- OWASP Secrets Management Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
- 12-Factor App Config: https://12factor.net/config
