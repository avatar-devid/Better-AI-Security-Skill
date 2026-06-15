# Security — Mobile Applications

## Scope

This module covers mobile application security aligned with OWASP MASVS (Mobile Application Security Verification Standard): Android, iOS, Flutter, React Native, and cross-platform frameworks.

## Sub-Router

```
IF task contains [Android, Kotlin, Java Android, Android Studio, Gradle, APK, AAB, Play Store, Jetpack, Room, Retrofit, Keystore Android]
    LOAD modules/Mobile_Android.md

IF task contains [iOS, Swift, Objective-C, Xcode, UIKit, SwiftUI, Keychain, CocoaPods, SPM, App Store, TestFlight, Core Data]
    LOAD modules/Mobile_iOS.md

IF task contains [Flutter, Dart, pub.dev, Widget, Flutter Secure Storage, Platform Channel, BuildRunner]
    LOAD modules/Mobile_Flutter.md

IF task contains [React Native, Expo, Metro, React Navigation, AsyncStorage, Hermes, JSI, Native Module, Turbo Module]
    LOAD modules/Mobile_ReactNative.md
```

## Universal Mobile Security Rules (OWASP MASVS Aligned)

### 1. Data Storage (MASVS-STORAGE)

```
RULE: Mobile devices are easily lost/stolen. Protect stored data.

Secure storage:
- Credentials/tokens: Platform keychain (iOS Keychain, Android Keystore)
- Sensitive data: Encrypted database (SQLCipher, Realm encryption)
- Temporary data: Clear on app close or after timeout
- Cache: Never cache sensitive data or clear on background

NEVER store sensitive data in:
- SharedPreferences / UserDefaults (unencrypted)
- SQLite without encryption
- Application sandbox files (unencrypted)
- SD card / external storage (Android)
- Clipboard (accessible to other apps)
- Console logs
- Crash reports
- Analytics payloads
- URL cache (NSURLCache)
- Keyboard cache / autocomplete
- WebView cache / cookies
- Screenshot cache (task switcher)

Prevent screenshot in task switcher:
- iOS: Use overlayView in applicationWillResignActive
- Android: FLAG_SECURE on sensitive activities
```

### 2. Network Security (MASVS-NETWORK)

```
RULE: All network communication MUST be encrypted.

Checklist:
- Use HTTPS for ALL connections (no exceptions)
- Implement certificate pinning for critical APIs
  - Pin to public key hash (not certificate — allows rotation)
  - Include backup pin(s)
  - Implement pin expiry and emergency bypass mechanism
- Configure Network Security Config (Android)
  - Block cleartext traffic: cleartextTrafficPermitted="false"
- Configure App Transport Security (iOS)
  - NSAllowsArbitraryLoads: false
  - Enable NSExceptionRequiresForwardSecrecy
- Validate certificates properly (never disable validation)
- Handle certificate errors — fail closed (block connection)
- Use TLS 1.2 minimum (prefer TLS 1.3)

Certificate pinning libraries:
- iOS: TrustKit, Alamofire with ServerTrustManager
- Android: OkHttp CertificatePinner, Network Security Config
- Flutter: http_certificate_pinning
- React Native: react-native-ssl-pinning
```

### 3. Authentication (MASVS-AUTH)

```
RULE: Mobile authentication has unique challenges. Address them.

Biometric authentication:
- Use platform APIs (BiometricPrompt Android, LAContext iOS)
- Bind biometric auth to cryptographic key (not just boolean check)
- Require biometric re-enrollment if biometric data changes
- Provide fallback to PIN/password
- Set timeout on biometric session (5-15 minutes)

Token management:
- Store tokens in secure storage (Keychain/Keystore)
- Use short-lived access tokens + refresh tokens
- Refresh tokens silently in background
- Clear tokens on logout
- Implement token rotation on every refresh
- Handle token expiry gracefully (redirect to login, don't crash)

Session handling:
- Set session timeout appropriate for mobile (30-60 minutes)
- Re-authenticate for sensitive operations
- Lock app after idle timeout (require biometric/PIN)
- Handle background/foreground transitions securely
```

### 4. Binary Protection (MASVS-RESILIENCE)

```
RULE: Mobile apps can be decompiled. Protect accordingly.

Code protection:
- Enable code obfuscation (ProGuard/R8 for Android, Bitcode for iOS)
- Strip debug symbols from release builds
- Never hard-code secrets in source code
- Use server-side validation for all business logic
- Implement root/jailbreak detection
- Implement debugger detection
- Implement integrity checks (tamper detection)
- Implement emulator detection

Root/Jailbreak detection:
- Check for common root indicators (su binary, Cydia, Magisk)
- Use SafetyNet/Play Integrity API (Android)
- Use DeviceCheck / App Attest (iOS)
- Implement multi-layered detection (not just single check)
- Decide policy: block, warn, or restrict features

NOTE: All client-side protections can be bypassed by a determined attacker.
      Never rely solely on client-side checks for security. Always validate server-side.
```

