# Security — API

## Scope

This module covers security for any server-exposed interface: REST APIs, GraphQL endpoints, gRPC services, WebSocket connections, and webhooks.

## Sub-Router

```
IF task contains [REST, HTTP endpoint, GET, POST, PUT, PATCH, DELETE, Express, FastAPI, Spring Boot, ASP.NET, Gin, Echo, Fiber, Hono, NestJS, Django REST, Rails API, Laravel]
    LOAD modules/API_REST.md

IF task contains [GraphQL, Apollo, Hasura, Relay, Query, Mutation, Subscription, Schema, Resolver]
    LOAD modules/API_GraphQL.md

IF task contains [gRPC, Protocol Buffers, Protobuf, Tonic, gRPC-Go, gRPC-Java]
    LOAD modules/API_gRPC.md

IF task contains [WebSocket, Socket.IO, WS, Real-time, SignalR, Pusher, Ably, SSE]
    LOAD modules/API_WebSocket.md
```

## Universal API Security Rules

These rules apply to ALL API types regardless of protocol:

### 1. Authentication

```
RULE: Every API endpoint MUST be authenticated unless explicitly public.
RULE: Use standard authentication mechanisms (Bearer token, API key, mTLS).
RULE: API keys are NOT a substitute for user authentication.
RULE: Authenticate at the gateway/middleware level, not in individual handlers.

Public endpoint whitelist pattern:
- Health check: GET /health
- API documentation: GET /docs (staging only, NOT production)
- Authentication endpoints: POST /auth/login, POST /auth/register
- Password reset: POST /auth/forgot-password
- Webhook receivers (validate via signature)
```

### 2. Authorization

```
RULE: Check authorization on EVERY request, not just at login.
RULE: Authorization must be server-side. Never trust client claims.
RULE: Use principle of least privilege — default deny.

Check these in order:
1. Is the user authenticated?
2. Is the user's account active (not suspended/deleted)?
3. Does the user have the required role/permission?
4. Does the user own/have access to the specific resource?
5. Is the action allowed given the current state?
```

### 3. Input Validation

```
RULE: Validate EVERY input field. Never trust client data.

Validation layers:
1. Schema validation (type, required fields, structure)
2. Business validation (ranges, formats, relationships)
3. Sanitization (trim, normalize, encode)

Tools:
- JSON Schema, Zod, Yup, Joi, class-validator
- Pydantic (Python), FluentValidation (.NET)
- Bean Validation (Java)

NEVER:
- Use eval() or equivalent on input
- Build dynamic queries from input
- Use input as file paths without validation
- Use input as command arguments without escaping
- Deserialize untrusted data without schema validation
```

### 4. Rate Limiting

```
RULE: Every public endpoint MUST have rate limiting.

Recommended limits:
- Authentication endpoints: 5-10 requests/minute per IP
- Password reset: 3 requests/hour per email
- API general: 100-1000 requests/minute per user
- Registration: 3-5 requests/hour per IP
- File upload: 10-20 requests/hour per user

Implementation:
- Use sliding window or token bucket algorithm
- Rate limit by: IP, User ID, API Key (layered)
- Return 429 Too Many Requests with Retry-After header
- Do NOT reveal rate limit internals to client
```

### 5. Response Security

```
RULE: API responses must be minimal — return only what the client needs.

- Never return passwords, hashes, or secrets
- Never return internal IDs if public IDs exist
- Never return server-side metadata (internal timestamps, debug info)
- Never return other users' data in the same response
- Use field selection / sparse fieldsets when possible
- Paginate all list endpoints (max page size enforced server-side)
```

### 6. Error Handling

```
RULE: Use consistent error format. Never leak internals.

Safe error response:
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email format is invalid",
    "requestId": "req_abc123"
  }
}

NEVER return:
- Stack traces
- SQL error messages
- File paths
- Internal service names
- Database schema details
```

### 7. CORS Policy

```
RULE: Configure CORS explicitly. Never use Access-Control-Allow-Origin: *
       (except for truly public, read-only APIs with no auth).

Checklist:
- Whitelist specific origins (not wildcard)
- Restrict allowed methods to those actually used
- Restrict allowed headers to those actually needed
- Set Access-Control-Max-Age for preflight caching
- Credentials mode: only if cookies/auth headers needed
- Never reflect Origin header back without validation
```

### 8. Request Size Limits

```
RULE: Enforce maximum request body size.

- JSON body: 1 MB default (adjust per endpoint)
- File upload: per-endpoint limit (see Security_FileUpload.md)
- URL parameters: 2048 characters
- Headers: 8 KB total
- Reject oversized requests before parsing

Also limit:
- Array length in JSON body
- Object nesting depth (max 5-10 levels)
- String field length (per-field limits)
```

### 9. Idempotency

```
RULE: Non-GET endpoints that modify state should support idempotency keys.

- Client sends Idempotency-Key header
- Server stores result and returns cached response for duplicate keys
- Prevents duplicate payments, double-creates, race conditions
- Key expiry: 24-48 hours
```

### 10. Versioning & Deprecation

```
RULE: Never remove or change API fields/endpoints without deprecation period.

- Use API versioning (URL path /v1/ or Accept header)
- Deprecation header: Deprecation: true, Sunset: <date>
- Maintain backward compatibility within a version
- Log usage of deprecated endpoints for migration tracking
```

### 11. Logging & Monitoring

```
RULE: Log every API request with security-relevant metadata.

Log:
- Timestamp, Request ID
- HTTP method, path, status code
- User ID (if authenticated)
- Client IP (consider proxies: X-Forwarded-For)
- Response time
- Rate limit remaining

Do NOT log:
- Request/response bodies (except in debug mode, never in production)
- Passwords, tokens, secrets
- Full credit card numbers
- Personal health information

Alert on:
- Spike in 401/403 errors (brute force)
- Spike in 500 errors (application failure)
- Unusual request patterns (scanning)
- Rate limit hits from single source
```

### 12. Webhook Security

```
IF the API receives webhooks:
- Verify webhook signatures (HMAC-SHA256)
- Validate webhook source IP (if provider publishes IP ranges)
- Use idempotency to handle duplicate deliveries
- Process webhooks asynchronously (queue, not inline)
- Set timeout on webhook processing
- Return 200 quickly, process later

IF the API sends webhooks:
- Sign payloads with HMAC-SHA256
- Use HTTPS only
- Implement retry with exponential backoff
- Allow customers to verify signatures
- Include timestamp in signature to prevent replay
```
