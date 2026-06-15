# ORM Security — Deep Module

## Threat Description

ORMs (Object-Relational Mappers) abstract SQL but do NOT automatically prevent all injection. Misuse of ORM features — raw queries, dynamic finders, unsafe operators — can introduce SQL injection and mass assignment vulnerabilities.

---

## ORM-Specific Vulnerabilities

### Raw Queries in ORMs

```
RULE: Raw queries inside an ORM are just as dangerous as direct SQL.

UNSAFE examples:

Sequelize:
  sequelize.query(`SELECT * FROM users WHERE name = '${name}'`)  // ✗ INJECTABLE

Prisma:
  prisma.$queryRawUnsafe(`SELECT * FROM users WHERE name = '${name}'`)  // ✗ INJECTABLE

TypeORM:
  repository.query(`SELECT * FROM users WHERE name = '${name}'`)  // ✗ INJECTABLE

Django:
  User.objects.raw(f"SELECT * FROM users WHERE name = '{name}'")  // ✗ INJECTABLE

ActiveRecord:
  User.where("name = '#{name}'")  // ✗ INJECTABLE

Eloquent:
  DB::select("SELECT * FROM users WHERE name = '{$name}'")  // ✗ INJECTABLE

Hibernate:
  session.createQuery("FROM User WHERE name = '" + name + "'")  // ✗ INJECTABLE

Entity Framework:
  context.Users.FromSqlRaw($"SELECT * FROM Users WHERE Name = '{name}'")  // ✗ INJECTABLE

SAFE alternatives:

Sequelize:
  sequelize.query('SELECT * FROM users WHERE name = ?', { replacements: [name] })

Prisma:
  prisma.$queryRaw`SELECT * FROM users WHERE name = ${name}`  // Tagged template = safe

TypeORM:
  repository.query('SELECT * FROM users WHERE name = $1', [name])

Django:
  User.objects.raw('SELECT * FROM users WHERE name = %s', [name])

ActiveRecord:
  User.where('name = ?', name)

Eloquent:
  DB::select('SELECT * FROM users WHERE name = ?', [$name])

Hibernate:
  session.createQuery("FROM User WHERE name = :name").setParameter("name", name)

Entity Framework:
  context.Users.FromSqlInterpolated($"SELECT * FROM Users WHERE Name = {name}")
```

### Mass Assignment

```
THREAT: Attacker sends extra fields in request body that map to model properties.

Example:
  POST /api/users { "name": "John", "email": "john@x.com", "role": "admin" }
  If ORM blindly assigns all fields → attacker sets their own role.

Prevention by ORM:

Sequelize:
  User.create(req.body)              // ✗ UNSAFE
  User.create({                       // ✓ SAFE — whitelist fields
    name: req.body.name,
    email: req.body.email
  })

Prisma:
  // Prisma requires explicit field selection — safe by default
  prisma.user.create({ data: { name, email } })

Django:
  # Use serializers with explicit fields
  class UserSerializer(serializers.ModelSerializer):
      class Meta:
          fields = ['name', 'email']  # Whitelist

ActiveRecord:
  # Use strong parameters
  params.require(:user).permit(:name, :email)

Eloquent:
  # Use $fillable whitelist
  protected $fillable = ['name', 'email'];
  # Or $guarded blacklist (whitelist preferred)
  protected $guarded = ['role', 'is_admin'];

Entity Framework:
  // Use DTOs/ViewModels — never bind directly to entity
  [Bind("Name,Email")] on action parameter

RULE: ALWAYS whitelist allowed fields. Never pass raw request body to ORM create/update.
```

### Unsafe Finders and Operators

```
Some ORM query methods accept operators that can be abused:

Sequelize operators injection:
  // If user passes { [Op.gt]: 0 } as a value
  User.findAll({ where: { age: req.query.age } })
  // Could become: WHERE age > 0 (unintended query)

  Prevention: Validate input types. Use operatorsAliases: false (Sequelize v5+)

MongoDB / Mongoose operator injection:
  // User sends: { "$gt": "" } instead of a string
  User.find({ password: req.body.password })
  // Becomes: password > "" → returns all users

  Prevention: Validate types, use mongo-sanitize, reject objects in string fields

Django:
  User.objects.filter(**request.GET.dict())  // ✗ UNSAFE — arbitrary lookups
  # Attacker: ?password__startswith=a → boolean-based extraction

  Prevention: Whitelist allowed filter fields and lookups
```

### N+1 Queries and DoS

```
THREAT: Uncontrolled eager/lazy loading can cause resource exhaustion.

Attack: Request deeply nested relationships → ORM generates thousands of queries.

Prevention:
- Set maximum query depth for nested relationships
- Use eager loading with explicit limits
- Set query timeout at database level
- Monitor and alert on slow queries
- Paginate all list queries with server-enforced maximum
- Use DataLoader pattern for GraphQL (batches queries)
```

---

## ORM Security Checklist

```
1. ✓ Never concatenate strings in raw queries — use parameterized alternatives
2. ✓ Whitelist fields for create/update (mass assignment protection)
3. ✓ Validate input types before passing to ORM (string, number, boolean)
4. ✓ Disable dangerous operators or aliases
5. ✓ Whitelist allowed filter fields for dynamic queries
6. ✓ Set query timeout
7. ✓ Use pagination with enforced maximum page size
8. ✓ Limit relationship depth for eager loading
9. ✓ Enable query logging for audit
10. ✓ Keep ORM version updated (security patches)
11. ✓ Use transactions for multi-step operations
12. ✓ Implement row-level security or tenant scoping
```

---

## Safe ORM Patterns

```
Pattern 1: Repository/Service Layer
- Controller validates input (schema validation)
- Service layer applies business logic
- Repository layer interacts with ORM
- ORM never directly receives user input

Pattern 2: DTOs (Data Transfer Objects)
- Define explicit input/output shapes
- Map DTO → Entity (whitelist fields)
- Never expose Entity directly to API response

Pattern 3: Query Builders with Validation
- Build query programmatically
- Validate each filter/sort parameter against whitelist
- Use typed parameters (parseInt, parseFloat, toString)
```

---

## References

- OWASP ORM Injection: https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/07-Input_Validation_Testing/05.7-Testing_for_ORM_Injection
- Sequelize Security: https://sequelize.org/docs/v6/core-concepts/raw-queries/#replacements
- Prisma Security: https://www.prisma.io/docs/concepts/components/prisma-client/raw-database-access
