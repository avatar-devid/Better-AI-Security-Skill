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

### 7. Memory Security & Buffer Overflow Prevention

```
RULE: Protect memory from corruption, exposure, and heap/stack overflows.

Memory-safe practices:
- Preferred languages: Use memory-safe runtimes (.NET, Rust, Go, Java) for new development.
- Bounds checking: Always check array boundaries and input lengths before buffer writes.
- Safe functions: In native code (C/C++), ban dangerous functions:
  - BANNED: strcpy, sprintf, strcat, gets, scanf
  - USE INSTEAD: strncpy, snprintf, strncat, fgets, sscanf (or std::string/std::vector)

Memory clearing and locks:
- Clear sensitive data: Overwrite memory containing secrets (passwords, keys) with zeros (e.g., SecureZeroMemory on Windows) immediately after use.
- Overcome string immutability: Avoid storing secrets in immutable strings (C# string, JS/TS strings) since garbage collectors may keep them in memory. Use byte arrays or SecureString (.NET) instead.
- Lock memory: Use `mlock` (Unix) or `VirtualLock` (Windows) to prevent sensitive memory pages from being written to swap files on disk.

Compilation hardening (for native binaries):
- DEP/NX (Data Execution Prevention): Marks memory pages (like stack and heap) as non-executable.
- ASLR (Address Space Layout Randomization): Randomizes memory offsets to prevent predictable shellcode jump addresses.
- Stack Canaries (-fstack-protector /GS): Places cookie values on the stack to detect buffer overflows before returning from a function.
- Control Flow Guard (CFG): Prevents hijack of indirect call targets.
```

### 8. Privilege Management

```
RULE: Run with minimum required privileges.

- Never run the app as Administrator/root unless necessary.
- If elevated privileges are needed, request them only for specific operations.
- Use privilege separation (separate process for privileged operations).
- Drop privileges as soon as elevated operation completes.
- On Windows: use proper UAC integration.
- On macOS: use Authorization Services for privileged helpers.
- On Linux: use PolicyKit or separate setuid helper.
```

### 9. Network Security

```
RULE: Desktop apps often make direct network connections. Secure them.

- Use HTTPS for all network requests.
- Implement certificate pinning for critical connections.
- Validate SSL/TLS certificates (never disable verification).
- Use proxy settings from OS (support corporate proxies).
- Implement timeout on all network requests.
- Handle network errors gracefully (no sensitive data in errors).
- Use DNS-over-HTTPS if DNS security is a concern.
```

### 10. Anti-Tampering & Static Analysis Evasion

```
RULE: Protect application integrity and obfuscate critical assets.

Anti-debugging & Instrumentation:
- Check debugger presence at startup (e.g., IsDebuggerPresent() on Windows, ptrace checks on Linux).
- Block instrumentation tools (e.g., detect Frida or hook detection).
- Exit gracefully or self-terminate if tampering is detected.

Static Analysis Evasion (XORSTR / String Obfuscation):
- Threat: Attackers run `strings` or reverse-engineer your binary in IDA Pro/Ghidra to harvest hardcoded secrets, server endpoints, or internal logic messages.
- Prevention:
  - Do NOT store plaintext strings or API endpoints in native binaries.
  - Use compile-time string encryption libraries like C++ `xorstr` or `skr::xorstr` to encrypt string literals at compile time and decrypt them in-memory only when executed.
  - Implement a simple runtime XOR loop to decrypt obfuscated strings immediately before use and zero-out the memory immediately afterward.
  - For managed languages (.NET, Java), use commercial or robust open-source obfuscators (e.g., ConfuserEx, R8/ProGuard) to encrypt strings and mangle control flow.

Obfuscated String Example (C++ Conceptual):
  #define XOR_KEY 0x5A
  void decrypt(char* str, size_t len) {
      for(size_t i = 0; i < len; i++) str[i] ^= XOR_KEY;
  }
  // At runtime, decrypt, use, and immediately clear:
  char endpoint[] = {0x1D, 0x0E, 0x0E, 0x2A, 0x00}; // "https" obfuscated
  decrypt(endpoint, 4);
  make_request(endpoint);
  SecureZeroMemory(endpoint, sizeof(endpoint));
```

### 11. Clipboard Security

```
RULE: Handle clipboard operations securely.

- Clear sensitive data from clipboard after a timeout (30 seconds).
- Warn users when copying sensitive data.
- Don't write passwords to clipboard without user action.
- Consider using a custom clipboard that auto-clears.
- On macOS: use NSPasteboard with concealed type for sensitive data.
```

### 12. Installer & Distribution Security

```
RULE: Secure the installation process.

- Sign the installer package.
- Verify the installer's integrity before running.
- Install to standard locations (Program Files, /Applications).
- Set proper file permissions on installed files.
- Don't require admin privileges for installation if possible.
- Clean up temporary files after installation.
- Register uninstaller properly.
- Don't modify system-wide settings without user consent.
```

### 13. Remote Code Execution (RCE) Prevention

```
RULE: Strictly prevent arbitrary command execution.

- Avoid shell invocation: Never pass raw user inputs or external parameters directly to shell executors (e.g., C/C++ `system()`, C# `Process.Start()`, Python `os.system()`, Node.js `child_process.exec()`).
- Use argument lists: Always use safe process APIs that execute binaries directly with structured arguments as an array/list, bypassing command-line parsing shells (e.g., `ProcessStartInfo.ArgumentList` in C#, `Command::new().args()` in Rust, `execFile` in Node.js).
- Input Whitelisting: If arguments must be dynamic, validate them using strict regex (allowing only alphanumeric characters) and check against an explicit whitelist of allowed commands.
- Secure Deserialization: Never deserialize untrusted data using polymorphic formatters (e.g., .NET BinaryFormatter, Python pickle, Java native deserialization). Use safe, schema-bound formats like JSON, MessagePack, or Protocol Buffers.
```

### 14. Library & DLL Hijacking Prevention

```
RULE: Prevent malicious code injection through dynamic library loading.

- DLL Search Order Hijacking (Windows):
  - Threat: Windows searches the application directory for DLLs before system folders. Attackers drop a malicious DLL (e.g., `version.dll` or `dwmapi.dll`) in the application folder, triggering RCE when your app starts.
  - Prevention:
    - Call `SetDllDirectory("")` at the very entry point of your program to remove the current working directory from the DLL search path.
    - Always load external libraries using absolute paths or explicit directories.
    - Use `LoadLibraryEx` with secure flags like `LOAD_LIBRARY_SEARCH_SYSTEM32` to ensure libraries are loaded only from the system folder.
- Signature verification:
  - Digitally verify code signatures of dynamically loaded libraries (.dll, .so, .dylib) before executing functions from them.
```
