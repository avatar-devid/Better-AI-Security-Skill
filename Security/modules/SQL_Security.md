# SQL Injection Security — Deep Module

## Threat Description

SQL Injection occurs when untrusted data is sent to a SQL interpreter as part of a command or query. The attacker's hostile data tricks the interpreter into executing unintended commands or accessing unauthorized data.

**Impact**: Full database compromise, data theft, data modification, data deletion, authentication bypass, OS command execution (in severe cases).

**CWE**: CWE-89 (SQL Injection)

---

## SQL Injection Types

### Classic SQL Injection

```
Attack: Injecting SQL through user input that modifies query logic.

Vulnerable code:
  query = "SELECT * FROM users WHERE username = '" + username + "' AND password = '" + password + "'"

Attack input:
  username: admin' --
  password: anything

Resulting query:
  SELECT * FROM users WHERE username = 'admin' --' AND password = 'anything'
  (Comment -- removes password check → auth bypass)

Other payloads:
  ' OR '1'='1                    → Always true condition
  ' UNION SELECT * FROM admins-- → Data from another table
  '; DROP TABLE users--          → Destructive query
  ' OR 1=1; UPDATE users SET role='admin' WHERE username='attacker'-- → Privilege escalation
```

### Blind SQL Injection

```
Attack: No direct output, but attacker infers data from application behavior.

Boolean-based:
  /user?id=1 AND 1=1    → Normal response (true)
  /user?id=1 AND 1=2    → Different response (false)
  /user?id=1 AND SUBSTRING(username,1,1)='a'  → Character-by-character extraction

Time-based:
  /user?id=1; WAITFOR DELAY '00:00:05'--     → MSSQL: 5-second delay = injectable
  /user?id=1 AND SLEEP(5)--                   → MySQL: 5-second delay
  /user?id=1; SELECT pg_sleep(5)--            → PostgreSQL: 5-second delay

These are slower but just as dangerous — full data extraction is possible.
```

### Second-Order SQL Injection

```
Attack: Malicious data is stored safely, then used unsafely in a later query.

Flow:
1. User registers with username: admin'--
2. Application safely stores it using parameterized query ✓
3. Later, application reads username from database and uses it in a new query:
   query = "SELECT * FROM orders WHERE username = '" + stored_username + "'"
4. SQL injection occurs on the second query

Prevention: Parameterize ALL queries, including those using data from the database.
```

---

## Prevention (Definitive)

### 1. Parameterized Queries / Prepared Statements

```
ABSOLUTE RULE: Use parameterized queries for ALL database interactions.

Node.js (pg):
  await pool.query('SELECT * FROM users WHERE id = $1 AND status = $2', [userId, status]);

Node.js (mysql2):
  await connection.execute('SELECT * FROM users WHERE id = ? AND status = ?', [userId, status]);

Python (psycopg2):
  cursor.execute("SELECT * FROM users WHERE id = %s AND status = %s", (user_id, status))

Java (JDBC):
  PreparedStatement ps = conn.prepareStatement("SELECT * FROM users WHERE id = ? AND status = ?");
  ps.setInt(1, userId);
  ps.setString(2, status);

C# (ADO.NET):
  cmd.CommandText = "SELECT * FROM users WHERE id = @id AND status = @status";
  cmd.Parameters.AddWithValue("@id", userId);
  cmd.Parameters.AddWithValue("@status", status);

Go (database/sql):
  db.Query("SELECT * FROM users WHERE id = $1 AND status = $2", userId, status)

PHP (PDO):
  $stmt = $pdo->prepare('SELECT * FROM users WHERE id = :id AND status = :status');
  $stmt->execute(['id' => $userId, 'status' => $status]);

Ruby (ActiveRecord):
  User.where("id = ? AND status = ?", user_id, status)
```

### 2. Dynamic Query Elements (Cannot Be Parameterized)

