# SSRF (Server-Side Request Forgery) — Deep Module

## Threat Description

SSRF occurs when an attacker can make the server send requests to unintended destinations, potentially accessing internal services, cloud metadata, or performing port scanning.

**Impact**: Access to internal services (databases, admin panels), cloud metadata theft (IAM credentials), internal network scanning, remote code execution (via internal services).

**CWE**: CWE-918 (Server-Side Request Forgery)

---

## Attack Vectors

```
1. URL parameter: GET /api/fetch?url=http://169.254.169.254/latest/meta-data/
2. Webhook URLs: POST /webhooks { "url": "http://internal-admin:8080/delete-all" }
3. File imports: POST /import { "url": "file:///etc/passwd" }
4. Image/avatar URL: PUT /profile { "avatar_url": "http://10.0.0.1:6379/FLUSHALL" }
5. PDF generation: POST /generate-pdf { "html": "<img src='http://internal:8080'>" }
6. XML/XXE: <!ENTITY xxe SYSTEM "http://internal:8080">
7. Redirect chains: http://evil.com → 302 → http://169.254.169.254/

Cloud metadata endpoints (high-value targets):
- AWS: http://169.254.169.254/latest/meta-data/iam/security-credentials/
- GCP: http://metadata.google.internal/computeMetadata/v1/
- Azure: http://169.254.169.254/metadata/instance?api-version=2021-02-01
- DigitalOcean: http://169.254.169.254/metadata/v1/
```

---

## Prevention

```
1. URL Validation (whitelist approach):
   - Whitelist allowed domains/IPs
   - Whitelist allowed protocols (https:// only)
   - Whitelist allowed ports (443, 80)
   - Reject private IP ranges, localhost, link-local addresses

2. Block Private/Internal IPs:
   - 10.0.0.0/8
   - 172.16.0.0/12
   - 192.168.0.0/16
   - 127.0.0.0/8 (localhost)
   - 169.254.0.0/16 (link-local / cloud metadata)
   - 0.0.0.0/8
   - ::1 (IPv6 localhost)
   - fd00::/8 (IPv6 private)

3. DNS resolution validation:
   - Resolve hostname BEFORE making request
   - Verify resolved IP is not private/internal
   - Beware of DNS rebinding (hostname resolves to internal IP)
   - Use DNS pinning (resolve once, use resolved IP)

4. Network-level protection:
   - Use a proxy/gateway for outbound requests
   - Block outbound requests to internal network from application servers
   - Use IMDSv2 (AWS) — requires token-based access to metadata

5. Disable unnecessary protocols:
   - Block file://, gopher://, dict://, ftp://
   - Allow only https:// (and http:// if absolutely necessary)

6. Follow redirects cautiously:
   - Limit redirect count (max 3)
   - Re-validate URL after each redirect
   - Don't follow redirects to private IPs

Example validation (Node.js):
  const url = new URL(userProvidedUrl);
  if (!['https:'].includes(url.protocol)) throw new Error('Invalid protocol');
  const resolved = await dns.resolve4(url.hostname);
  if (isPrivateIP(resolved[0])) throw new Error('Private IP blocked');
```

---

## References

- OWASP SSRF: https://owasp.org/www-community/attacks/Server_Side_Request_Forgery
- CWE-918: https://cwe.mitre.org/data/definitions/918.html
