# Security — Infrastructure & DevOps

## Scope

This module covers infrastructure-level security: server configuration, deployment, container security, CI/CD pipelines, cloud services, TLS, DNS, and monitoring.

## Self-Contained Module

This module does not have sub-routers. It covers all infrastructure security topics.

## Infrastructure Security Rules

### 1. HTTPS / TLS Configuration

```
RULE: ALL traffic MUST use HTTPS. No exceptions.

TLS configuration:
- TLS 1.2 minimum, prefer TLS 1.3
- Disable TLS 1.0, TLS 1.1, SSLv3 (all deprecated)
- Use strong cipher suites (AEAD ciphers: AES-GCM, ChaCha20-Poly1305)
- Enable Perfect Forward Secrecy (PFS) — ECDHE key exchange
- Use 2048-bit RSA or 256-bit ECDSA certificates
- Enable OCSP stapling
- Disable compression (CRIME/BREACH attacks)

HSTS (HTTP Strict Transport Security):
- Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
- Submit to HSTS preload list (hstspreload.org)
- Redirect HTTP → HTTPS at server level (301 permanent redirect)

Certificate management:
- Use Let's Encrypt (free, automated) or CA-signed certificates
- Automate renewal (certbot, ACME client)
- Monitor expiry (alert 30 days before)
- Use separate certificates per environment
- Implement CAA DNS records (restrict which CAs can issue certificates)
```

### 2. HTTP Security Headers

```
RULE: Set security headers on ALL responses.

Required headers:
- Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
- X-Content-Type-Options: nosniff
- X-Frame-Options: DENY (or SAMEORIGIN)
- Content-Security-Policy: [appropriate policy]
- Referrer-Policy: strict-origin-when-cross-origin
- Permissions-Policy: camera=(), microphone=(), geolocation=()
- X-XSS-Protection: 0 (disable broken browser filter, rely on CSP)
- Cross-Origin-Opener-Policy: same-origin
- Cross-Origin-Resource-Policy: same-origin
- Cross-Origin-Embedder-Policy: require-corp

Remove revealing headers:
- Server: (remove or change to generic value)
- X-Powered-By: (remove)
- X-AspNet-Version: (remove)
- X-AspNetMvc-Version: (remove)
```

### 3. Web Server Hardening

```
RULE: Harden web server configuration.

Nginx:
- server_tokens off (hide version)
- Disable directory listing (autoindex off)
- Set client_max_body_size appropriately
- Disable unnecessary modules
- Run as non-root user
- Set proper file permissions (644 for files, 755 for directories)
- Configure access and error logs
- Limit concurrent connections per IP

Apache:
- ServerTokens Prod (minimal version info)
- ServerSignature Off
- Options -Indexes (disable directory listing)
- Disable unnecessary modules (mod_info, mod_status in production)
- Set appropriate LimitRequestBody
- Use mod_security (WAF)

General:
- Disable HTTP TRACE/TRACK methods
- Set proper timeouts (connection, keep-alive, read, send)
- Configure error pages (no information leakage)
- Enable access logging
- Restrict administrative interfaces to internal network
```

### 4. Container Security

```
IF using Docker/containers:

Image security:
- Use official base images from trusted registries
- Use specific version tags (not :latest)
- Scan images for vulnerabilities (Trivy, Snyk, Grype)
- Use multi-stage builds (minimize final image size)
- Use distroless or Alpine base images
- Don't include build tools in production images
- Sign container images (Docker Content Trust, cosign)

Runtime security:
- Never run as root inside container (USER directive)
- Use read-only filesystem where possible (--read-only)
- Drop all capabilities, add only what's needed (--cap-drop ALL --cap-add ...)
- Set resource limits (--memory, --cpus)
- Use network policies (restrict container-to-container communication)
- Don't mount Docker socket inside containers
- Don't use --privileged flag
- Use security profiles (AppArmor, seccomp)

Secrets:
- Never put secrets in Dockerfile or image layers
- Use Docker secrets or mount secrets at runtime
- Use environment variables or mounted files (not build args)
- Scan image layers for accidentally committed secrets
```

### 5. CI/CD Pipeline Security

```
RULE: The CI/CD pipeline is a critical attack vector.

Pipeline security:
- Use separate service accounts for CI/CD (least privilege)
- Rotate CI/CD credentials regularly
- Use short-lived tokens where possible
- Audit pipeline configuration changes
- Sign commits and verify in pipeline
- Use branch protection (require reviews, status checks)
- Scan dependencies in pipeline (npm audit, pip audit, etc.)
- Run SAST (Static Application Security Testing) in pipeline
- Run DAST (Dynamic Application Security Testing) on staging
- Scan for secrets in code (gitleaks, trufflehog, detect-secrets)
- Use immutable build environments
- Pin tool versions in pipeline

Secrets in CI/CD:
- Use built-in secrets management (GitHub Secrets, GitLab CI Variables)
- Never echo secrets in logs
- Mask secrets in build output
- Limit secret access to specific branches/environments
- Rotate secrets after employee departure
```

