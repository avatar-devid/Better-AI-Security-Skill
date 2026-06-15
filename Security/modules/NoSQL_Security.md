# NoSQL Injection Security — Deep Module

## Threat Description

NoSQL injection occurs when untrusted data is incorporated into NoSQL database queries without proper sanitization. Unlike SQL injection, NoSQL injection exploits query operators and data structures specific to document/key-value stores.

**CWE**: CWE-943 (Improper Neutralization of Special Elements in Data Query Logic)

---

## MongoDB Injection

### Operator Injection

```
THREAT: User sends query operators instead of simple values.

Vulnerable code (Node.js + Mongoose):
  app.post('/login', async (req, res) => {
    const user = await User.findOne({
      username: req.body.username,
      password: req.body.password      // ✗ UNSAFE
    });
  });

Attack payload:
  POST /login
  { "username": "admin", "password": { "$gt": "" } }

Resulting query:
  db.users.findOne({ username: "admin", password: { $gt: "" } })
  → password > "" is true for any non-empty password → auth bypass

Other dangerous operators:
  { "$ne": null }     → not equal null (matches all)
  { "$gt": "" }       → greater than empty string (matches all)
  { "$regex": ".*" }  → matches all
  { "$exists": true } → field exists (matches all)
  { "$in": [...] }    → membership check
  { "$where": "..." } → JavaScript execution!

Prevention:
  // Validate types — reject objects
  if (typeof req.body.password !== 'string') return res.status(400).send('Invalid');

  // Or use mongo-sanitize
  const sanitize = require('mongo-sanitize');
  const user = await User.findOne({
    username: sanitize(req.body.username),
    password: sanitize(req.body.password)
  });

  // Or use express-mongo-sanitize middleware
  app.use(mongoSanitize());  // Strips keys starting with $ and containing .
```

### $where / $expr Injection

```
THREAT: $where operator executes arbitrary JavaScript on the server.

Vulnerable:
  db.users.find({ $where: `this.username == '${username}'` })

Attack:
  username: ' || true || '
  → $where: this.username == '' || true || ''
  → Returns all users

RULE: NEVER use $where with user input.
RULE: Disable server-side JavaScript in MongoDB: --noscripting flag or security.javascriptEnabled: false
RULE: Use $expr with aggregation operators instead of $where.
```

### Aggregation Pipeline Injection

```
THREAT: Injecting operators into aggregation pipeline stages.

Vulnerable:
  db.orders.aggregate([
    { $match: { status: req.query.status } }  // If status is an object with operators
  ]);

Prevention:
- Validate all aggregation inputs as expected types
- Whitelist allowed values for enum-like fields
- Don't build pipeline stages from user input directly
- Validate pipeline structure before execution
```

---

## Redis Injection

### Command Injection

```
THREAT: Injecting Redis commands through unsanitized input.

Vulnerable:
  // Using raw command strings
  redis.send_command(`GET user:${userId}`)

  // Attack: userId = "1\r\nDEL user:admin"
  // Sends two commands: GET user:1 and DEL user:admin

Prevention:
- Use parameterized Redis client methods (not raw command strings)
  redis.get(`user:${sanitized_userId}`)
- Validate input format (alphanumeric only for keys)
- Use Redis ACL (Redis 6+) to restrict dangerous commands
- Disable EVAL/EVALSHA if Lua scripting not needed
- Disable CONFIG, FLUSHALL, FLUSHDB, DEBUG, KEYS in production
- Use Redis AUTH with strong password
- Bind to localhost or internal network only
```

---

## Elasticsearch Injection

### Query DSL Injection

```
THREAT: Injecting Elasticsearch query DSL operators.

Vulnerable:
  // Building query from user input
  const query = {
    query: {
      match: { title: req.query.search }
    }
  };
  // If search is an object: { "query": "...", "fuzziness": "AUTO" }

Dangerous queries:
  // Script injection
  { "script": { "source": "Runtime.getRuntime().exec('...')" } }

Prevention:
- Validate search input is a string
- Use simple_query_string for user-facing search (limited syntax)
- Disable scripting: script.allowed_types: none
- Or whitelist only stored scripts
- Use field-level security for sensitive data
- Set search timeout to prevent resource exhaustion
- Limit result size (from + size guard)
```

---

## NoSQL Security Checklist

```
1. ✓ Validate ALL input types — reject objects/arrays when strings expected
2. ✓ Use mongo-sanitize or equivalent (strip $ operators from input)
3. ✓ Disable server-side JavaScript ($where, mapReduce with JS)
4. ✓ Enable authentication on database (NEVER run without auth)
5. ✓ Use role-based access control (RBAC)
6. ✓ Encrypt connections (TLS)
7. ✓ Bind to internal network only (not 0.0.0.0)
8. ✓ Enable audit logging
9. ✓ Set query timeout / resource limits
10. ✓ Disable unnecessary features (scripting, admin endpoints)
11. ✓ Keep database version updated
12. ✓ Validate data schema (Mongoose schemas, JSON Schema)
13. ✓ Use field-level encryption for sensitive data (MongoDB CSFLE)
14. ✓ Implement application-level access control (not just DB-level)
```

---

## References

- OWASP NoSQL Injection: https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/07-Input_Validation_Testing/05.6-Testing_for_NoSQL_Injection
- MongoDB Security Checklist: https://www.mongodb.com/docs/manual/administration/security-checklist/
- CWE-943: https://cwe.mitre.org/data/definitions/943.html
