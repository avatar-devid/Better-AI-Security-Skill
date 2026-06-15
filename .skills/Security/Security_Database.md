# Security — Database

## Scope

This module covers security for all data persistence layers: relational databases (SQL), document stores (NoSQL), in-memory caches, and schema migrations.

## Sub-Router

```
IF task contains [SQL, PostgreSQL, MySQL, MariaDB, SQLite, MSSQL, Oracle, Raw Query, Prepared Statement, Stored Procedure]
    LOAD modules/SQL_Security.md

IF task contains [ORM, Prisma, Sequelize, TypeORM, Hibernate, Entity Framework, Django ORM, ActiveRecord, Eloquent, SQLAlchemy, Drizzle, Knex]
    LOAD modules/ORM_Security.md

IF task contains [MongoDB, Redis, Elasticsearch, DynamoDB, Cassandra, Firebase Firestore, CouchDB, Neo4j, NoSQL]
    LOAD modules/NoSQL_Security.md

IF task contains [Migration, Schema Change, Alter Table, Add Column, Seed, Rollback]
    LOAD modules/Migration_Security.md
```

## Universal Database Security Rules

These rules apply to ALL database types:

### 1. Injection Prevention

```
ABSOLUTE RULE: Never construct queries by concatenating user input.

✗ DANGEROUS:
  query("SELECT * FROM users WHERE id = " + userId)
  query(`DELETE FROM posts WHERE id = ${postId}`)
  collection.find({ $where: "this.name == '" + name + "'" })

✓ SAFE:
  query("SELECT * FROM users WHERE id = $1", [userId])
  query("DELETE FROM posts WHERE id = ?", [postId])
  collection.find({ name: name })
```

### 2. Least Privilege Access

```
RULE: Application database user MUST have minimal permissions.

- Application user: SELECT, INSERT, UPDATE, DELETE on application tables only
- Migration user: ALTER, CREATE, DROP (separate credentials, CI/CD only)
- Admin user: ALL PRIVILEGES (manual access only, never in application code)
- Read-only replicas: SELECT only

NEVER:
- Use root/admin credentials in application code
- Grant SUPERUSER or DBA role to application user
- Share credentials between environments
- Use same credentials for all microservices
```

### 3. Connection Security

```
RULE: All database connections MUST be encrypted in transit.

- Use TLS/SSL for all connections (sslmode=require or verify-full)
- Verify server certificate (do NOT set sslmode=disable or trust)
- Use connection pooling with proper idle timeout
- Close connections after use (use connection pool manager)
- Set connection timeout (5-10 seconds)
- Set query timeout (30 seconds default, adjust per query)
```

### 4. Data at Rest Encryption

```
RULE: Sensitive data MUST be encrypted at rest.

Encrypt at database level:
- Transparent Data Encryption (TDE) for full-disk
- Column-level encryption for specific sensitive fields

Encrypt at application level (preferred for sensitive fields):
- PII (names, addresses, phone numbers)
- Financial data (account numbers)
- Health records
- Authentication secrets (tokens, API keys)

Use AES-256-GCM for application-level encryption.
Store encryption keys in a key management service (KMS), NOT in the database.
```

### 5. Backup Security

```
RULE: Database backups MUST be encrypted and access-controlled.

- Encrypt backups with separate key from database encryption
- Store backups in different location than primary database
- Test backup restoration regularly
- Set retention policy (regulatory compliance)
- Log all backup access
- Never store backups in publicly accessible storage
```

### 6. Query Safety

```
RULE: Always parameterize dynamic parts of queries.

Dynamic column names (cannot be parameterized):
- Use strict whitelist: if column not in allowedColumns → reject
- Never allow user input directly as column name

Dynamic ORDER BY:
- Whitelist allowed columns
- Whitelist allowed directions (ASC, DESC only)
- Map user input to enum: sort=name → ORDER BY name ASC

Dynamic table names:
- NEVER allow user-controlled table names
- Use enum mapping if multi-table access is needed

LIMIT and OFFSET:
- Parse as integer
- Enforce maximum (e.g., LIMIT max 100)
- Validate non-negative
```

### 7. Sensitive Data Handling

```
RULE: Minimize sensitive data in database.

- Hash passwords (bcrypt, argon2) — never store plaintext
- Mask data in logs (show last 4 digits of card, email partial)
- Implement data retention policies (auto-delete old records)
- Use soft delete with scheduled hard delete for compliance
- Separate PII into dedicated table with restricted access
- Audit all access to sensitive tables
```

### 8. Database-Level Access Control

```
RULE: Implement Row-Level Security (RLS) where supported.

PostgreSQL RLS example:
- CREATE POLICY tenant_isolation ON orders
  USING (tenant_id = current_setting('app.tenant_id')::uuid);

Application-level equivalent:
- ALWAYS filter by tenant_id / user_id in WHERE clause
- Use global query scopes (ORM-level automatic filtering)
- Never rely solely on API authorization — defense in depth
```

### 9. Transaction Safety

```
RULE: Use transactions for multi-step operations.

- Wrap related writes in a single transaction
- Set appropriate isolation level (READ COMMITTED minimum)
- Handle deadlocks with retry logic
- Set transaction timeout
- Avoid long-running transactions (they hold locks)
- Use optimistic locking for concurrent updates (version column)
```

### 10. Monitoring & Alerting

```
RULE: Monitor database for security anomalies.

Monitor:
- Failed authentication attempts
- Unusual query patterns (mass SELECT, bulk DELETE)
- Slow queries (potential DoS)
- Schema changes outside migration windows
- Connection count spikes
- Privilege escalation attempts

Enable:
- Query logging (PostgreSQL: log_statement = 'all' for audit)
- Slow query log
- Connection audit log
```
