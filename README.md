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

The easiest way to integrate this AI Security Skill into your coding project is by running our automated installation script directly in your project root.

## Option A: Automated Installation (Recommended)

Run the command corresponding to your operating system in your target project directory:

### Bash (macOS / Linux / Git Bash / WSL)
```bash
curl -sSL https://raw.githubusercontent.com/avatar-devid/Better-AI-Security-Skill/main/install.sh | bash
```

### PowerShell (Windows)
```powershell
irm https://raw.githubusercontent.com/avatar-devid/Better-AI-Security-Skill/main/install.ps1 | iex
```

The script will automatically:
1. Download the `.skills/Security` folder into your project.
2. Generate all the relevant AI rules/configuration files (`.cursor/rules/security.mdc`, `CLAUDE.md`, `.github/copilot-instructions.md`, `.windsurfrules`, `GEMINI.md`) referencing your local `.skills/Security/Security.md` relative path.

---

## Option B: Manual Installation

If you prefer to install it manually:

### 1. Clone this Repository or Copy Files
Copy the `.skills` directory into your project root:
```text
your-project/
└── .skills/
    └── Security/
```

### 2. Configure Your AI Assistant
Create the configuration file(s) for your AI assistant in your project root using the relative path `.skills/Security/Security.md`:

#### Cursor
Create `.cursor/rules/security.mdc`:
```markdown
---
description: Apply security best practices to code generation and updates
globs: *
---
# Security Rules
Before writing or modifying any code in this project, read and follow the decision tree in:
.skills/Security/Security.md

LOAD only the relevant security modules and apply all loaded rules.
```

#### Claude Code
Create `CLAUDE.md`:
```markdown
# CLAUDE.md

## Security Skill
This project uses a hierarchical security skill system. Before implementing code, read:
.skills/Security/Security.md

Follow its decision tree and load the matching security modules. Apply all loaded rules.
```

#### GitHub Copilot
Create `.github/copilot-instructions.md`:
```markdown
# Copilot Instructions

## Security Skill Protocol
This project uses a hierarchical security skill system. Before implementing any feature:

1. Read: .skills/Security/Security.md
2. Evaluate the decision tree and load every matching module.
3. Apply all loaded rules.
```

#### Windsurf
Create `.windsurfrules`:
```markdown
You have access to a hierarchical Security Skill system.
At the START of every task, read:
.skills/Security/Security.md

Follow the decision tree. LOAD only matching files. Apply every loaded security rule.
```

#### Gemini
Create `GEMINI.md`:
```markdown
## Security Skill
Before every implementation task, read:
.skills/Security/Security.md

Follow every LOAD directive and apply every loaded security rule.
```

### 3. Done!
Your AI assistant will automatically read `.skills/Security/Security.md`, follow the decision tree, and apply best practices.

---

# File Structure

```text
.skills/
└── Security/
    ├── Security.md                      # L1 Root Router
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
    └── modules/
        ├── XSS.md
        ├── CSRF.md
        ├── CSP.md
        ├── Cookie.md
        ├── SQL_Security.md
        ├── ORM_Security.md
        ├── NoSQL_Security.md
        ├── Migration_Security.md
        ├── JWT.md
        ├── OAuth.md
        ├── Password.md
        ├── MFA.md
        ├── RBAC.md
        ├── API_REST.md
        ├── API_GraphQL.md
        ├── API_gRPC.md
        ├── API_WebSocket.md
        ├── FileUpload_Validation.md
        ├── FileUpload_Storage.md
        ├── Crypto_Symmetric.md
        ├── Crypto_Asymmetric.md
        ├── Crypto_Hashing.md
        ├── Mobile_Android.md
        ├── Mobile_iOS.md
        ├── Mobile_Flutter.md
        ├── Mobile_ReactNative.md
        ├── Desktop_Electron.md
        ├── Desktop_DotNet.md
        ├── Desktop_Tauri.md
        ├── SSRF.md
        ├── RCE.md
        ├── PathTraversal.md
        ├── IDOR.md
        ├── RateLimit.md
        ├── Logging.md
        ├── SecretManagement.md
        └── OWASP.md

Integration.md
README.md
install.sh                           # Bash installation script
install.ps1                          # PowerShell installation script
```

**53 files** • **~305 KB** • **37 deep modules**

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

# Repository Resources & Metadata

## 🏷️ GitHub Topics
This project is categorized under the following topics:
`security` • `ai` • `copilot` • `cursor` • `claude` • `prompt-engineering` • `ai-agent` • `secure-coding` • `owasp` • `security-rules` • `llm`

## 📢 GitHub Discussions
Got questions, suggestions, or custom rules to share? Join the conversation in [GitHub Discussions](https://github.com/avatar-devid/Better-AI-Security-Skill/discussions). We welcome community feedback and collaboration on refining security protocols!

## 📖 GitHub Wiki
For deep dives, custom extension guides, and additional integration patterns, please visit our [GitHub Wiki](https://github.com/avatar-devid/Better-AI-Security-Skill/wiki).

## 📦 Releases & Tags
We follow semantic versioning. You can find stable milestones under the [Releases](https://github.com/avatar-devid/Better-AI-Security-Skill/releases) tab. Use git tags to lock down a specific, audited version of these rules in your production pipelines.

---

# License

MIT License — free to use, modify, and distribute.

---

<div align="center">

## Make your AI write secure code automatically.

⭐ If you find this project useful, consider giving it a star!

</div>
