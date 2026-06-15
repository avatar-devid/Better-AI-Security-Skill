# GraphQL Security — Deep Module

## Scope

GraphQL-specific security: query depth, introspection, batching attacks, authorization, and resource exhaustion.

---

## GraphQL-Specific Vulnerabilities

### 1. Query Depth Attack

```
THREAT: Deeply nested queries exhaust server resources.

Attack:
  query {
    user(id: 1) {
      posts {
        comments {
          author {
            posts {
              comments {
                author { ... }  # Infinite nesting
              }
            }
          }
        }
      }
    }
  }

Prevention:
- Set maximum query depth (6-10 levels recommended)
- Use graphql-depth-limit (Node.js) or equivalent
- Return 400 error for queries exceeding depth limit

// Apollo Server
const depthLimit = require('graphql-depth-limit');
const server = new ApolloServer({
  validationRules: [depthLimit(10)]
});
```

### 2. Query Complexity / Cost Analysis

```
THREAT: Complex queries with many fields consume excessive resources.

Prevention:
- Assign cost to each field/resolver
- Calculate total query cost before execution
- Reject queries exceeding cost limit

// graphql-query-complexity
const { createComplexityRule } = require('graphql-query-complexity');
const rule = createComplexityRule({
  maximumComplexity: 1000,
  estimators: [
    fieldExtensionsEstimator(),
    simpleEstimator({ defaultComplexity: 1 })
  ],
  onComplete: (complexity) => console.log('Query complexity:', complexity)
});

Cost assignment:
- Scalar field: 1
- Object field: 2
- List field: complexity × estimated_count
- Connection field: complexity × first/last argument
- Mutation: higher cost than query
```

### 3. Batching Attack

```
THREAT: Single request contains multiple queries or aliases for brute force.

Attack — alias-based:
  query {
    login1: login(email: "admin@x.com", password: "pass1") { token }
    login2: login(email: "admin@x.com", password: "pass2") { token }
    login3: login(email: "admin@x.com", password: "pass3") { token }
    ... # 1000 login attempts in one request
  }

Attack — array-based:
  [
    { "query": "mutation { login(email: \"admin\", password: \"pass1\") { token } }" },
    { "query": "mutation { login(email: \"admin\", password: \"pass2\") { token } }" },
    ...
  ]

Prevention:
- Limit number of aliases per query
- Limit array batch size (max 5-10 queries per batch)
- Rate limit by operation count, not just request count
- Disable query batching if not needed
- Rate limit specific operations (login, register) individually
```

### 4. Introspection

```
RULE: Disable introspection in production.

Introspection reveals:
- All types, fields, and arguments
- All queries and mutations available
- Internal naming conventions
- Hidden admin endpoints

// Apollo Server
const server = new ApolloServer({
  introspection: process.env.NODE_ENV !== 'production'
});

// GraphQL Yoga
const yoga = createYoga({
  schema,
  graphiql: process.env.NODE_ENV !== 'production'
});

RULE: If introspection must be available in production (developer portal),
      put it behind authentication and restrict to authorized developers.
```

### 5. Authorization

```
RULE: Authorize at the resolver level, not at the schema level.

// WRONG — checking auth only at query level
const resolvers = {
  Query: {
    users: requireAuth(async () => { ... })  // Auth checked here
  },
  User: {
    email: (user) => user.email  // No auth check — exposes email to anyone
  }
};

// RIGHT — field-level authorization
const resolvers = {
  User: {
    email: (user, args, context) => {
      if (context.user.id !== user.id && !context.user.isAdmin) return null;
      return user.email;
    },
    role: (user, args, context) => {
      if (!context.user.isAdmin) return null;
      return user.role;
    }
  }
};

Consider using:
- graphql-shield (permission layer)
- Custom directives (@auth, @hasRole)
- DataLoader with per-user scoping
```

### 6. Injection via Arguments

```
RULE: Validate and sanitize all GraphQL arguments.

GraphQL typing provides basic validation but is NOT sufficient:
- String type accepts any string (including SQL injection payloads)
- Int type prevents strings but allows negative numbers
- Custom scalars can enforce format (Email, URL, DateTime)

Use custom scalars for validation:
  scalar Email    # Validates email format
  scalar URL      # Validates URL format
  scalar DateTime # Validates ISO 8601
  scalar UUID     # Validates UUID format

Always parameterize database queries in resolvers (same rules as SQL_Security.md).
```

### 7. N+1 Query Problem

```
THREAT: Each resolver makes its own database query → exponential queries.

query {
  users(first: 100) {     # 1 query
    posts {                 # 100 queries (one per user)
      comments {            # N queries (one per post)
        author { ... }      # M queries (one per comment)
      }
    }
  }
}
# Could result in thousands of database queries!

Prevention:
- Use DataLoader for batching and caching (MANDATORY)
- Limit list sizes (max first/last arguments)
- Monitor resolver execution count
- Set query timeout

// DataLoader
const userLoader = new DataLoader(async (ids) => {
  const users = await User.findByIds(ids);
  return ids.map(id => users.find(u => u.id === id));
});
```

### 8. Persisted Queries

```
RECOMMENDED: Use persisted/whitelisted queries in production.

Approach:
1. During build: extract all queries from client code
2. Generate query hash → query mapping
3. Client sends only query hash (not full query text)
4. Server looks up query by hash

Benefits:
- Prevents arbitrary queries
- Reduces request size
- Eliminates query complexity attacks
- Faster query validation

// Apollo — Automatic Persisted Queries (APQ)
// Client sends hash, server caches query text on first request
const link = createPersistedQueryLink().concat(httpLink);
```

---

## GraphQL Security Checklist

```
1. ✓ Disable introspection in production
2. ✓ Set maximum query depth (6-10)
3. ✓ Implement query cost analysis with limits
4. ✓ Limit batching (aliases and array batches)
5. ✓ Authorize at resolver level (field-level auth)
6. ✓ Use DataLoader for N+1 prevention
7. ✓ Validate all arguments (custom scalars)
8. ✓ Rate limit by operation count
9. ✓ Set query timeout
10. ✓ Use persisted queries in production
11. ✓ Paginate all list fields (enforce max page size)
12. ✓ Log all mutations with user context
```

---

## References

- OWASP GraphQL Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/GraphQL_Cheat_Sheet.html
- Apollo Security: https://www.apollographql.com/docs/apollo-server/security/
