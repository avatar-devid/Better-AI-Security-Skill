# Security Skill — Integration Guide

How to integrate this hierarchical Security Skill system with your AI coding tools.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Cursor](#cursor)
- [Claude Code (claude-code)](#claude-code)
- [OpenCode](#opencode)
- [Google Gemini CLI / Project IDX / Pi](#pi)
- [VS Code Copilot (GitHub Copilot)](#vs-code-copilot)
- [General Tips](#general-tips)

---

## Architecture Overview

```
e:\AI_Skills\Security\
├── Security.md                    ← ENTRY POINT (always read this first)
├── Security_Web.md                ← Domain routers (loaded conditionally)
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
└── modules/                       ← Deep detail (loaded conditionally by L2)
    ├── XSS.md
    ├── CSRF.md
    ├── ...
    └── OWASP.md
```

**Loading flow:**

```
Task → Security.md (decision tree)
         │
         ├── Match keyword? → Load relevant Security_*.md (L2)
         │                        │
         │                        └── Match sub-keyword? → Load modules/*.md (L3)
         │
         └── No match? → STOP. No security skill needed.
```

---

## Cursor

### Method 1: Project Rules (Recommended)

Create a `.cursor/rules` file in your project root:

```
# .cursor/rules

You have access to a hierarchical Security Skill system.

## Security Skill Loading Protocol

1. At the START of every task, read the file:
   e:\AI_Skills\Security\Security.md

2. This file contains a decision tree. Evaluate your current task against
   the keyword conditions listed.

3. For EACH matching condition, LOAD the corresponding file as instructed.

4. Each loaded file may contain its own sub-router with additional LOAD
   directives. Follow those as well.

5. If NO condition matches, STOP. Do not load any security files.

6. Apply ALL security rules from loaded files to your implementation.

## Important
- Only load files that match your task (minimize context usage)
- Security rules are MANDATORY, not suggestions
- When in doubt, load the module — false positive is better than missing a vulnerability
```

### Method 2: .cursorrules (Legacy)

Create `.cursorrules` in your project root with the same content as above.

### Method 3: Notepads

1. Open Cursor → Settings → Notepads
2. Create a new notepad called "Security"
3. Paste the content of `Security.md` into the notepad
4. Reference it in conversations with `@Security`

### Method 4: @file Reference (Per-conversation)

In any Cursor chat, type:

```
@file e:\AI_Skills\Security\Security.md

Apply security best practices to my current task.
```

Cursor will read the file and follow the LOAD directives.

### Cursor Recommended Setup

```
your-project/
├── .cursor/
│   └── rules              ← Auto-applies security skill to every task
├── src/
└── ...
```

---

## Claude Code

### Method 1: CLAUDE.md (Recommended)

Create a `CLAUDE.md` file in your project root:

```markdown
# CLAUDE.md

## Security Skill

This project uses a hierarchical security skill system.

### Protocol

1. Before implementing any code, read:
   e:\AI_Skills\Security\Security.md

2. Follow the decision tree in that file:
   - Match keywords from the current task against the conditions
   - LOAD only the files that match
   - Each loaded file may have sub-routers — follow those too
   - If nothing matches, skip security loading

3. Apply all loaded security rules to your implementation.

### Quick Reference Paths
- Root:     e:\AI_Skills\Security\Security.md
- Web:      e:\AI_Skills\Security\Security_Web.md
- API:      e:\AI_Skills\Security\Security_API.md
- Database: e:\AI_Skills\Security\Security_Database.md
- Auth:     e:\AI_Skills\Security\Security_Auth.md
- Mobile:   e:\AI_Skills\Security\Security_Mobile.md
- Desktop:  e:\AI_Skills\Security\Security_Desktop.md
```

### Method 2: Slash Command

In Claude Code terminal, use:

```bash
claude "Read e:\AI_Skills\Security\Security.md and apply relevant security rules to my task: [describe task]"
```

### Method 3: Project Memory

Add to Claude Code's project memory via `/init` command:

```
This project follows security rules defined in e:\AI_Skills\Security\Security.md.
Before any security-relevant implementation, read that file and follow its
decision tree to load only the necessary security modules.
```

### Claude Code Tips

- Claude Code can read files directly — just reference the path
- Use `cat` or `Read` tool to load files
- The hierarchical design works well with Claude Code's context management
- Claude Code respects CLAUDE.md automatically on every conversation

---

## OpenCode

### Method 1: System Prompt Configuration

Configure in `~/.config/opencode/config.toml` (or project-level `.opencode.toml`):

```toml
[agent]
system_prompt = """
You have access to a hierarchical Security Skill system at:
e:\AI_Skills\Security\

Protocol:
1. At the start of every task, read Security.md
2. Follow its decision tree — LOAD only matching files
3. Apply all loaded security rules to your implementation
4. If no keywords match, skip security loading
"""
```

### Method 2: Project Instructions

Create `.opencode.md` in your project root:

```markdown
# OpenCode Project Instructions

## Security Skill Protocol

Before implementing any security-relevant code:

1. Read: e:\AI_Skills\Security\Security.md
2. Follow the decision tree to identify relevant modules
3. Load and apply matching security rules
4. Modules are at: e:\AI_Skills\Security\modules/

This is a hierarchical loading system — only load what your task needs.
```

### Method 3: Per-Session

In OpenCode chat:

```
Read e:\AI_Skills\Security\Security.md first, then help me build a REST API
with authentication. Follow the LOAD directives in that file to apply
relevant security rules.
```

---

## Pi

### Method 1: Gemini Skill Files

If using Google Gemini CLI or Pi (Antigravity IDE), place skill files where the tool can discover them:

#### Antigravity IDE / Pi

Skills are automatically discovered. Create a skill instruction file:

```markdown
<!-- e:\AI_Skills\Security\Security.md is already the skill entry point -->
<!-- Pi reads .md files marked with IsSkillFile=true -->
```

In conversation, reference the skill:

```
@skill Security

Build a login page with email and password.
```

Pi will read `Security.md`, follow the decision tree, and apply relevant security modules.

#### Gemini CLI

Add to your `.gemini/settings.json`:

```json
{
  "systemInstructions": [
    {
      "file": "e:\\AI_Skills\\Security\\Security.md",
      "description": "Security skill — hierarchical module loading"
    }
  ]
}
```

Or reference inline:

```bash
gemini "Read e:\AI_Skills\Security\Security.md and apply security to: [task]"
```

### Method 2: Workspace Context

Place a `GEMINI.md` in your project root:

```markdown
## Security

This project uses a hierarchical security skill at e:\AI_Skills\Security\Security.md.
Read it at task start. Follow its LOAD directives to conditionally load domain-specific
security modules. Apply all loaded rules.
```

---

## VS Code Copilot

### Method 1: .github/copilot-instructions.md (Recommended)

Create `.github/copilot-instructions.md` in your project:

```markdown
# Copilot Instructions

## Security Skill Protocol

This project uses a hierarchical security skill system located at:
`e:\AI_Skills\Security\`

### How to Use

1. **Before implementing any feature**, read the file:
   `e:\AI_Skills\Security\Security.md`

2. **Evaluate the decision tree** in that file against your current task.

3. **For each matching keyword condition**, read the corresponding file:
   - Web tasks → `Security_Web.md` → may load `modules/XSS.md`, `modules/CSRF.md`, etc.
   - API tasks → `Security_API.md` → may load `modules/API_REST.md`, etc.
   - Database tasks → `Security_Database.md` → may load `modules/SQL_Security.md`, etc.
   - Auth tasks → `Security_Auth.md` → may load `modules/JWT.md`, `modules/Password.md`, etc.
   - File upload → `Security_FileUpload.md` → may load `modules/FileUpload_Validation.md`, etc.
   - Mobile → `Security_Mobile.md` → may load `modules/Mobile_Android.md`, etc.
   - Desktop → `Security_Desktop.md` → may load `modules/Desktop_Electron.md`, etc.

4. **Apply all security rules** from loaded files to your code.

5. **If no condition matches**, skip security — no loading needed.

### Key Rules
- Never skip security checks for matching tasks
- Load only relevant modules (don't load everything)
- Security rules are requirements, not suggestions
```

### Method 2: Workspace Settings

Add to `.vscode/settings.json`:

```json
{
  "github.copilot.chat.codeGeneration.instructions": [
    {
      "file": ".github/copilot-instructions.md"
    }
  ],
  "github.copilot.chat.reviewSelection.instructions": [
    {
      "text": "Check code against security rules in e:\\AI_Skills\\Security\\Security.md. Follow the decision tree to identify which security modules apply. Verify all applicable rules are followed."
    }
  ]
}
```

### Method 3: Chat Participants (@workspace)

In Copilot Chat, use `@workspace` to include project context:

```
@workspace Read e:\AI_Skills\Security\Security.md and apply relevant
security rules to the authentication system I'm building.
```

### Method 4: Custom Instructions (User-Level)

Go to VS Code → Settings → Copilot → Custom Instructions:

```
When writing security-relevant code (auth, API, database, file upload,
encryption, session management), read the Security Skill at
e:\AI_Skills\Security\Security.md and follow its hierarchical loading
protocol to apply the correct security rules.
```

### Method 5: Copilot Edits with Context

When using Copilot Edits (Ctrl+Shift+I), add context files:

1. Click "Add Files" in the Copilot Edits panel
2. Add `e:\AI_Skills\Security\Security.md`
3. Add the relevant L2 file (e.g., `Security_Auth.md`)
4. Add the relevant L3 module (e.g., `modules/Password.md`)
5. Describe your task — Copilot will apply the security rules

---

## General Tips

### 1. Symbolic Links (Cross-Project Reuse)

Create symbolic links so the security skill is available in every project:

```powershell
# PowerShell (run as Administrator)
New-Item -ItemType SymbolicLink -Path "C:\Projects\my-app\.security" -Target "e:\AI_Skills\Security"
```

Then reference `.security/Security.md` in your project's AI configuration.

### 2. Git Submodule (Team Sharing)

If you version-control the security skill:

```bash
git submodule add https://github.com/your-org/security-skill.git .security
```

All team members get the same security rules.

### 3. Universal Prompt Template

For any AI tool that supports custom prompts, use this template:

```
## Security Skill Protocol

Before implementing code, follow this protocol:

1. Read the entry point: [PATH]/Security.md
2. This file contains a decision tree with IF/LOAD rules
3. For each keyword match, read the referenced file
4. Each referenced file may have its own sub-router — follow those too
5. Apply ALL security rules from loaded files
6. If no keywords match your task, skip security loading

This is a hierarchical system — only load what's relevant.
Average task loads 3-5 files (~4,000 tokens), not all 49 files (~50,000 tokens).
```

### 4. Testing the Integration

After setup, test with these prompts:

```
Test 1 (should load Auth + Password + Web + CSRF):
"Create a login page with email and password"

Test 2 (should load API + REST):
"Create a REST API endpoint for listing products"

Test 3 (should load NOTHING):
"Fix the CSS alignment on the footer"

Test 4 (should load Mobile + Android):
"Build an Android app settings screen with Kotlin"
```

Verify the AI loads only the correct modules — not too many, not too few.

### 5. Updating the Skill

When you update a security module:

1. Edit the specific module file
2. No need to update other files (modular design)
3. All AI tools will pick up changes on next conversation
4. Version the changes if using Git

### 6. Adding New Modules

To extend the system:

1. Add a new L3 file in `modules/` (e.g., `modules/WebAssembly.md`)
2. Add a LOAD directive in the appropriate L2 router
3. Optionally add keywords in `Security.md` if it's a new domain
4. The hierarchy is extensible — no other files need changes

---

## Compatibility Matrix

| Tool | Auto-Load | File Reference | Project Config | Works Offline |
|------|-----------|----------------|----------------|---------------|
| **Cursor** | ✅ via .cursor/rules | ✅ @file | ✅ .cursorrules | ✅ |
| **Claude Code** | ✅ via CLAUDE.md | ✅ Read tool | ✅ /init memory | ✅ |
| **OpenCode** | ✅ via .opencode.md | ✅ Read tool | ✅ config.toml | ✅ |
| **Pi / Gemini** | ✅ via skill discovery | ✅ @skill | ✅ GEMINI.md | ✅ |
| **VS Code Copilot** | ✅ via copilot-instructions | ✅ @workspace | ✅ settings.json | ❌ (cloud) |
