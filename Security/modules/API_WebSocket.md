# WebSocket Security — Deep Module

## Scope

Security specific to WebSocket connections: origin validation, authentication, message validation, DoS protection, and connection management.

---

## WebSocket Security Rules

### 1. Origin Validation

```
RULE: Validate the Origin header on WebSocket upgrade request.

WebSocket connections are NOT restricted by Same-Origin Policy.
Any website can open a WebSocket connection to your server.

// Server-side validation
wss.on('connection', (ws, req) => {
  const origin = req.headers.origin;
  const allowedOrigins = ['https://app.example.com', 'https://www.example.com'];
  if (!allowedOrigins.includes(origin)) {
    ws.close(1008, 'Origin not allowed');
    return;
  }
});

NEVER skip origin validation — this is the WebSocket equivalent of CORS.
```

### 2. Authentication

```
RULE: Authenticate WebSocket connections before establishing them.

Methods:

A. Token in URL (simple but less secure):
   ws://example.com/ws?token=JWT_TOKEN
   - Token visible in logs and browser history
   - Use only with short-lived tokens

B. Token in first message (recommended for SPAs):
   1. Connect WebSocket
   2. Send auth message: { type: "auth", token: "JWT_TOKEN" }
   3. Server validates token
   4. If invalid → close connection immediately
   5. If valid → mark connection as authenticated
   6. Reject all other messages until authenticated

C. Cookie-based (recommended for web apps):
   - Session cookie sent automatically with upgrade request
   - Validate session on upgrade
   - Combined with origin validation → CSRF protection

D. Ticket-based (most secure):
   1. Client requests one-time ticket via authenticated REST API
   2. Client connects: ws://example.com/ws?ticket=ONE_TIME_TICKET
   3. Server validates ticket (single-use, short expiry: 30 seconds)
   4. Server establishes authenticated connection

RULE: Re-validate authentication periodically for long-lived connections.
RULE: Close connection immediately on auth failure (don't just ignore messages).
```

### 3. Message Validation

```
RULE: Validate EVERY incoming WebSocket message.

- Parse as JSON (reject malformed messages)
- Validate message type/action (whitelist allowed types)
- Validate payload schema (type, length, format per field)
- Reject unknown message types
- Set maximum message size (prevent memory exhaustion)
- Rate limit messages per connection
- Sanitize text content (prevent XSS if messages are rendered as HTML)

// Example validation
ws.on('message', (data) => {
  let msg;
  try { msg = JSON.parse(data); } catch { ws.close(1003, 'Invalid JSON'); return; }
  if (!VALID_TYPES.includes(msg.type)) { ws.close(1003, 'Unknown type'); return; }
  if (msg.content?.length > 10000) { ws.close(1009, 'Message too large'); return; }
  // Process validated message
});
```

### 4. DoS Protection

```
RULE: Protect against WebSocket-based denial of service.

Connection limits:
- Max connections per IP (e.g., 10)
- Max connections per user (e.g., 5)
- Max total connections per server
- Connection timeout for unauthenticated connections (10 seconds)

Message limits:
- Max message size (64KB-1MB depending on use case)
- Max messages per second per connection (50-100)
- Max total bandwidth per connection
- Slow message detection (incomplete frames held too long)

Resource limits:
- Connection idle timeout (close after 30 min of no messages)
- Maximum connection duration (close after 24 hours, reconnect)
- Heartbeat/ping interval (detect dead connections)

// Ping/pong keepalive
const interval = setInterval(() => {
  wss.clients.forEach(ws => {
    if (!ws.isAlive) return ws.terminate();
    ws.isAlive = false;
    ws.ping();
  });
}, 30000);

ws.on('pong', () => { ws.isAlive = true; });
```

### 5. Authorization per Message

```
RULE: Check authorization for each message action, not just at connection time.

User's permissions may change during a long-lived connection:
- User role changed by admin
- User subscription expired
- User banned/suspended
- Resource permissions changed

// Per-message auth check
ws.on('message', async (data) => {
  const msg = JSON.parse(data);
  const user = await getUser(ws.userId);  // Refresh from DB/cache
  if (!user.active) { ws.close(1008, 'Account suspended'); return; }
  if (!authorize(user, msg.type, msg.resource)) {
    ws.send(JSON.stringify({ error: 'Forbidden' }));
    return;
  }
  // Process message
});
```

### 6. Room/Channel Security

```
IF WebSocket supports rooms/channels (chat, notifications):

- Validate user has access to the room before joining
- Re-validate on room events (user removed, room deleted, permission changed)
- Prevent room enumeration (don't reveal room list to unauthorized users)
- Rate limit room join/leave operations
- Limit rooms per user
- Broadcast only to authorized users in the room
- Log room join/leave events

// Socket.IO example
io.on('connection', (socket) => {
  socket.on('join-room', async (roomId) => {
    if (!await canAccessRoom(socket.userId, roomId)) {
      socket.emit('error', 'Access denied');
      return;
    }
    socket.join(roomId);
  });
});
```

### 7. Data Exposure Prevention

```
RULE: Be careful what data is broadcast.

- Never broadcast sensitive data to all connected clients
- Filter outgoing messages based on recipient's permissions
- Don't include internal IDs, tokens, or metadata in broadcast messages
- Sanitize user-generated content before broadcasting
- Log all broadcast events for audit
```

### 8. Secure Close

```
RULE: Handle connection closure securely.

- Clean up resources on close (remove from rooms, release locks)
- Log disconnection with reason code
- Don't reveal internal state in close reason
- Handle abnormal closures (network drop, crash)
- Implement reconnection with authentication (don't resume old session without re-auth)
- Clear any cached user state on close

Close codes:
  1000 - Normal closure
  1001 - Going away (server shutting down)
  1003 - Unsupported data (invalid message format)
  1008 - Policy violation (authentication/authorization failure)
  1009 - Message too big
  1011 - Unexpected server error (don't include details)
```

---

## References

- OWASP WebSocket Security: https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/11-Client-side_Testing/10-Testing_WebSockets
- RFC 6455 (WebSocket Protocol): https://tools.ietf.org/html/rfc6455
