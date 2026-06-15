# React Native Security — Deep Module

## Scope

React Native-specific security: Hermes, bridge/JSI security, secure storage, AsyncStorage risks, and native module security.

---

## React Native Security Rules

### 1. Secure Storage

```
RULE: NEVER use AsyncStorage for sensitive data.

AsyncStorage:
- Unencrypted plain text (SQLite on Android, plist on iOS)
- Accessible on rooted/jailbroken devices
- Use ONLY for non-sensitive preferences (theme, language, onboarding state)

USE react-native-keychain:
import * as Keychain from 'react-native-keychain';

// Store
await Keychain.setGenericPassword('authToken', tokenValue, {
  accessible: Keychain.ACCESSIBLE.WHEN_UNLOCKED_THIS_DEVICE_ONLY,
  securityLevel: Keychain.SECURITY_LEVEL.SECURE_HARDWARE,
});

// Retrieve
const credentials = await Keychain.getGenericPassword();
if (credentials) { const token = credentials.password; }

// Delete
await Keychain.resetGenericPassword();

OR use react-native-sensitive-info or expo-secure-store (Expo):
import * as SecureStore from 'expo-secure-store';
await SecureStore.setItemAsync('token', value);
```

### 2. Hermes Engine Security

```
Hermes compiles JavaScript to bytecode:
- Bytecode is NOT source code but CAN be reversed
- Hermes bytecode is easier to decompile than V8 bytecode
- Tools exist: hbctool, hermes-dec

Protection:
- NEVER embed secrets in JavaScript code (even with Hermes)
- Use server-side logic for sensitive operations
- Enable Hermes in release (better performance, slight obfuscation)
- Use react-native-obfuscating-transformer for additional obfuscation
- ProGuard/R8 only obfuscates Java/Kotlin, not JavaScript

// metro.config.js — obfuscation (community tools)
// Use javascript-obfuscator with metro transformer
```

### 3. Bridge / JSI Security

```
RULE: Validate all data crossing the native bridge.

Native modules receive data from JavaScript — treat as untrusted:

// Android native module (Kotlin)
@ReactMethod
fun processPayment(amount: Double, token: String, promise: Promise) {
  if (amount <= 0 || amount > 999999) {
    promise.reject("INVALID", "Invalid amount")
    return
  }
  if (!isValidToken(token)) {
    promise.reject("INVALID", "Invalid token")
    return
  }
  // Process...
}

// iOS native module (Swift)
@objc func processPayment(_ amount: NSNumber, token: String,
                           resolver: @escaping RCTPromiseResolveBlock,
                           rejecter: @escaping RCTPromiseRejectBlock) {
  guard amount.doubleValue > 0, amount.doubleValue < 999999 else {
    rejecter("INVALID", "Invalid amount", nil)
    return
  }
  // Process...
}

Turbo Modules / JSI:
- Same validation rules apply
- JSI calls are synchronous — be extra careful about blocking
- Type safety is better with Codegen but still validate values
```

### 4. Network Security

```
// Certificate pinning with react-native-ssl-pinning
import { fetch } from 'react-native-ssl-pinning';

const response = await fetch('https://api.example.com/data', {
  method: 'GET',
  sslPinning: {
    certs: ['cert1', 'cert2']  // .cer files in assets
  },
  headers: { Authorization: `Bearer ${token}` }
});

// Or use TrustKit (iOS) + OkHttp CertificatePinner (Android) via native modules

Platform network config:
- Android: network_security_config.xml (see Mobile_Android.md)
- iOS: ATS enabled by default (see Mobile_iOS.md)
```

### 5. Deep Link Security

```
// Validate deep link parameters
import { Linking } from 'react-native';

Linking.addEventListener('url', ({ url }) => {
  const parsed = new URL(url);

  // Validate origin/scheme
  if (!['myapp:', 'https:'].includes(parsed.protocol)) return;

  // Validate parameters
  const token = parsed.searchParams.get('token');
  if (token && !/^[a-zA-Z0-9]{64}$/.test(token)) return;

  // Route safely
  navigation.navigate('ResetPassword', { token });
});

// Use react-navigation deep linking with validation
const linking = {
  prefixes: ['myapp://', 'https://app.example.com'],
  config: {
    screens: {
      ResetPassword: 'reset/:token',
    },
  },
};
```

### 6. Debug & Release Security

```
// Remove console.log in production
// babel.config.js
module.exports = {
  plugins: [
    ...(process.env.NODE_ENV === 'production'
      ? ['transform-remove-console']
      : []),
  ],
};

// Detect debug mode
if (__DEV__) {
  // Development only code
}

// Detect emulator (react-native-device-info)
import DeviceInfo from 'react-native-device-info';
const isEmulator = await DeviceInfo.isEmulator();

// Prevent screenshots (Android)
// In MainActivity.java
getWindow().setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE);

// Prevent screenshots (iOS) — use react-native-prevent-screenshot
```

### 7. Dependency Security

```
RULE: React Native has a large dependency tree. Monitor it.

- Run npm audit / yarn audit regularly
- Use npx react-native-clean-project for clean builds
- Pin dependency versions (package-lock.json / yarn.lock)
- Audit native dependencies especially (they have full device access)
- Review permissions requested by native modules
- Keep React Native version updated (security patches)
- Use Dependabot / Renovate for automated updates
- Check native module popularity/maintenance before adopting
```

### 8. Expo-Specific Security

```
IF using Expo:

- Expo Go app: shared runtime — NEVER use for production
- Use expo-secure-store (not AsyncStorage) for secrets
- Use EAS Build for production builds (custom native code)
- OTA updates (expo-updates): verify update signatures
- Don't use Expo Go to demo sensitive features
- expo-auth-session for OAuth (secure redirect handling)
- expo-local-authentication for biometrics
```

---

## References

- React Native Security: https://reactnative.dev/docs/security
- OWASP MASVS: https://mas.owasp.org/MASVS/
