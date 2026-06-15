# Flutter Security — Deep Module

## Scope

Flutter-specific security: secure storage, platform channels, obfuscation, network security, and Dart-specific patterns.

---

## Flutter Security Rules

### 1. Secure Storage

```
RULE: Use flutter_secure_storage for sensitive data.

// pubspec.yaml
dependencies:
  flutter_secure_storage: ^9.0.0

// Usage
final storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
await storage.write(key: 'auth_token', value: token);
final token = await storage.read(key: 'auth_token');
await storage.delete(key: 'auth_token');
await storage.deleteAll();  // On logout

Backed by:
- iOS: Keychain
- Android: EncryptedSharedPreferences / Keystore
- Web: NOT SECURE (uses localStorage) — handle differently for web

NEVER use:
- SharedPreferences for secrets (plain text)
- Hive without encryption for sensitive data
- Plain file storage for tokens
```

### 2. Platform Channel Security

```
RULE: Validate all data crossing the platform channel boundary.

// Dart side
final result = await platform.invokeMethod('sensitiveOperation', {
  'userId': userId,
  'action': action,
});

// Native side (Kotlin) — validate inputs
override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
  when (call.method) {
    "sensitiveOperation" -> {
      val userId = call.argument<String>("userId") ?: return result.error("INVALID", "Missing userId", null)
      val action = call.argument<String>("action") ?: return result.error("INVALID", "Missing action", null)
      // Validate userId format, action against whitelist
      if (!ALLOWED_ACTIONS.contains(action)) return result.error("INVALID", "Invalid action", null)
      // Process
    }
    else -> result.notImplemented()
  }
}

RULE: Whitelist allowed method names on native side.
RULE: Type-check all arguments.
RULE: Don't pass secrets through platform channels unless encrypted.
```

### 3. Network Security

```
// Certificate pinning with dio
final dio = Dio();
(dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
  final client = HttpClient();
  client.badCertificateCallback = (cert, host, port) {
    // Verify certificate fingerprint
    final fingerprint = sha256.convert(cert.der).toString();
    return pinnedFingerprints.contains(fingerprint);
  };
  return client;
};

// Or use http_certificate_pinning package
dependencies:
  http_certificate_pinning: ^2.0.0

RULE: Disable cleartext traffic (handled at platform level — Android network_security_config, iOS ATS).
```

### 4. Obfuscation

```
// Build with obfuscation
flutter build apk --obfuscate --split-debug-info=build/debug-info/
flutter build ios --obfuscate --split-debug-info=build/debug-info/

// Save debug info for crash report symbolication
// Store build/debug-info/ securely (needed to decode stack traces)

Additional measures:
- Remove debug prints in release: kReleaseMode check
  if (!kReleaseMode) print('Debug: $data');
- Use --dart-define for build-time configuration
  flutter build apk --dart-define=API_URL=https://api.prod.com
- Strip unused code: tree shaking is automatic in release builds
```

### 5. Secure Input

```
// Password field
TextField(
  obscureText: true,
  enableSuggestions: false,
  autocorrect: false,
  decoration: InputDecoration(labelText: 'Password'),
)

// Prevent screenshots on sensitive screens (Android)
// In MainActivity.kt
window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)

// Clear sensitive data from memory
// Dart strings are immutable — use Uint8List for sensitive data
final sensitiveData = Uint8List.fromList(utf8.encode(password));
// After use:
sensitiveData.fillRange(0, sensitiveData.length, 0);  // Zero out
```

### 6. Deep Link Security

```
// Validate deep link parameters
GoRouter(routes: [
  GoRoute(
    path: '/reset-password/:token',
    builder: (context, state) {
      final token = state.pathParameters['token'];
      // Validate token format before using
      if (token == null || !RegExp(r'^[a-zA-Z0-9]{64}$').hasMatch(token)) {
        return ErrorPage();
      }
      return ResetPasswordPage(token: token);
    },
  ),
]);

RULE: Never auto-authenticate via deep links.
RULE: Validate all deep link parameters (format, length, allowed characters).
RULE: Use uni_links or app_links package with verified domain (Android App Links, iOS Universal Links).
```

### 7. Web-Specific (Flutter Web)

```
IF deploying Flutter to web:

- flutter_secure_storage uses localStorage on web (NOT secure)
  → Use server-side sessions or HttpOnly cookies for web
- Dart code is compiled to JavaScript (viewable in browser)
  → NEVER embed secrets in Dart code
- Apply same web security rules (CSP, CORS, XSS prevention)
- Be cautious with dart:html — potential XSS via Element.innerHtml
  → Use Element.text instead for user content
```

---

## References

- Flutter Security: https://docs.flutter.dev/security
- OWASP MASVS: https://mas.owasp.org/MASVS/