### 5. Secure Communication (MASVS-PLATFORM)

```
RULE: Secure inter-app and platform communication.

Deep links / Universal links:
- Validate all deep link parameters
- Never auto-authenticate via deep link
- Use Universal Links (iOS) / App Links (Android) — verified domain
- Sanitize data received from deep links
- Don't navigate to arbitrary URLs from deep links

Intent security (Android):
- Use explicit intents for internal communication
- Set exported="false" for non-public components
- Validate intent extras
- Use permissions for sensitive broadcast receivers
- Use PendingIntent.FLAG_IMMUTABLE

URL schemes (iOS):
- Prefer Universal Links over custom URL schemes
- Validate all URL scheme parameters
- Don't transmit sensitive data via URL schemes

Inter-app data sharing:
- Use Content Providers with proper permissions (Android)
- Use App Groups with minimum data (iOS)
- Encrypt shared data
- Validate data from other apps
```

### 6. Secure Data Transmission

```
RULE: Protect data in transit beyond just TLS.

- Don't send sensitive data in URL parameters (logged in server, proxy, browser history)
- Use request body for sensitive data (POST/PUT)
- Implement request signing for API calls (HMAC)
- Add timestamp to prevent replay attacks
- Use request nonces for critical operations
- Compress and encrypt large payloads
- Implement response validation (verify server signatures if applicable)
```

### 7. WebView Security (if used)

```
IF the mobile app uses WebView:

RULE: WebView is a browser inside your app. Treat it as untrusted.

Checklist:
- Disable JavaScript if not needed
- If JavaScript needed, restrict to trusted content only
- Disable file access (setAllowFileAccess(false) on Android)
- Validate all URLs before loading
- Intercept navigation and block untrusted domains
- Don't expose native functions to WebView unless absolutely necessary
- If exposing native functions, validate all inputs from JavaScript
- Use WKWebView (iOS), not UIWebView (deprecated)
- Disable local storage and caches for sensitive content
- Clear WebView data on logout
```

### 8. Push Notification Security

```
RULE: Push notifications can leak sensitive data.

- Never include sensitive data in push notification payload
  (visible on lock screen, in notification center, logged by OS)
- Use "silent" notifications to trigger background data fetch
- Validate push notification origin (verify signature)
- Encrypt notification payload if sensitive (end-to-end)
- Allow users to disable sensitive notification content
- Don't include tokens or secrets in push payloads
- Validate notification registration with server
```

### 9. Secure Build & Release

```
RULE: Secure the build pipeline for mobile apps.

Build security:
- Use reproducible builds when possible
- Sign release builds with production certificates
- Strip debug logs from release builds
- Remove test/debug code paths from release
- Use build variants/flavors for different environments
- Never ship debug builds to production

Release security:
- App Store / Play Store review compliance
- Code signing verification
- Metadata review (no secrets in app description, screenshots)
- Version management (no downgrade attacks)
- Staged rollout for risk mitigation
```

### 10. Offline Security

```
RULE: Mobile apps often work offline. Secure offline mode.

- Enforce session timeout even offline
- Encrypt all offline data
- Queue sensitive operations for online sync (don't process locally)
- Validate offline data when syncing back to server
- Handle sync conflicts securely (server wins for security-critical data)
- Clear offline cache periodically
- Limit amount of data available offline
```

### 11. Third-Party SDK Security

```
RULE: Third-party SDKs run with your app's permissions.

- Audit all third-party SDKs before inclusion
- Review SDK permissions (do they need camera, location, contacts?)
- Monitor SDK network traffic (what data are they sending?)
- Keep SDKs updated (security patches)
- Remove unused SDKs
- Use SDK privacy manifests (iOS Privacy Manifest)
- Declare data collection practices (App Store Privacy Labels, Play Data Safety)
- Consider SDK supply chain attacks (pin SDK versions, verify checksums)
```

### 12. Privacy

```
RULE: Mobile platforms have strong privacy requirements.

Checklist:
- Request permissions at point of use (not on launch)
- Explain why each permission is needed
- Handle permission denial gracefully
- Implement data minimization (collect only what's needed)
- Provide data export / deletion capability (GDPR, CCPA)
- Implement analytics opt-out
- Review App Tracking Transparency (iOS ATT)
- Complete Privacy Labels / Data Safety section accurately
- Handle location data with extra care (precise vs. approximate)
```
