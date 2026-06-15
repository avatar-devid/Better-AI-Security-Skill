# IDOR (Insecure Direct Object Reference) — Deep Module

## Threat Description

IDOR occurs when an application exposes internal object references (IDs) without proper authorization checks, allowing attackers to access other users' resources by modifying the reference.

**CWE**: CWE-639 (Authorization Bypass Through User-Controlled Key)

---

## Attack Examples

```
Horizontal IDOR (accessing another user's data):
  GET /api/users/123/profile     → My profile
  GET /api/users/124/profile     → Someone else's profile!
  GET /api/orders/456            → My order
  GET /api/orders/457            → Someone else's order!

Vertical IDOR (accessing higher-privilege resources):
  GET /api/admin/users           → Admin panel accessed by regular user

Parameter-based:
  GET /api/invoices?userId=123   → Changing userId
  POST /api/transfer { "fromAccount": "123", "toAccount": "456" }  → Changing fromAccount
  DELETE /api/files/789          → Deleting someone else's file
```

## Prevention

```
1. ALWAYS check resource ownership server-side:
   const order = await Order.findById(orderId);
   if (order.userId !== req.user.id) return res.status(403).send('Forbidden');

2. Use opaque, non-sequential IDs (UUIDs instead of integers):
   ✗ /api/users/1, /api/users/2  (enumerable)
   ✓ /api/users/a1b2c3d4-e5f6-7890 (not enumerable)

3. Filter queries by the authenticated user:
   // Instead of: Order.findById(id)
   // Use: Order.findOne({ id, userId: req.user.id })

4. Use indirect references (map user-facing ID to internal ID):
   User sees: "order-A" → Server maps to internal ID 12345

5. Test for IDOR on every endpoint:
   - Try accessing resources with IDs belonging to other users
   - Try modifying IDs in request body, URL, and headers
   - Automate with different user sessions

6. Log and alert on IDOR attempts:
   - User requesting resources they don't own = suspicious
   - Sequential ID scanning = likely attack
```

---

## References

- OWASP IDOR: https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/05-Authorization_Testing/04-Testing_for_Insecure_Direct_Object_References
- CWE-639: https://cwe.mitre.org/data/definitions/639.html
