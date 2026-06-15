# Security — Desktop Applications

## Scope

This module covers security for desktop applications: Electron, .NET (WPF/WinForms/MAUI), Tauri, Qt, JavaFX, and native desktop apps.

## Sub-Router

```
IF task contains [Electron, Chromium, Node Integration, Context Isolation, BrowserWindow, Preload, IPC Main, IPC Renderer, electron-builder, electron-forge]
    LOAD modules/Desktop_Electron.md

IF task contains [WPF, WinForms, MAUI, .NET Desktop, C# Desktop, XAML, ClickOnce, DPAPI, Windows App, UWP, WinUI]
    LOAD modules/Desktop_DotNet.md

IF task contains [Tauri, Rust Desktop, Tauri Command, Tauri IPC, Tauri Plugin, WebView, Wry]
    LOAD modules/Desktop_Tauri.md
```

## Universal Desktop Security Rules

### 1. Local Data Security

```
RULE: Desktop apps store data locally. Protect it.

Sensitive data storage:
- Credentials: OS keychain (Windows Credential Manager, macOS Keychain, Linux Secret Service)
- API keys: OS keychain or encrypted storage
- User data: Encrypted local database (SQLCipher for SQLite)
- Config: Encrypted if contains secrets

NEVER:
- Store credentials in plain text config files
- Store API keys in application code
- Store tokens in localStorage/sessionStorage (Electron)
- Write sensitive data to log files
- Store secrets in registry without encryption (Windows)
```

### 2. Code Signing

```
RULE: All production builds MUST be code-signed.

Purpose:
- Proves the app comes from you (authenticity)
- Proves the app hasn't been modified (integrity)
- Prevents OS security warnings
- Required for app store distribution

Platforms:
- Windows: EV Code Signing Certificate (Authenticode)
- macOS: Apple Developer Certificate + Notarization
- Linux: GPG signing for packages

RULE: Protect signing keys as critical infrastructure.
RULE: Use CI/CD for signing (keys never on developer machines).
RULE: Use timestamp server (app remains valid after cert expiry).
```

### 3. Auto-Update Security

```
RULE: Application updates are a critical attack vector. Secure them.

Secure update flow:
1. Check for updates over HTTPS (certificate pinning recommended)
2. Download update to temporary location
3. Verify digital signature of update package
4. Verify checksum (SHA-256) matches manifest
5. Apply update
6. Verify installation integrity post-update

NEVER:
- Download updates over HTTP
- Skip signature verification
- Allow unsigned updates
- Auto-update without user consent (except for security patches)
- Use update server without authentication

Frameworks:
- Electron: electron-updater (with code signing)
- Tauri: built-in updater (with signature verification)
- .NET: ClickOnce, Squirrel, MSIX
```

### 4. Inter-Process Communication (IPC)

```
RULE: IPC is a trust boundary. Validate all messages.

Common IPC mechanisms:
- Named pipes (Windows)
- Unix domain sockets (Linux/macOS)
- D-Bus (Linux)
- COM (Windows)
- Electron IPC (ipcMain/ipcRenderer)
- Tauri commands

Security rules:
- Validate all IPC messages (schema + authorization)
- Restrict IPC listeners to expected senders
- Use unique pipe names (include random component)
- Set proper permissions on IPC endpoints
- Never pass unsanitized data through IPC
- Minimize IPC surface area (expose only necessary methods)
```

### 5. WebView Security

```
IF the desktop app embeds a WebView (Electron, Tauri, CEF, WebView2):

RULE: WebView is a browser. Apply web security rules.

Checklist:
- Disable Node.js integration in WebView (Electron: nodeIntegration: false)
- Enable context isolation (Electron: contextIsolation: true)
- Use Content Security Policy
- Validate all URLs loaded in WebView
- Restrict navigation (prevent navigating to untrusted sites)
- Disable remote module (Electron)
- Sanitize WebView-to-native communication
- Don't load remote content in WebView if possible

URL validation:
- Whitelist allowed protocols (https:, app:)
- Whitelist allowed domains
- Block file:// protocol for remote content
- Block javascript: protocol
- Validate URL before navigation
```

### 6. File System Access

```
RULE: Desktop apps often have broad file system access. Restrict it.

Principle of least privilege:
- Only access files the user explicitly selects (file dialog)
- Restrict to user's data directory
- Never access system files unless absolutely necessary
- Use app-specific data directory (AppData, Application Support)

Path security:
- Validate and sanitize all file paths
- Prevent path traversal (../../)
- Resolve symlinks and verify final path
- Check file permissions before access
- Use sandboxing where available
```

### 7. Memory Security

```
RULE: Sensitive data in memory must be managed carefully.

- Clear sensitive data from memory after use
- Avoid string immutability issues (strings can't be cleared in managed languages)
  - Use SecureString (.NET), byte arrays, or dedicated secure memory
- Use memory-locked allocations for critical secrets (mlock)
- Prevent memory dumps from containing secrets
- Disable core dumps in production
- Be cautious of swap file exposure (lock pages in memory)
```

### 8. Privilege Management

```
RULE: Run with minimum required privileges.

- Never run the app as Administrator/root unless necessary
- If elevated privileges needed, request them only for specific operations
- Use privilege separation (separate process for privileged operations)
- Drop privileges as soon as elevated operation completes
- On Windows: use proper UAC integration
- On macOS: use Authorization Services for privileged helpers
- On Linux: use PolicyKit or separate setuid helper
```

### 9. Network Security

```
RULE: Desktop apps often make direct network connections. Secure them.

- Use HTTPS for all network requests
- Implement certificate pinning for critical connections
- Validate SSL/TLS certificates (never disable verification)
- Use proxy settings from OS (support corporate proxies)
- Implement timeout on all network requests
- Handle network errors gracefully (no sensitive data in errors)
- Use DNS-over-HTTPS if DNS security is a concern
```

### 10. Anti-Tampering

```
RULE: Protect application integrity at runtime.

Measures:
- Runtime integrity checks (verify code signatures)
- Detect debugger attachment (anti-debugging)
- Obfuscate sensitive logic (not as sole protection)
- Monitor for DLL injection / code injection
- Validate loaded libraries against whitelist
- Use ASLR, DEP, and other OS security features
- Implement license validation securely

NOTE: Anti-tampering is defense-in-depth. A determined attacker can bypass it.
      Never rely solely on client-side protection for security-critical logic.
```

### 11. Clipboard Security

```
RULE: Handle clipboard operations securely.

- Clear sensitive data from clipboard after a timeout (30 seconds)
- Warn users when copying sensitive data
- Don't write passwords to clipboard without user action
- Consider using a custom clipboard that auto-clears
- On macOS: use NSPasteboard with concealed type for sensitive data
```

### 12. Installer Security

```
RULE: Secure the installation process.

- Sign the installer package
- Verify the installer's integrity before running
- Install to standard locations (Program Files, /Applications)
- Set proper file permissions on installed files
- Don't require admin privileges for installation if possible
- Clean up temporary files after installation
- Register uninstaller properly
- Don't modify system-wide settings without user consent
```
