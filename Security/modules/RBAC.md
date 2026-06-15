# RBAC / Authorization — Deep Module

## Threat Description

Broken access control is the #1 risk in OWASP Top 10 (2021). Authorization flaws allow users to access data or perform actions beyond their intended permissions.

**CWE**: CWE-285 (Improper Authorization), CWE-862 (Missing Authorization), CWE-863 (Incorrect Authorization)

---

## Authorization Models

### RBAC (Role-Based Access Control)

```
Concept: Users are assigned roles, roles have permissions.

Structure:
  User → Role(s) → Permission(s) → Resource + Action

Example:
  User "john" → Role "editor" → Permissions ["post:create", "post:edit", "post:delete"]
  User "jane" → Role "admin"  → Permissions ["*"]  (all permissions)
  User "bob"  → Role "viewer" → Permissions ["post:read"]

Database schema:
  users:        id, name, email
  roles:        id, name, description
  permissions:  id, name (resource:action format)
  user_roles:   user_id, role_id
  role_permissions: role_id, permission_id

RULE: Users should have the MINIMUM roles necessary.
RULE: Roles should have the MINIMUM permissions necessary.
RULE: Default role for new users: lowest privilege (e.g., "viewer" or "member").
```

### ABAC (Attribute-Based Access Control)

```
Concept: Access decisions based on attributes of user, resource, action, and environment.

Example:
  IF user.department == resource.department
  AND user.clearance >= resource.classification
  AND environment.time is within business_hours
  AND action == "read"
  THEN allow

Advantages over RBAC:
- More granular control
- Context-aware (time, location, device)
- Scales better for complex organizations
- Fewer role explosion problems

Use ABAC when:
- Multi-tenant applications
- Complex access rules based on data attributes
- Regulatory compliance requires fine-grained control
```

### Policy-Based (OPA, Casbin, Cedar)

```
Concept: Externalize authorization logic into policy engines.

Tools:
- OPA (Open Policy Agent): Rego language, general-purpose
- Casbin: Multiple models (RBAC, ABAC, ACL), multiple languages
- Cedar (AWS): Purpose-built for authorization
- Oso: Application-level authorization

Benefits:
- Authorization logic separate from business logic
- Testable policies
- Auditable decisions
- Centralized policy management
- Policy-as-code (version controlled)
```

---

## Implementation Security

### 1. Server-Side Enforcement

```
ABSOLUTE RULE: ALL authorization checks MUST be server-side.

Client-side: UI may hide buttons/menus based on role (UX only)
Server-side: MUST verify authorization on EVERY request

// Middleware pattern (Express.js)
function authorize(...requiredPermissions) {
  return (req, res, next) => {
    const userPermissions = req.user.permissions;
    const hasAll = requiredPermissions.every(p => userPermissions.includes(p));
    if (!hasAll) return res.status(403).json({ error: 'Forbidden' });
    next();
  };
}

app.delete('/api/posts/:id', authorize('post:delete'), deletePost);

NEVER:
- Rely on hidden UI elements for security
- Trust client-provided role/permission claims
- Skip authorization for "internal" endpoints
```

### 2. Resource-Level Authorization

```
RULE: Authorize access to SPECIFIC resources, not just actions.

INSUFFICIENT: Can the user delete posts? (action-level only)
REQUIRED: Can the user delete THIS SPECIFIC post? (resource-level)

// Check ownership
async function deletePost(req, res) {
  const post = await Post.findById(req.params.id);
  if (!post) return res.status(404).json({ error: 'Not found' });
  
  // Authorization check: user owns the post OR user is admin
  if (post.authorId !== req.user.id && !req.user.roles.includes('admin')) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  
  await post.delete();
}

This prevents IDOR (Insecure Direct Object Reference).
See modules/IDOR.md for details.
```

### 3. Multi-Tenancy Authorization

```
RULE: Tenant isolation is a critical authorization boundary.

Every database query MUST include tenant filter:
  // UNSAFE — missing tenant filter
  const users = await User.find({ role: 'admin' });  // Returns admins from ALL tenants!
  
  // SAFE — tenant-scoped
  const users = await User.find({ tenantId: req.user.tenantId, role: 'admin' });

Implementation patterns:
A. Query-level filtering (add WHERE tenant_id = ? to every query)
B. Global scope / middleware (ORM automatically filters by tenant)
C. Separate databases per tenant (strongest isolation)
D. Row-Level Security (PostgreSQL RLS)

RULE: Use global scoping to prevent developers from forgetting tenant filters.
RULE: Test cross-tenant access in integration tests.
```

### 4. Privilege Escalation Prevention

```
Vertical escalation: User gains higher role (user → admin)
Horizontal escalation: User accesses another user's data (user A → user B's data)

Prevention:
1. Validate role changes through admin-only endpoints
2. Validate resource ownership on every access
3. Don't trust client-provided role/privilege data
4. Log all role changes
5. Require admin re-authentication for role modifications
6. Implement separation of duties (user can't approve their own role change)
7. Alert on unusual privilege patterns (user suddenly has admin)
```

### 5. Default Deny

```
RULE: Default to DENY. Explicitly ALLOW.

// WRONG: Default allow, deny specific
if (user.role === 'banned') return deny();
return allow();  // Everyone else gets access — dangerous

// RIGHT: Default deny, allow specific
if (user.permissions.includes('resource:action')) return allow();
return deny();  // Default: no access

Apply at every level:
- Route level: unauthenticated routes must be explicitly whitelisted
- Controller level: unauthorized actions denied by default
- Data level: unowned resources inaccessible by default
```

### 6. Authorization Caching

```
IF caching authorization decisions:

RULE: Invalidate cache when permissions change.

- Cache TTL: 5-15 minutes maximum
- Invalidate on: role change, permission change, logout, password change
- Use per-user cache (never share authorization cache between users)
- Cache DENIALS too (prevents repeated lookups)
- Include cache version in session (force refresh when permissions change)
```

### 7. API Key Authorization

```
IF using API keys for authorization:

- API keys identify the APPLICATION, not the user
- API keys should have scoped permissions (not full access)
- Allow multiple API keys per user/app
- Support key rotation (create new → migrate → revoke old)
- Set key expiry (90 days recommended)
- Allow key revocation (immediate effect)
- Log all API key usage
- Rate limit per API key
- Hash API keys in storage (like passwords)
- Display key only once at creation time
- Prefix keys for identification: sk_live_, pk_test_ (like Stripe)
```

---

## Testing Authorization

```
Test cases for every endpoint:
1. Unauthenticated user → 401
2. Authenticated user without required role → 403
3. Authenticated user with correct role → 200
4. User accessing another user's resource → 403
5. User modifying their own role → 403
6. Deleted/disabled user → 401 or 403
7. Expired session/token → 401
8. Cross-tenant access → 403
9. Privilege escalation attempt → 403 + security alert

Automated testing:
- Write authorization tests for EVERY endpoint
- Test both positive (allowed) and negative (denied) cases
- Use test matrix: roles × endpoints × actions × resource ownership
- Run authorization tests in CI/CD pipeline
```

---

## References

- OWASP Authorization Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html
- OWASP Top 10 A01:2021 Broken Access Control: https://owasp.org/Top10/A01_2021-Broken_Access_Control/
- NIST RBAC: https://csrc.nist.gov/projects/role-based-access-control
