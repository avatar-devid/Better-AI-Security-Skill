# Security Skill — Root Router

## Purpose

This skill ensures applications are secure against common and advanced vulnerabilities.
It uses hierarchical loading — read ONLY what the task requires.

## Skip Rule

IF the task has NO relation to any keyword below → **STOP. Do not load any module.**

## Decision Tree

Evaluate the task. For EACH matching condition, LOAD the corresponding file.
Multiple files may be loaded if the task spans multiple domains.

```
IF task contains [HTML, CSS, JavaScript, Frontend, Form, Search, Rich Text, Markdown, Template, Renderer, Browser, SPA, SSR, DOM]
    LOAD Security_Web.md

IF task contains [API, REST, GraphQL, gRPC, WebSocket, Endpoint, Route, Controller, Middleware, CORS, Webhook]
    LOAD Security_API.md

IF task contains [Database, SQL, Query, ORM, Migration, Schema, Table, Model, Repository, Prisma, Sequelize, TypeORM, Hibernate, Entity Framework, MongoDB, Redis, Elasticsearch]
    LOAD Security_Database.md

IF task contains [Login, Register, Signup, Authentication, Authorization, Password, Credential, Identity, User Account, SSO]
    LOAD Security_Auth.md

IF task contains [Session, Cookie, Token Refresh, Remember Me, Logout, Idle Timeout]
    LOAD Security_Session.md

IF task contains [Upload, File, Image, Document, Attachment, Media, Blob, S3, Storage]
    LOAD Security_FileUpload.md

IF task contains [Encrypt, Decrypt, Hash, Sign, Verify, Certificate, Key, TLS, SSL, AES, RSA, HMAC, PBKDF2, bcrypt, argon2]
    LOAD Security_Crypto.md

IF task contains [Electron, WPF, WinForms, Tauri, Desktop App, Native App, .NET Desktop, MAUI, Qt, GTK, JavaFX, Swing]
    LOAD Security_Desktop.md

IF task contains [Android, iOS, Mobile, Flutter, React Native, Expo, Kotlin, Swift, Capacitor, Cordova, Xamarin, MAUI Mobile]
    LOAD Security_Mobile.md

IF task contains [Payment, Checkout, Stripe, PayPal, Invoice, Billing, Subscription, PCI, Credit Card, Transaction]
    LOAD Security_Payment.md

IF task contains [Deploy, Docker, Kubernetes, CI/CD, Server, Nginx, Apache, Cloud, AWS, GCP, Azure, Infrastructure, Firewall, DNS, CDN, Reverse Proxy, Load Balancer, Terraform, Ansible]
    LOAD Security_Infrastructure.md
```

## Cross-Cutting Concerns

After loading domain-specific modules, also evaluate:

```
IF task involves external user input of any kind
    ALSO LOAD modules/SSRF.md (if server-side requests exist)
    ALSO LOAD modules/IDOR.md (if object access by ID exists)
    ALSO LOAD modules/RateLimit.md (if public endpoints exist)

IF task involves any data persistence or logging
    ALSO LOAD modules/Logging.md

IF task involves secrets, API keys, or credentials
    ALSO LOAD modules/SecretManagement.md
```

## File Map

| Domain | Router File | Modules |
|--------|------------|---------|
| Web | Security_Web.md | XSS, CSRF, CSP, Cookie |
| API | Security_API.md | API_REST, API_GraphQL, API_gRPC, API_WebSocket |
| Database | Security_Database.md | SQL_Security, ORM_Security, NoSQL_Security, Migration_Security |
| Auth | Security_Auth.md | JWT, OAuth, Password, MFA, RBAC |
| Session | Security_Session.md | (self-contained + links Cookie) |
| File Upload | Security_FileUpload.md | FileUpload_Validation, FileUpload_Storage |
| Crypto | Security_Crypto.md | Crypto_Symmetric, Crypto_Asymmetric, Crypto_Hashing |
| Desktop | Security_Desktop.md | Desktop_Electron, Desktop_DotNet, Desktop_Tauri |
| Mobile | Security_Mobile.md | Mobile_Android, Mobile_iOS, Mobile_Flutter, Mobile_ReactNative |
| Payment | Security_Payment.md | (self-contained) |
| Infrastructure | Security_Infrastructure.md | (self-contained) |
| General | (loaded via cross-cutting) | SSRF, RCE, PathTraversal, IDOR, RateLimit, Logging, SecretManagement, OWASP |
