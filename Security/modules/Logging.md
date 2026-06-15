# Security Logging & Monitoring — Deep Module

## Threat Description

Without proper logging and monitoring, breaches go undetected. The average breach takes 277 days to detect (IBM Cost of a Data Breach 2023). Security logging is the foundation of incident detection and response.

---

## What to Log

### Security Events (MUST log)

```
Authentication:
- Login success (user, IP, user agent, timestamp)
- Login failure (user/email attempted, IP, user agent, reason)
- Logout (user, session duration)
- Password change (user, IP)
- Password reset request (email, IP)
- MFA enrollment/removal (user, method)
- MFA verification (success/failure)
- Account lockout (user, trigger count)
- Session creation/destruction

Authorization:
- Access denied (user, resource, action, reason)
- Privilege escalation attempts
- Role/permission changes (who changed, what changed, by whom)
- Admin actions (what, who, target)

Data access:
- Sensitive data access (who accessed what)
- Data export/download (user, data type, volume)
- Bulk operations (user, operation, count)

Input validation:
- Rejected inputs (type, value pattern — NOT full value if sensitive)
- Suspected injection attempts (SQLi, XSS patterns detected)
- File upload rejections (reason, file type)

System:
- Application startup/shutdown
- Configuration changes
- Error rates (spikes)
- Rate limit triggers
- Certificate expiry warnings
```

### What NOT to Log

```
NEVER log:
- Passwords (plain text or hashed)
- Session tokens / JWT tokens
- API keys / secrets
- Credit card numbers (even partial — PCI-DSS)
- Social Security Numbers
- Full request/response bodies (may contain PII)
- Encryption keys
- Database connection strings
- Internal IP addresses (in customer-facing logs)

Mask sensitive data:
- Email: j***@example.com
- Phone: ***-***-1234
- Card: ****-****-****-1234
- IP: Log full IP for security, but mask in analytics
```

---

## Log Format

```
RULE: Use structured logging (JSON).

{
  "timestamp": "2024-01-15T10:30:45.123Z",
  "level": "WARN",
  "event": "auth.login.failure",
  "requestId": "req_abc123",
  "userId": null,
  "email": "j***@example.com",
  "ip": "203.0.113.42",
  "userAgent": "Mozilla/5.0...",
  "reason": "invalid_password",
  "attemptCount": 3,
  "service": "auth-service",
  "environment": "production"
}

Required fields:
- timestamp (ISO 8601, UTC)
- level (DEBUG, INFO, WARN, ERROR, FATAL)
- event (dotted namespace: category.action.result)
- requestId (correlation ID)
- service (which service generated the log)

Optional but recommended:
- userId, ip, userAgent (who)
- resource, action (what)
- duration (how long)
- traceId, spanId (distributed tracing)
```

---

## Monitoring & Alerting

```
Alert immediately (P1 — within minutes):
- Multiple failed logins from same IP (brute force)
- Admin account login from new IP
- Privilege escalation detected
- Unusual data export volume
- Rate limit exceeded repeatedly
- Authentication bypass attempt
- Known attack patterns detected (SQLi, XSS in logs)

Alert promptly (P2 — within hours):
- New admin user created
- Bulk data access
- Failed MFA attempts
- Certificate expiry < 7 days
- Error rate spike (>5x baseline)
- Unusual geographic access patterns

Review daily (P3):
- Failed login summary
- Access denied summary  
- Rate limit trigger summary
- New user registrations
- Configuration changes

Tools:
- SIEM: Splunk, Elastic SIEM, Datadog Security, Azure Sentinel
- Log aggregation: ELK Stack, Loki + Grafana, CloudWatch, Datadog
- Alerting: PagerDuty, OpsGenie, custom webhooks
```

---

## Log Protection

```
RULE: Logs are security-critical data. Protect them.

1. Integrity: Append-only storage (prevent tampering)
2. Confidentiality: Encrypt logs at rest and in transit
3. Access control: Restrict who can read logs (not all engineers)
4. Retention: Follow compliance requirements (PCI: 1 year, SOX: 7 years)
5. Availability: Centralized storage (survive server compromise)
6. Monitoring: Alert on log pipeline failures (attacker may try to disable logging)
```

---

## References

- OWASP Logging Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
- OWASP Top 10 A09:2021 Security Logging and Monitoring Failures
