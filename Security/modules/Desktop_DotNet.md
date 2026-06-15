# .NET Desktop Security — Deep Module

## Scope

Security for WPF, WinForms, MAUI, and .NET desktop applications: DPAPI, CAS, assembly signing, registry security, and Windows-specific protections.

---

## .NET Desktop Security Rules

### 1. Data Protection (DPAPI)

```
RULE: Use DPAPI for local secret storage on Windows.

using System.Security.Cryptography;

// Encrypt (CurrentUser scope — only this user can decrypt)
byte[] encrypted = ProtectedData.Protect(
    Encoding.UTF8.GetBytes(secret),
    optionalEntropy,  // Additional entropy (app-specific salt)
    DataProtectionScope.CurrentUser  // or LocalMachine
);

// Decrypt
byte[] decrypted = ProtectedData.Unprotect(
    encrypted,
    optionalEntropy,
    DataProtectionScope.CurrentUser
);

// For ASP.NET Core / modern .NET — use Data Protection API
var protector = dataProtectionProvider.CreateProtector("Secrets.v1");
string encrypted = protector.Protect(plainText);
string decrypted = protector.Unprotect(encrypted);

Scopes:
- CurrentUser: Only the current Windows user can decrypt (recommended)
- LocalMachine: Any user on the machine can decrypt (use only for shared services)

NEVER:
- Store secrets in app.config/appsettings.json in plain text
- Store secrets in Windows Registry without encryption
- Use hardcoded keys in source code
```

### 2. Assembly Security

```
// Strong-name signing (integrity, not security guarantee)
[assembly: AssemblyKeyFile("MyKey.snk")]

// Authenticode signing (verifies publisher identity)
signtool sign /f certificate.pfx /p password /t http://timestamp.digicert.com app.exe

RULE: Always Authenticode-sign release binaries.
RULE: Use timestamp server (signature remains valid after cert expires).
RULE: Use EV Code Signing Certificate for Windows SmartScreen reputation.

// Assembly load security
// Don't load assemblies from untrusted locations
// Validate assembly identity before loading
Assembly.LoadFrom(path);  // Verify path is trusted
```

### 3. Input Validation

```
RULE: Validate all user input even in desktop apps.

// WPF binding validation
public class EmailValidationRule : ValidationRule {
    public override ValidationResult Validate(object value, CultureInfo ci) {
        string email = value as string;
        if (string.IsNullOrEmpty(email) || !Regex.IsMatch(email, @"^[^@]+@[^@]+\.[^@]+$"))
            return new ValidationResult(false, "Invalid email address");
        return ValidationResult.ValidResult;
    }
}

// Sanitize for SQL (always use parameterized queries)
using var cmd = new SqlCommand("SELECT * FROM Users WHERE Id = @id", connection);
cmd.Parameters.AddWithValue("@id", userId);

// Sanitize file paths
string safePath = Path.GetFullPath(Path.Combine(baseDir, userInput));
if (!safePath.StartsWith(Path.GetFullPath(baseDir)))
    throw new SecurityException("Path traversal detected");
```

### 4. Registry Security

```
RULE: Use registry carefully. Encrypt sensitive values.

// Safe registry usage
using var key = Registry.CurrentUser.CreateSubKey(@"SOFTWARE\MyApp\Settings");
key.SetValue("LastSync", DateTime.UtcNow.ToString("o"));

// For sensitive data — encrypt before storing
var encrypted = ProtectedData.Protect(Encoding.UTF8.GetBytes(value),
    null, DataProtectionScope.CurrentUser);
key.SetValue("ApiKey", Convert.ToBase64String(encrypted));

NEVER:
- Store plain text passwords in registry
- Use HKLM without admin privileges check
- Store API keys without encryption
```

### 5. Inter-Process Communication

```
// Named pipes with ACL
var pipeSecurity = new PipeSecurity();
pipeSecurity.AddAccessRule(new PipeAccessRule(
    WindowsIdentity.GetCurrent().User,
    PipeAccessRights.FullControl,
    AccessControlType.Allow));

var server = new NamedPipeServerStream("MyApp.Pipe",
    PipeDirection.InOut, 1, PipeTransmissionMode.Byte,
    PipeOptions.Asynchronous, 1024, 1024, pipeSecurity);

// Validate client identity
server.WaitForConnection();
var clientIdentity = server.GetImpersonationUserName();

RULE: Set restrictive ACLs on IPC endpoints.
RULE: Validate client identity before processing messages.
RULE: Use unique, non-predictable pipe names.
```

### 6. Windows Credential Manager

```
// Use Windows Credential Manager for credentials
using CredentialManagement;

var cred = new Credential {
    Target = "MyApp:ApiToken",
    Username = "api",
    Password = token,
    PersistanceType = PersistanceType.LocalComputer
};
cred.Save();

// Retrieve
var cred = new Credential { Target = "MyApp:ApiToken" };
cred.Load();
string token = cred.Password;

// Delete
cred.Delete();
```

### 7. Exception Handling

```
RULE: Never expose internal details in error messages to users.

try {
    // Operation
} catch (SqlException ex) {
    Logger.Error(ex);  // Full details to log
    MessageBox.Show("A database error occurred. Please contact support.",
        "Error", MessageBoxButton.OK, MessageBoxImage.Error);  // Generic to user
}

// Global exception handler
AppDomain.CurrentDomain.UnhandledException += (sender, e) => {
    Logger.Fatal(e.ExceptionObject as Exception);
    // Show generic error, don't expose exception details
};

Application.Current.DispatcherUnhandledException += (sender, e) => {
    Logger.Error(e.Exception);
    e.Handled = true;
    // Show generic error dialog
};
```

### 8. Secure Updates

```
// Use Squirrel, MSIX, or ClickOnce for secure updates

// Squirrel.Windows
using Squirrel;
using (var manager = await UpdateManager.GitHubRelease("owner", "repo")) {
    var updates = await manager.CheckForUpdate();
    if (updates.ReleasesToApply.Any()) {
        await manager.UpdateApp();
        // Code-signed updates verified automatically
    }
}

// MSIX (modern Windows packaging)
// Automatically handles updates, code signing, and sandboxing
// Use Windows.Management.Deployment for programmatic updates
```

---

## References

- .NET Security Guide: https://learn.microsoft.com/en-us/dotnet/standard/security/
- Windows Security Baselines: https://learn.microsoft.com/en-us/windows/security/