### 6. Cloud Security

```
IF using cloud services (AWS, GCP, Azure):

Identity & Access:
- Use IAM roles (not long-lived access keys)
- Implement least privilege for all IAM policies
- Enable MFA for all human accounts
- Use service accounts for applications
- Rotate credentials regularly
- Audit IAM policies regularly (unused permissions)

Network:
- Use VPC/VNet for network isolation
- Configure security groups / firewall rules (deny by default)
- Use private subnets for databases and internal services
- Use NAT gateway for outbound internet access from private subnets
- Enable VPC flow logs
- Use VPN or PrivateLink for cross-service communication

Storage:
- Block public access on storage buckets by default
- Enable server-side encryption
- Enable versioning (data recovery)
- Enable access logging
- Set lifecycle policies (auto-delete old data)
- Use presigned URLs for temporary access

Monitoring:
- Enable cloud audit logs (CloudTrail, Cloud Audit Logs, Activity Log)
- Set up alerts for security events
- Enable GuardDuty / Security Center / Security Command Center
- Regular compliance scans (AWS Config, GCP Security Health Analytics)
```

### 7. DNS Security

```
RULE: DNS is a trust foundation. Protect it.

- Use DNSSEC (DNS Security Extensions) if supported
- Use CAA records (restrict which CAs can issue certs for your domain)
- Enable DNS logging
- Monitor for unauthorized DNS changes
- Use registrar lock (prevent domain transfer)
- Enable 2FA on domain registrar account
- Set low TTL during migrations, restore after
- Monitor for DNS hijacking (external DNS monitoring)
- Use DNS-based security services (DMARC, SPF, DKIM for email)
```

### 8. Firewall & Network Security

```
RULE: Default deny. Whitelist only required traffic.

Network firewall rules:
- Inbound: Allow only necessary ports (80, 443 for web)
- SSH: Restrict to bastion host or VPN only (not 0.0.0.0/0)
- Database: Internal network only (never public internet)
- Cache (Redis, Memcached): Internal network only
- Admin interfaces: Internal network or VPN only
- Outbound: Restrict to necessary destinations (prevents data exfiltration)

Web Application Firewall (WAF):
- Use WAF for public-facing applications
- Enable OWASP Core Rule Set (CRS)
- Custom rules for application-specific attacks
- Monitor and tune WAF rules (minimize false positives)
- Log WAF blocks for analysis
```

### 9. Logging & Monitoring

```
RULE: You can't secure what you can't see.

Log aggregation:
- Centralize logs (ELK, Datadog, Splunk, CloudWatch, Loki)
- Structured logging (JSON format)
- Include correlation IDs across services
- Set retention policies (compliance + operational needs)
- Encrypt logs at rest and in transit

Security monitoring:
- Real-time alerting on security events
- Anomaly detection (unusual traffic patterns, failed logins)
- Dashboards for security metrics
- Regular log review
- Incident response playbooks

Protect logs:
- Logs are append-only (prevent tampering)
- Restrict log access (not all engineers need production logs)
- Sanitize PII in logs (GDPR compliance)
- Never log secrets, passwords, or tokens
- Monitor for unauthorized log access
```

### 10. Backup & Disaster Recovery

```
RULE: Secure backups are critical for ransomware resilience.

Backup security:
- Encrypt all backups (separate key from primary system)
- Store backups offsite / different cloud region
- Test backup restoration regularly (quarterly minimum)
- Implement 3-2-1 rule (3 copies, 2 media types, 1 offsite)
- Use immutable backups (prevent ransomware deletion)
- Restrict backup access (separate credentials)
- Monitor backup job status

Disaster recovery:
- Document recovery procedures
- Define RTO (Recovery Time Objective) and RPO (Recovery Point Objective)
- Test DR plan regularly
- Automate recovery where possible
- Maintain infrastructure-as-code for rapid reconstruction
```

### 11. Dependency Management

```
RULE: Dependencies are attack surface. Manage them.

- Keep dependencies updated (security patches)
- Use lock files (package-lock.json, yarn.lock, Pipfile.lock, go.sum)
- Run dependency vulnerability scanning in CI/CD
- Monitor for security advisories (GitHub Dependabot, Snyk, etc.)
- Audit transitive dependencies (not just direct)
- Pin major versions (prevent breaking changes)
- Review changelogs before major updates
- Remove unused dependencies
- Consider dependency health (maintenance, community, security track record)
```

### 12. Secrets Management

```
RULE: Centralize and secure all secrets.

Secret management tools:
- HashiCorp Vault
- AWS Secrets Manager / SSM Parameter Store
- GCP Secret Manager
- Azure Key Vault
- Infisical
- doppler

Rules:
- Never commit secrets to version control
- Rotate secrets regularly (90 days for most, 24 hours for critical)
- Use different secrets per environment
- Audit secret access
- Implement secret revocation for compromised secrets
- Auto-rotate where possible (database passwords, API keys)
- Use short-lived credentials (STS tokens, IAM roles)
```
