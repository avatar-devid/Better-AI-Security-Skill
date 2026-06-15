# Migration Security — Deep Module

## Threat Description

Database migrations modify schema and data. Insecure migrations can introduce vulnerabilities, data loss, or expose sensitive information.

---

## Migration Security Rules

### 1. Migration File Safety

```
RULE: Treat migration files as security-critical code. Review them carefully.

Checklist:
- Never include sensitive data (passwords, API keys, PII) in migration files
- Never use dynamic SQL with user input in migrations
- Use parameterized queries even in seed data
- Review all raw SQL in migrations
- Don't include production data in migration seeds
- Separate seed data from schema migrations
```

### 2. Credential Management

```
RULE: Use separate database credentials for migrations.

- Migration user: has ALTER, CREATE, DROP, INSERT, UPDATE, DELETE permissions
- Application user: has only SELECT, INSERT, UPDATE, DELETE on application tables
- Migration credentials: used ONLY in CI/CD pipeline, NOT in application code
- Rotate migration credentials after team member departure

NEVER:
- Run migrations with root/superuser credentials in production
- Store migration credentials in source code
- Use the same credentials for migrations and application runtime
```

### 3. Destructive Operations

```
RULE: Guard destructive migrations carefully.

Dangerous operations:
- DROP TABLE / DROP COLUMN
- TRUNCATE TABLE
- ALTER TABLE ... DROP CONSTRAINT
- DELETE FROM (without WHERE — mass delete)
- ALTER TYPE (enum changes that remove values)

Safety measures:
- Require explicit confirmation for destructive migrations
- Create backup before destructive migration
- Add reversible (rollback) migration for every destructive operation
- Test migration on staging with production-like data first
- Use soft deletes before hard deletes (rename → drop after grace period)

Safe column removal pattern:
  Step 1: Deploy code that stops reading/writing the column
  Step 2: Run migration to drop the column
  Step 3: Verify application works without the column
  (Never drop column while code still references it)
```

### 4. Data Migration Security

```
RULE: Data migrations that transform sensitive data need extra care.

- Encrypt sensitive fields during migration (if adding encryption)
- Hash passwords during migration (if migrating from plaintext — emergency fix)
- Log migration progress (but NOT the data itself)
- Handle migration failure gracefully (partial migration state)
- Use transactions for data migrations (rollback on failure)
- Set batch size for large data migrations (avoid memory exhaustion)
- Validate data after migration (row counts, checksums)
```

### 5. Default Values and Constraints

```
RULE: Security-relevant defaults must be secure by default.

Good defaults in migrations:
- is_admin: false (not true)
- is_active: false (until email verified)
- is_verified: false
- role: 'user' (not 'admin')
- visibility: 'private' (not 'public')
- created_at: NOW() (audit trail)
- login_attempts: 0

Constraints:
- NOT NULL on required fields (prevent null bypass)
- UNIQUE on email, username (prevent duplicates)
- CHECK constraints on enum-like values
- Foreign key constraints (referential integrity)
- Length limits (VARCHAR(255), not TEXT for short fields)
```

### 6. Index Security

```
Add indexes for security-related queries:
- Unique index on email (prevent duplicate accounts)
- Index on login_attempts + locked_until (lockout queries)
- Index on session_token (session lookup performance)
- Index on reset_token (password reset lookup)
- Index on audit fields (created_at, user_id for audit queries)

Without proper indexes, security queries may be slow → potential DoS.
```

### 7. Migration Rollback

```
RULE: Every migration should have a rollback plan.

- Write down migration (up) and rollback (down) for every change
- Test rollback in staging before production deployment
- For irreversible migrations, document the manual recovery procedure
- Keep database backups before migration (point-in-time recovery)
- Use migration versioning (track which migrations have been applied)

Irreversible migrations (document carefully):
- Data encryption (can't reverse without key)
- Password hashing (can't reverse — by design)
- Data deletion (need backup to reverse)
- Column type changes with data loss
```

### 8. Migration Audit

```
RULE: Log all migration executions.

Log:
- Migration name/version
- Timestamp
- Who triggered it (CI/CD system, manual)
- Duration
- Success/failure
- Database user used
- Environment (staging/production)

Monitor:
- Unexpected migrations (not from CI/CD)
- Failed migrations (may leave database in inconsistent state)
- Migrations run outside maintenance window
- Long-running migrations (may cause downtime)
```

---

## References

- OWASP Database Security: https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/07-Input_Validation_Testing/05-Testing_for_SQL_Injection
