# gRPC Security — Deep Module

## Scope

Security specific to gRPC services: TLS configuration, authentication interceptors, input validation, reflection, and streaming security.

---

## gRPC Security Rules

### 1. Transport Security (TLS)

```
RULE: ALL gRPC connections MUST use TLS in production.

Server configuration:
- Use TLS 1.2 minimum (prefer 1.3)
- Use valid certificates (not self-signed in production)
- For internal services: use mTLS (mutual TLS)

// Go
creds, _ := credentials.NewServerTLSFromFile("server.crt", "server.key")
server := grpc.NewServer(grpc.Creds(creds))

// Node.js
const server = new grpc.Server();
const creds = grpc.ServerCredentials.createSsl(
  rootCert, [{ cert_chain: serverCert, private_key: serverKey }], true
);

// Java
Server server = NettyServerBuilder.forPort(443)
  .useTransportSecurity(certChainFile, privateKeyFile)
  .build();

NEVER use grpc.ServerCredentials.createInsecure() in production.
```

### 2. Authentication

```
RULE: Authenticate every RPC call.

Methods:
A. Token-based (JWT in metadata):
   // Client sends: metadata.set('authorization', 'Bearer ' + token)
   // Server interceptor validates token

B. mTLS (Mutual TLS):
   // Both client and server present certificates
   // Strongest for service-to-service communication

C. API Key:
   // Client sends: metadata.set('x-api-key', apiKey)
   // Server interceptor validates key

Interceptor pattern (Go):
func authInterceptor(ctx context.Context, req interface{},
  info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
  md, ok := metadata.FromIncomingContext(ctx)
  if !ok { return nil, status.Error(codes.Unauthenticated, "missing metadata") }
  token := md.Get("authorization")
  if !validateToken(token) {
    return nil, status.Error(codes.Unauthenticated, "invalid token")
  }
  return handler(ctx, req)
}
```

### 3. Authorization

```
RULE: Authorize at per-method level.

- Define permissions per RPC method
- Check user role/permission in interceptor
- Use method name from ServerInfo for routing authorization decisions
- Default deny for unknown methods
- Log authorization failures

Consider using:
- OPA (Open Policy Agent) for policy evaluation
- Custom interceptor with permission mapping
- Google CEL (Common Expression Language) for policy rules
```

### 4. Input Validation

```
RULE: Validate all protobuf message fields server-side.

Protobuf provides type safety but NOT business validation:
- int32 accepts any integer (need range check)
- string accepts any string (need format/length check)
- repeated fields can be empty or huge (need count limits)
- oneof fields may have no value set

Validation libraries:
- Go: protoc-gen-validate (PGV), buf/validate
- Java: protoc-gen-validate
- Python: Custom validators
- Node.js: Custom validation in handlers

// protoc-gen-validate example (.proto)
message CreateUserRequest {
  string email = 1 [(validate.rules).string.email = true];
  string name = 2 [(validate.rules).string = {min_len: 1, max_len: 100}];
  int32 age = 3 [(validate.rules).int32 = {gte: 0, lte: 150}];
}
```

### 5. Reflection

```
RULE: Disable gRPC reflection in production.

Reflection exposes all available services and methods (like GraphQL introspection).

// Go — don't register reflection in production
if env != "production" {
  reflection.Register(server)
}

// Java
if (!isProduction) {
  ProtoReflectionService.newInstance()
}

If reflection is needed for monitoring tools, restrict access via network policy.
```

### 6. Rate Limiting & Resource Protection

```
RULE: Protect gRPC services from resource exhaustion.

- Set maximum message size (default 4MB, adjust per-method if needed)
  grpc.MaxRecvMsgSize(10 * 1024 * 1024)  // 10 MB

- Set connection limits (max concurrent connections)
- Set per-method rate limits
- Set deadline/timeout on all RPCs
  ctx, cancel := context.WithTimeout(ctx, 5*time.Second)

- Limit concurrent streams per connection
  grpc.MaxConcurrentStreams(100)

- Implement keepalive settings
  grpc.KeepaliveParams(keepalive.ServerParameters{
    MaxConnectionIdle: 5 * time.Minute,
    Time: 2 * time.Hour,
  })
```

### 7. Streaming Security

```
IF using gRPC streaming:

- Validate each message in the stream individually
- Set maximum stream duration (timeout)
- Limit number of messages per stream
- Limit message size per stream message
- Handle client disconnection gracefully
- Authenticate at stream start AND validate session throughout
- Rate limit messages within streams
- Monitor stream duration for anomalies
```

### 8. Error Handling

```
RULE: Use proper gRPC status codes. Don't leak internals.

Safe status codes:
  codes.OK               → Success
  codes.InvalidArgument  → Bad request (validation error)
  codes.NotFound         → Resource not found
  codes.Unauthenticated  → Missing/invalid credentials
  codes.PermissionDenied → Insufficient permissions
  codes.AlreadyExists    → Duplicate resource
  codes.ResourceExhausted → Rate limited
  codes.Internal         → Server error (generic, no details to client)
  codes.Unavailable      → Service temporarily unavailable

NEVER include in error details:
- Stack traces
- Database errors
- Internal service names
- File paths
- Configuration details
```

### 9. Logging & Monitoring

```
- Log all RPC calls with: method, user, duration, status code
- Use OpenTelemetry / gRPC interceptors for tracing
- Monitor error rates per method
- Alert on unusual patterns (spikes in Unauthenticated/PermissionDenied)
- Don't log request/response bodies (may contain sensitive data)
- Use request IDs for correlation across services
```

---

## References

- gRPC Authentication Guide: https://grpc.io/docs/guides/auth/
- gRPC Security Best Practices: https://grpc.io/docs/guides/security/
