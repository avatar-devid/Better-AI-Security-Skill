# Rate Limiting — Deep Module

## Threat Description

Without rate limiting, attackers can perform brute force attacks, credential stuffing, API abuse, denial of service, and resource exhaustion.

---

## Rate Limiting Strategies

### Algorithms

```
1. Fixed Window:
   - Count requests per time window (e.g., 100/minute)
   - Simple but has burst at window boundaries
   
2. Sliding Window:
   - Smooth counting across time windows
   - Better than fixed window, slightly more complex

3. Token Bucket:
   - Tokens added at fixed rate, consumed per request
   - Allows bursts up to bucket size
   - Good for APIs with variable traffic

4. Leaky Bucket:
   - Requests processed at fixed rate
   - Excess requests queued or rejected
   - Smoothest output rate
```

### Implementation

```
// Node.js (express-rate-limit)
const rateLimit = require('express-rate-limit');
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 100,                    // 100 requests per window
  standardHeaders: true,       // Return RateLimit-* headers
  legacyHeaders: false,
  keyGenerator: (req) => req.ip,  // Rate limit by IP
  handler: (req, res) => {
    res.status(429).json({ error: 'Too many requests', retryAfter: 900 });
  }
});
app.use('/api/', limiter);

// Stricter for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,  // Only 10 login attempts per 15 minutes
  keyGenerator: (req) => `${req.ip}:${req.body.email}`,  // Per IP+email
});
app.use('/api/auth/login', authLimiter);

// Redis-based (distributed)
const RedisStore = require('rate-limit-redis');
const limiter = rateLimit({
  store: new RedisStore({ client: redisClient }),
  windowMs: 60000,
  max: 100,
});
```

### Recommended Limits by Endpoint

```
| Endpoint Type          | Limit              | Key           |
|------------------------|---------------------|---------------|
| Login                  | 5-10/15min          | IP + email    |
| Registration           | 3-5/hour            | IP            |
| Password reset         | 3/hour              | email         |
| MFA verification       | 5/5min              | user ID       |
| API (authenticated)    | 100-1000/min        | user ID       |
| API (unauthenticated)  | 20-50/min           | IP            |
| File upload            | 10-20/hour          | user ID       |
| Search                 | 30/min              | IP + user ID  |
| Email sending          | 5/hour              | user ID       |
| Export/download         | 5/hour              | user ID       |
| Webhook                | 100/min             | source IP     |

Response: 429 Too Many Requests
Headers: Retry-After, X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset
```

### Layered Rate Limiting

```
RULE: Implement rate limiting at multiple layers.

Layer 1: Infrastructure (Nginx, CDN, API Gateway)
  - Broadest limits (10,000 req/min per IP)
  - Handles DDoS-level traffic
  
Layer 2: Application middleware
  - Per-endpoint limits
  - User-aware limits
  
Layer 3: Business logic
  - Per-operation limits (3 password resets/hour)
  - Per-resource limits (10 comments/hour per post)
```

---

## References

- OWASP Rate Limiting: https://cheatsheetseries.owasp.org/cheatsheets/Denial_of_Service_Cheat_Sheet.html
