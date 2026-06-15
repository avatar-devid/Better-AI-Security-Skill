# Electron Security — Deep Module

## Scope

Electron-specific security: nodeIntegration, contextIsolation, IPC hardening, preload scripts, and Chromium security.

---

## Electron Security Rules

### 1. Core Security Settings (CRITICAL)

```
RULE: Configure BrowserWindow with security-first defaults.

const win = new BrowserWindow({
  webPreferences: {
    nodeIntegration: false,           // NEVER enable — XSS = full system access
    contextIsolation: true,           // ALWAYS enable — isolates preload from renderer
    sandbox: true,                    // RECOMMENDED — restricts renderer capabilities
    webSecurity: true,                // NEVER disable — enforces same-origin policy
    allowRunningInsecureContent: false,// NEVER enable
    enableRemoteModule: false,        // DEPRECATED and dangerous — don't use
    preload: path.join(__dirname, 'preload.js'),
    nodeIntegrationInWorker: false,
    nodeIntegrationInSubFrames: false,
    webviewTag: false,                // Disable <webview> tag unless needed
    navigateOnDragDrop: false,        // Prevent navigation on file drag
  }
});

IF nodeIntegration is true AND an XSS vulnerability exists:
  → Attacker can: require('child_process').exec('rm -rf /')
  → Full system compromise via a single XSS bug
```

### 2. Preload Script & Context Bridge

```
RULE: Use contextBridge to expose ONLY specific APIs to the renderer.

// preload.js
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('api', {
  // Whitelist specific operations — never expose ipcRenderer directly
  getUser: () => ipcRenderer.invoke('get-user'),
  saveFile: (data) => ipcRenderer.invoke('save-file', data),
  onNotification: (callback) => {
    // Wrap callback to prevent leaking ipcRenderer
    ipcRenderer.on('notification', (event, data) => callback(data));
  },
  removeNotificationListener: () => {
    ipcRenderer.removeAllListeners('notification');
  }
});

// NEVER do this:
contextBridge.exposeInMainWorld('electron', require('electron'));  // ✗ Full access!
contextBridge.exposeInMainWorld('ipc', ipcRenderer);               // ✗ Arbitrary IPC!
```

### 3. IPC Security

```
RULE: Validate ALL IPC messages in the main process.

// main.js
const { ipcMain } = require('electron');

ipcMain.handle('save-file', async (event, data) => {
  // 1. Validate sender
  if (event.senderFrame.url !== 'file:///app/index.html') {
    throw new Error('Unauthorized sender');
  }

  // 2. Validate input
  if (typeof data !== 'object' || !data.content || !data.filename) {
    throw new Error('Invalid data');
  }

  // 3. Sanitize filename
  const safeName = path.basename(data.filename).replace(/[^a-zA-Z0-9._-]/g, '_');

  // 4. Validate path (prevent path traversal)
  const fullPath = path.resolve(SAFE_DIRECTORY, safeName);
  if (!fullPath.startsWith(path.resolve(SAFE_DIRECTORY))) {
    throw new Error('Path traversal detected');
  }

  // 5. Execute with least privilege
  await fs.writeFile(fullPath, data.content);
  return { success: true, path: fullPath };
});

RULE: Never use ipcRenderer.send for sensitive operations — use ipcRenderer.invoke (returns promise).
RULE: Validate event.senderFrame to ensure messages come from expected windows.
```

### 4. Navigation & URL Security

```
RULE: Restrict navigation and new window creation.

// Prevent navigation to untrusted URLs
win.webContents.on('will-navigate', (event, url) => {
  const parsedUrl = new URL(url);
  if (parsedUrl.origin !== 'file://') {
    event.preventDefault();  // Block external navigation
  }
});

// Prevent opening new windows
win.webContents.setWindowOpenHandler(({ url }) => {
  // Open external URLs in default browser, not in Electron
  if (url.startsWith('https://')) {
    shell.openExternal(url);
  }
  return { action: 'deny' };  // Never open new Electron windows from renderer
});

// Block dangerous protocols
app.on('web-contents-created', (event, contents) => {
  contents.on('will-navigate', (event, navigationUrl) => {
    const parsedUrl = new URL(navigationUrl);
    if (!['https:', 'file:'].includes(parsedUrl.protocol)) {
      event.preventDefault();
    }
  });
});
```

### 5. Content Security Policy

```
RULE: Set CSP for Electron renderer pages.

// In HTML
<meta http-equiv="Content-Security-Policy" content="
  default-src 'self';
  script-src 'self';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: https:;
  connect-src 'self' https://api.example.com;
  font-src 'self';
  object-src 'none';
  base-uri 'self';
">

// Or via session headers
session.defaultSession.webRequest.onHeadersReceived((details, callback) => {
  callback({
    responseHeaders: {
      ...details.responseHeaders,
      'Content-Security-Policy': ["default-src 'self'; script-src 'self'"]
    }
  });
});
```

### 6. Auto-Update Security

```
// electron-updater with code signing
const { autoUpdater } = require('electron-updater');

autoUpdater.autoDownload = false;  // Don't auto-download — let user confirm
autoUpdater.autoInstallOnAppQuit = true;

// Verify update signatures (electron-updater does this automatically if app is code-signed)
// Ensure update server uses HTTPS
autoUpdater.setFeedURL({
  provider: 'generic',
  url: 'https://updates.example.com/releases/',
  useMultipleRangeRequest: false
});

autoUpdater.on('update-available', (info) => {
  // Notify user, let them decide
  dialog.showMessageBox({ message: `Update ${info.version} available. Download?` });
});

RULE: Code-sign the application (update signature verification depends on it).
RULE: Use HTTPS for update feed URL.
RULE: Verify update checksum and signature before installation.
```

### 7. Permission Handling

```
// Restrict permission requests from renderer
session.defaultSession.setPermissionRequestHandler((webContents, permission, callback) => {
  const allowedPermissions = ['clipboard-read', 'notifications'];
  callback(allowedPermissions.includes(permission));
});

// Restrict permission checks
session.defaultSession.setPermissionCheckHandler((webContents, permission) => {
  const allowedPermissions = ['clipboard-read', 'notifications'];
  return allowedPermissions.includes(permission);
});
```

### 8. Sensitive Data Handling

```
// Use safeStorage for encrypting secrets
const { safeStorage } = require('electron');

if (safeStorage.isEncryptionAvailable()) {
  const encrypted = safeStorage.encryptString(secret);
  // Store encrypted buffer to file
  fs.writeFileSync(secretPath, encrypted);

  // Decrypt
  const decrypted = safeStorage.decryptString(fs.readFileSync(secretPath));
}

// Clear sensitive data from memory
// JavaScript strings are immutable — use Buffer/Uint8Array
const sensitive = Buffer.from(password);
// After use:
sensitive.fill(0);
```

---

## References

- Electron Security Checklist: https://www.electronjs.org/docs/latest/tutorial/security
- Electron Security Best Practices: https://www.electronjs.org/docs/latest/tutorial/security#checklist-security-recommendations
