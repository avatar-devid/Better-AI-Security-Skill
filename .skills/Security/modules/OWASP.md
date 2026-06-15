# OWASP Reference — Deep Module

## OWASP Top 10 (2021) — Quick Reference

```
A01: Broken Access Control
  → See: modules/RBAC.md, modules/IDOR.md
  → Ensure authorization checks on every request
  → Default deny, validate resource ownership

A02: Cryptographic Failures
  → See: Security_Crypto.md, modules/Password.md
  → Use strong algorithms, protect data at rest and in transit
  → Never store secrets in code

A03: Injection
  → See: modules/SQL_Security.md, modules/NoSQL_Security.md, modules/XSS.md, modules/RCE.md
  → Parameterize all queries, validate all input, encode all output

A04: Insecure Design
  → Threat modeling during design phase
  → Secure by default, defense in depth
  → Use established security patterns, don't invent your own

A05: Security Misconfiguration
  → See: Security_Infrastructure.md
  → Harden all components, remove defaults, disable unnecessary features
  → Automate configuration with infrastructure-as-code

A06: Vulnerable and Outdated Components
  → Keep dependencies updated, scan for vulnerabilities
  → Use lock files, monitor advisories, remove unused dependencies

A07: Identification and Authentication Failures
  → See: Security_Auth.md, modules/Password.md, modules/MFA.md, modules/JWT.md
  → Strong password policy, MFA, session management, brute force protection

A08: Software and Data Integrity Failures
  → Verify software updates (signatures), use SRI for CDN resources
  → Secure CI/CD pipeline, validate deserialized data

A09: Security Logging and Monitoring Failures
  → See: modules/Logging.md
  → Log security events, monitor for anomalies, alert on incidents

A10: Server-Side Request Forgery (SSRF)
  → See: modules/SSRF.md
  → Validate URLs, block private IPs, use allowlists
```

---

## OWASP ASVS (Application Security Verification Standard) v4.0

### Verification Levels

```
Level 1: Minimum — automated vulnerability scanning
  → All applications should meet Level 1
  → Focus: Top 10 vulnerabilities, basic security controls

Level 2: Standard — most applications
  → Deeper testing, security architecture review
  → Focus: Defense in depth, secure defaults, complete threat coverage

Level 3: Advanced — high-value applications (finance, health, military)
  → Comprehensive security assessment
  → Focus: Zero trust, advanced threat modeling, formal verification
```

### Key ASVS Categories

```
V1: Architecture, Design and Threat Modeling
  - Secure architecture documentation
  - Threat model for the application
  - Security controls identified for each threat

V2: Authentication
  - Password policy (NIST SP 800-63B)
  - MFA support
  - Credential storage (Argon2id, bcrypt)
  - Anti-automation (rate limiting, CAPTCHA)

V3: Session Management
  - Session ID generation (CSPRNG, 128+ bits)
  - Session timeout (idle + absolute)
  - Session fixation prevention
  - Cookie security flags

V4: Access Control
  - Principle of least privilege
  - Server-side enforcement
  - CORS configuration
  - Directory traversal prevention

V5: Validation, Sanitization and Encoding
  - Input validation (whitelist)
  - Output encoding (context-appropriate)
  - HTML sanitization
  - SQL injection prevention

V6: Stored Cryptography
  - Approved algorithms only
  - Key management
  - Random number generation (CSPRNG)

V7: Error Handling and Logging
  - Generic error messages to users
  - Security event logging
  - Log protection

V8: Data Protection
  - Sensitive data classification
  - Encryption at rest and in transit
  - Data minimization

V9: Communication
  - TLS for all connections
  - Certificate validation
  - HSTS

V10: Malicious Code
  - No backdoors
  - No time bombs
  - Integrity verification

V11: Business Logic
  - Business flow validation
  - Transaction limits
  - Anti-automation

V12: Files and Resources
  - File upload validation
  - File storage security
  - Path traversal prevention

V13: API and Web Service
  - REST/GraphQL/gRPC security
  - Input validation
  - Rate limiting

V14: Configuration
  - Security headers
  - Dependency management
  - Build pipeline security
```

---

## OWASP API Security Top 10 (2023)

```
API1: Broken Object Level Authorization (BOLA)
  → Same as IDOR. Check resource ownership on every request.

API2: Broken Authentication
  → Weak auth mechanisms, missing MFA, exposed credentials.

API3: Broken Object Property Level Authorization
  → Mass assignment, excessive data exposure in responses.

API4: Unrestricted Resource Consumption
  → Missing rate limiting, no pagination limits, no request size limits.

API5: Broken Function Level Authorization
  → Missing role checks, admin endpoints accessible to users.

API6: Unrestricted Access to Sensitive Business Flows
  → No protection against automated abuse (ticket scalping, credential stuffing).

API7: Server Side Request Forgery (SSRF)
  → API fetches user-provided URLs without validation.

API8: Security Misconfiguration
  → Default credentials, unnecessary features, verbose errors, missing headers.

API9: Improper Inventory Management
  → Old API versions still running, undocumented endpoints, shadow APIs.

API10: Unsafe Consumption of APIs
  → Trusting third-party API responses without validation.
```

---

## OWASP Mobile Top 10 (2024)

```
M1: Improper Credential Usage
M2: Inadequate Supply Chain Security
M3: Insecure Authentication/Authorization
M4: Insufficient Input/Output Validation
M5: Insecure Communication
M6: Inadequate Privacy Controls
M7: Insufficient Binary Protections
M8: Security Misconfiguration
M9: Insecure Data Storage
M10: Insufficient Cryptography
```

---

## Security Testing Resources

```
Methodologies:
- OWASP Testing Guide (WSTG): https://owasp.org/www-project-web-security-testing-guide/
- OWASP MASTG (Mobile): https://mas.owasp.org/MASTG/
- PTES (Penetration Testing Execution Standard)

Tools:
- SAST: SonarQube, Semgrep, CodeQL, Snyk Code
- DAST: OWASP ZAP, Burp Suite, Nuclei
- SCA: Snyk, npm audit, Dependabot, Trivy
- Secrets: gitleaks, trufflehog, detect-secrets
- Infrastructure: ScoutSuite, Prowler, Checkov

Standards:
- OWASP ASVS: https://owasp.org/www-project-application-security-verification-standard/
- NIST Cybersecurity Framework: https://www.nist.gov/cyberframework
- CIS Benchmarks: https://www.cisecurity.org/cis-benchmarks
- PCI-DSS: https://www.pcisecuritystandards.org/
```
