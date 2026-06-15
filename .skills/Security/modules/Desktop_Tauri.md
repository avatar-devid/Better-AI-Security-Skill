# Tauri Security — Deep Module

## Scope

Tauri-specific security: command allowlist, IPC security, CSP configuration, scope restrictions, and Rust-backed safety patterns.

---

## Tauri Security Rules

### 1. Command Allowlist (Capabilities)

```
RULE: Tauri v2 uses a capabilities system. Restrict to minimum needed.

// src-tauri/capabilities/default.json (Tauri v2)
{
  "identifier": "default",
  "description": "Default capabilities",
  "windows": ["main"],
  "permissions": [
    "core:default",
    "dialog:allow-open",
    "dialog:allow-save",
    "fs:allow-read",
    "fs:allow-write",
    "http:default",
    "shell:allow-open"
  ]
}

// Tauri v1 — tauri.conf.json allowlist
{
  "tauri": {
    "allowlist": {
      "all": false,  // NEVER set to true
      "fs": { "readFile": true, "writeFile": true, "scope": ["$APPDATA/*"] },
      "dialog": { "open": true, "save": true },
      "http": { "request": true, "scope": ["https://api.example.com/*"] },
      "shell": { "open": true }  // Only open URLs in default browser
    }
  }
}

RULE: Start with all:false and enable only what you need.
RULE: Use scope restrictions for fs, http, and shell commands.
```

### 2. Command Security (Rust Backend)

```
RULE: Validate all inputs in Tauri commands.

#[tauri::command]
fn save_document(name: String, content: String) -> Result<String, String> {
    // 1. Validate filename
    if name.contains("..") || name.contains('/') || name.contains('\\') {
        return Err("Invalid filename".to_string());
    }
    let safe_name: String = name.chars()
        .filter(|c| c.is_alphanumeric() || *c == '.' || *c == '-' || *c == '_')
        .collect();

    // 2. Validate content size
    if content.len() > 10_000_000 {
        return Err("Content too large".to_string());
    }

    // 3. Construct safe path
    let app_dir = app_handle.path_resolver().app_data_dir()
        .ok_or("Cannot resolve app dir")?;
    let full_path = app_dir.join("documents").join(&safe_name);

    // 4. Verify path is within allowed directory
    if !full_path.starts_with(app_dir.join("documents")) {
        return Err("Path traversal detected".to_string());
    }

    std::fs::write(&full_path, &content).map_err(|e| e.to_string())?;
    Ok(safe_name)
}

Rust advantages:
- Memory safety (no buffer overflows, use-after-free)
- Type system prevents many bugs at compile time
- No null pointer exceptions
- Thread safety enforced by compiler
```

### 3. IPC Security

```
RULE: The WebView ↔ Rust boundary is a trust boundary.

Frontend (TypeScript):
  import { invoke } from '@tauri-apps/api/core';

  // Invoke Rust command
  const result = await invoke('save_document', {
    name: sanitizedName,
    content: documentContent,
  });

Backend (Rust):
  // Register commands explicitly
  tauri::Builder::default()
    .invoke_handler(tauri::generate_handler![
      save_document,
      load_document,
      delete_document,
      // Only registered commands are callable
    ])

RULE: Only expose necessary commands via invoke_handler.
RULE: Each command validates its own inputs.
RULE: Use serde deserialization with proper types (not raw strings for structured data).
```

### 4. CSP Configuration

```
// tauri.conf.json
{
  "app": {
    "security": {
      "csp": "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' asset: https:; connect-src ipc: http://ipc.localhost https://api.example.com",
      "dangerousDisableAssetCspModification": false  // NEVER set to true
    }
  }
}

Tauri-specific CSP sources:
- 'self': Local app files
- ipc: / http://ipc.localhost: Tauri IPC communication
- asset: / https://asset.localhost: Local asset protocol
- tauri: Tauri-specific protocol

RULE: Keep CSP strict. Only add sources you actually need.
```

### 5. File System Scope

```
RULE: Restrict file system access to specific directories.

Tauri v2 capabilities:
{
  "permissions": [
    {
      "identifier": "fs:allow-read",
      "allow": [
        { "path": "$APPDATA/**" },
        { "path": "$DOCUMENT/**" }
      ]
    },
    {
      "identifier": "fs:allow-write",
      "allow": [
        { "path": "$APPDATA/**" }
      ]
    }
  ]
}

Variables:
- $APPDATA: Application data directory
- $DOCUMENT: User's documents directory
- $DESKTOP: User's desktop
- $HOME: User's home directory (use cautiously)

RULE: Never allow unrestricted file system access.
RULE: Use $APPDATA for app-specific data.
RULE: Request access to $DOCUMENT/$DESKTOP only through file dialogs.
```

### 6. HTTP Scope

```
RULE: Restrict HTTP requests to known domains.

// Tauri v1 — tauri.conf.json
"http": {
  "request": true,
  "scope": [
    "https://api.example.com/*",
    "https://cdn.example.com/*"
  ]
}

// Tauri v2 — capabilities
{
  "identifier": "http:default",
  "allow": [
    { "url": "https://api.example.com/**" }
  ]
}

RULE: Never allow wildcard HTTP scope (all domains).
RULE: Use HTTPS only (no HTTP in scope).
```

### 7. Update Security

```
// Tauri built-in updater with signature verification
// tauri.conf.json
{
  "plugins": {
    "updater": {
      "active": true,
      "pubkey": "PUBLIC_KEY_FOR_VERIFICATION",
      "endpoints": ["https://updates.example.com/{{target}}/{{arch}}/{{current_version}}"]
    }
  }
}

// Generate signing keys
// tauri signer generate -w ~/.tauri/myapp.key

RULE: Always configure the pubkey for update signature verification.
RULE: Use HTTPS for update endpoints.
RULE: The updater automatically verifies signatures — don't bypass this.
```

### 8. Build Security

```
// Build with optimizations and stripping
// Cargo.toml
[profile.release]
opt-level = 3
lto = true       # Link-time optimization
strip = true      # Strip debug symbols
codegen-units = 1 # Better optimization

// Don't include debug info in release
#[cfg(debug_assertions)]
fn debug_only_function() { /* ... */ }

// Environment-specific configuration
let api_url = if cfg!(debug_assertions) {
    "http://localhost:3000"
} else {
    "https://api.example.com"
};
```

---

## References

- Tauri Security: https://tauri.app/security/
- Tauri Capabilities: https://v2.tauri.app/security/capabilities/
