# 🛡️ AI Security Skill

> A hierarchical, compiler-like security skill system for AI coding assistants.
> Load only what you need. Save over 90% of context tokens.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Files](https://img.shields.io/badge/Modules-49_files-blue.svg)](#file-structure)
[![Platforms](https://img.shields.io/badge/Platforms-Web%20%7C%20Mobile%20%7C%20Desktop-green.svg)](#coverage)

---

# What is AI Security Skill?

**AI Security Skill** is a modular security framework that teaches AI coding assistants (Cursor, Claude Code, Copilot, Gemini, and others) to **automatically apply security best practices** while generating code.

Instead of relying on a single monolithic document (~50,000 tokens), this project uses a **hierarchical loading architecture**, allowing the AI to load only the modules relevant to the current task.

```text
Task: "Build a REST API"

❌ Monolithic
Read ~50,000 tokens (every security rule)

✅ Hierarchical
Read ~3,000 tokens (API + REST modules only)

Context Saving: 94%
```

---

# How It Works

The system behaves similarly to a compiler that loads modules on demand.

```text
Incoming Task
      │
      ▼
Security.md (Root Router — ~300 tokens)
      │
      ├── Contains keyword "API"?
      │      └── LOAD Security_API.md
      │             └── Contains keyword "REST"?
      │                    └── LOAD modules/API_REST.md
      │
      ├── Contains keyword "Login"?
      │      └── LOAD Security_Auth.md
      │             └── Contains keyword "Password"?
      │                    └── LOAD modules/Password.md
      │
      └── No matching keyword?
             └── STOP
```

## Three-Layer Architecture

| Layer                  | Purpose                                              | Tokens     | Files |
| ---------------------- | ---------------------------------------------------- | ---------- | ----- |
| **L1 — Root Router**   | Decision tree only                                   | ~300       | 1     |
| **L2 — Domain Router** | Domain-specific routing                              | ~500–1500  | 11    |
| **L3 — Deep Modules**  | Complete security guidance, checklists, and examples | ~1500–5000 | 37    |

---

# Coverage

## Platforms

| Platform              | Domain Router              | Deep Modules                            |
| --------------------- | -------------------------- | --------------------------------------- |
| 🌐 **Web**            | Security_Web.md            | XSS, CSRF, CSP, Cookies                 |
| 🔌 **API**            | Security_API.md            | REST, GraphQL, gRPC, WebSocket          |
| 🗄️ **Database**      | Security_Database.md       | SQL Injection, ORM, NoSQL, Migration    |
| 🔐 **Authentication** | Security_Auth.md           | JWT, OAuth/OIDC, Passwords, MFA, RBAC   |
| 📱 **Mobile**         | Security_Mobile.md         | Android, iOS, Flutter, React Native     |
| 🖥️ **Desktop**       | Security_Desktop.md        | Electron, .NET/WPF, Tauri               |
| 💳 **Payment**        | Security_Payment.md        | PCI-DSS, Tokenization, Fraud Prevention |
| 🔒 **Cryptography**   | Security_Crypto.md         | AES, RSA, Ed25519, Hashing              |
| ☁️ **Infrastructure** | Security_Infrastructure.md | TLS, Docker, CI/CD, Cloud Security      |

## Security Coverage

```text
SQL Injection    ✅     XSS (Stored / Reflected / DOM)  ✅
CSRF             ✅     SSRF                             ✅
RCE              ✅     IDOR                             ✅
Path Traversal   ✅     Rate Limiting                    ✅
Secrets          ✅     Logging & Monitoring             ✅
OWASP Top 10     ✅     OWASP ASVS                       ✅
OWASP API Top 10 ✅     OWASP Mobile Top 10              ✅
```

---

# Quick Start

## 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/ai-security-skill.git
```

## 2. Configure Your AI Assistant

### Cursor

Create:

```text
.cursor/rules
```

```text
You have access to a hierarchical Security Skill system.

At the START of every task, read:
[PATH_TO]/Security.md

Follow the decision tree.
LOAD only matching files.
Apply every loaded security rule.
If nothing matches, STOP.
```

---

### Claude Code

Create:

```text
CLAUDE.md
```

```markdown
## Security Skill

Before implementing code, read:

[PATH_TO]/Security.md

Follow the decision tree.
Load only matching modules.
Apply every loaded rule.
```

---

### GitHub Copilot

Create:

```text
.github/copilot-instructions.md
```

```markdown
## Security Skill Protocol

Before implementing any feature:

Read:
[PATH_TO]/Security.md

Evaluate the decision tree.

Load every matching module.

Apply all loaded security rules.
```

---

### OpenCode

Create:

```text
.opencode.md
```

```markdown
## Security Skill

Read [PATH_TO]/Security.md at the beginning of every task.

Follow the decision tree.

Load only matching modules.

Apply all loaded security rules.
```

---

### Gemini / Pi

Create:

```text
GEMINI.md
```

```markdown
## Security Skill

This project uses a hierarchical security system located at:

[PATH_TO]/Security.md

Read it before every implementation task.

Follow every LOAD directive.

Apply every loaded security rule.
```

---

## 3. Done!

Your AI assistant will automatically read `Security.md`, identify the relevant modules, and apply security best practices for every coding task.

---

# File Structure

```text
Security/
│
├── Security.md                      # L1 Root Router
│
├── Security_Web.md
├── Security_API.md
├── Security_Database.md
├── Security_Auth.md
├── Security_Session.md
├── Security_FileUpload.md
├── Security_Crypto.md
├── Security_Desktop.md
├── Security_Mobile.md
├── Security_Payment.md
├── Security_Infrastructure.md
│
├── modules/
│   ├── XSS.md
│   ├── CSRF.md
│   ├── CSP.md
│   ├── Cookie.md
│   ├── SQL_Security.md
│   ├── ORM_Security.md
│   ├── NoSQL_Security.md
│   ├── Migration_Security.md
│   ├── JWT.md
│   ├── OAuth.md
│   ├── Password.md
│   ├── MFA.md
│   ├── RBAC.md
│   ├── API_REST.md
│   ├── API_GraphQL.md
│   ├── API_gRPC.md
│   ├── API_WebSocket.md
│   ├── FileUpload_Validation.md
│   ├── FileUpload_Storage.md
│   ├── Crypto_Symmetric.md
│   ├── Crypto_Asymmetric.md
│   ├── Crypto_Hashing.md
│   ├── Mobile_Android.md
│   ├── Mobile_iOS.md
│   ├── Mobile_Flutter.md
│   ├── Mobile_ReactNative.md
│   ├── Desktop_Electron.md
│   ├── Desktop_DotNet.md
│   ├── Desktop_Tauri.md
│   ├── SSRF.md
│   ├── RCE.md
│   ├── PathTraversal.md
│   ├── IDOR.md
│   ├── RateLimit.md
│   ├── Logging.md
│   ├── SecretManagement.md
│   └── OWASP.md
│
├── Integration.md
└── README.md
```

**49 files** • **~294 KB** • **37 deep modules**

---

# Token Efficiency

| Task                   | Files Loaded | Estimated Tokens | Saved |
| ---------------------- | ------------ | ---------------- | ----- |
| Fix CSS alignment      | 1            | ~300             | 99%   |
| Build a REST API       | 3            | ~2,500           | 95%   |
| Build a Login Page     | 5            | ~4,500           | 91%   |
| Android App + Login    | 5–7          | ~6,000           | 88%   |
| Full-stack Application | 8–12         | ~10,000          | 80%   |
| Load Everything        | 49           | ~50,000          | 0%    |

> Most coding tasks load only **3–7 files (~4,000 tokens)** instead of the entire **49-file (~50,000 token)** knowledge base.

---

# Example Loading Trace

### Build a REST API with JWT Authentication

```text
Security.md
 ├── API
 │     └── Security_API.md
 │            └── API_REST.md
 │
 ├── Authentication
 │     └── Security_Auth.md
 │            └── JWT.md
 │
 └── Cross-cutting
       └── RateLimit.md

Total:
5 files
~4,500 tokens
```

---

### Upload Images in a Flutter App

```text
Security.md
 ├── Flutter
 │     └── Security_Mobile.md
 │            └── Mobile_Flutter.md
 │
 └── Upload
       └── Security_FileUpload.md
              ├── FileUpload_Validation.md
              └── FileUpload_Storage.md
```

---

### Change Button Color

```text
Security.md

No matching keyword.

STOP.
```

---

# Every Module Includes

Each L3 module follows a consistent structure:

1. 🎯 Threat Description
2. ⚔️ Real Attack Examples
3. ✅ Prevention Checklist
4. 💻 Multi-language Code Examples
5. 🔧 Framework-specific Patterns
6. 🧪 Testing Guide
7. 📚 References (OWASP, CWE, RFC)

---

# Extending the Framework

## Add a New Module

```text
1. Create a new file inside modules/
2. Add a LOAD directive in the appropriate L2 router.
3. (Optional) Register new keywords inside Security.md.
4. Done.
```

## Add a New Domain

```text
1. Create a new L2 router.
2. Add the required L3 modules.
3. Register the router inside Security.md.
4. Done.
```

---

# References

This project is based on industry standards, including:

* OWASP Top 10 (2021)
* OWASP ASVS
* OWASP API Security Top 10
* OWASP Mobile Top 10
* OWASP MASVS
* NIST SP 800-63B
* CWE / SANS Top 25

---

# Compatibility

| AI Tool                 | Supported | Configuration                     |
| ----------------------- | --------- | --------------------------------- |
| Cursor                  | ✅         | `.cursor/rules`                   |
| Claude Code             | ✅         | `CLAUDE.md`                       |
| GitHub Copilot          | ✅         | `.github/copilot-instructions.md` |
| OpenCode                | ✅         | `.opencode.md`                    |
| Gemini CLI / Pi         | ✅         | `GEMINI.md`                       |
| Windsurf                | ✅         | `.windsurfrules`                  |
| Aider                   | ✅         | `.aider.conf.yml`                 |
| Any AI with file access | ✅         | Reference `Security.md`           |

See `Integration.md` for complete setup instructions.

---

# License

MIT License — free to use, modify, and distribute.

---

<div align="center">

## Make your AI write secure code automatically.

⭐ If you find this project useful, consider giving it a star!

</div>