```
RULE: Column names, table names, ORDER BY, and operators CANNOT be parameterized.
      Use strict whitelists.

Column whitelist:
const ALLOWED_COLUMNS = ['name', 'email', 'created_at', 'status'];
const column = ALLOWED_COLUMNS.includes(input) ? input : 'created_at';
const query = `SELECT * FROM users ORDER BY ${column}`;  // Safe: from whitelist

Order direction:
const direction = input.toUpperCase() === 'DESC' ? 'DESC' : 'ASC';  // Binary choice

Table name:
const TABLE_MAP = { 'users': 'users', 'products': 'products' };
const table = TABLE_MAP[input];
if (!table) throw new Error('Invalid table');

Operator:
const OP_MAP = { 'eq': '=', 'gt': '>', 'lt': '<', 'gte': '>=', 'lte': '<=' };
const op = OP_MAP[input];
if (!op) throw new Error('Invalid operator');

NEVER:
- Concatenate user input as column/table names without whitelist
- Use user input in ORDER BY without whitelist
- Allow arbitrary SQL fragments from user
```

### 3. Stored Procedures

```
Stored procedures CAN be safe IF parameterized internally.

SAFE:
  CREATE PROCEDURE GetUser(@UserId INT)
  AS
    SELECT * FROM users WHERE id = @UserId;

UNSAFE (still vulnerable):
  CREATE PROCEDURE SearchUsers(@SearchTerm NVARCHAR(100))
  AS
    EXEC('SELECT * FROM users WHERE name LIKE ''%' + @SearchTerm + '%''');

RULE: Dynamic SQL inside stored procedures MUST also use parameters.
      Use sp_executesql (MSSQL) or EXECUTE ... USING (PostgreSQL) with parameters.
```

### 4. LIKE Queries

```
RULE: Escape wildcard characters in LIKE patterns.

Wildcards: % (any string), _ (any character), [ ] (character set, MSSQL)

Safe LIKE query:
  // Escape wildcards in user input
  const escaped = userInput.replace(/[%_\\]/g, '\\$&');
  await pool.query("SELECT * FROM products WHERE name LIKE '%' || $1 || '%'", [escaped]);

  // Or use parameterized LIKE:
  await pool.query("SELECT * FROM products WHERE name LIKE $1", [`%${escaped}%`]);

Without escaping wildcards, user can input:
  % → match everything (information disclosure)
  %admin% → enumerate admin-related records
```

### 5. IN Clauses

```
RULE: Parameterize IN clauses properly.

UNSAFE:
  query(`SELECT * FROM users WHERE id IN (${ids.join(',')})`)

SAFE (PostgreSQL):
  query('SELECT * FROM users WHERE id = ANY($1::int[])', [ids])

SAFE (MySQL — generate placeholders):
  const placeholders = ids.map(() => '?').join(',');
  query(`SELECT * FROM users WHERE id IN (${placeholders})`, ids);

SAFE (using query builder):
  knex('users').whereIn('id', ids);
```

---

## Database-Specific Risks

```
PostgreSQL:
- COPY command (file read/write if superuser)
- lo_import/lo_export (large object file access)
- pg_read_file() (file system access)
- dblink (connect to other databases)

MySQL:
- LOAD_FILE() (file read)
- INTO OUTFILE / INTO DUMPFILE (file write)
- User-defined functions (code execution)

MSSQL:
- xp_cmdshell (OS command execution)
- OPENROWSET (data from external sources)
- sp_OACreate (COM object creation)
- Linked servers (lateral movement)

SQLite:
- ATTACH DATABASE (create new database file)
- load_extension() (load shared library)

RULE: Disable dangerous functions and features in production.
RULE: Application database user should NEVER have SUPERUSER/DBA privileges.
```

---

## Testing for SQL Injection

```
Manual testing:
- Add single quote ' to inputs → watch for SQL errors
- Add -- or # → check if comment causes different behavior
- Boolean test: AND 1=1 vs AND 1=2
- Time test: AND SLEEP(5) or WAITFOR DELAY '00:00:05'
- UNION test: ORDER BY 1,2,3... to find column count
- String concatenation: 'abc' || 'def' or 'abc' + 'def'

Automated tools:
- sqlmap (comprehensive SQL injection tool)
- Burp Suite SQLi scanner
- OWASP ZAP
- jSQL Injection
- Havij

Static analysis:
- Grep for string concatenation in SQL context
- semgrep rules for SQL injection patterns
- SonarQube SQL injection rules
- ESLint plugin: eslint-plugin-security
```

---

## References

- OWASP SQL Injection: https://owasp.org/www-community/attacks/SQL_Injection
- OWASP SQL Injection Prevention Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html
- CWE-89: https://cwe.mitre.org/data/definitions/89.html
