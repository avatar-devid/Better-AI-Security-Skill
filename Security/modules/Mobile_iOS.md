# iOS Security — Deep Module

## Scope

iOS-specific security: Keychain, App Transport Security, data protection, jailbreak detection, and secure coding patterns.

---

## iOS Security Rules

### 1. Keychain Services

```
RULE: Use Keychain for all secrets (tokens, passwords, keys, certificates).

// Store in Keychain
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "authToken",
    kSecAttrService as String: "com.example.app",
    kSecValueData as String: tokenData,
    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
]
SecItemAdd(query as CFDictionary, nil)

// Retrieve from Keychain
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "authToken",
    kSecAttrService as String: "com.example.app",
    kSecReturnData as String: true
]
var result: AnyObject?
SecItemCopyMatching(query as CFDictionary, &result)

Accessibility levels (most to least restrictive):
- kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly  (requires passcode, this device)
- kSecAttrAccessibleWhenUnlockedThisDeviceOnly       (unlocked, this device)
- kSecAttrAccessibleWhenUnlocked                     (unlocked, syncs via iCloud)
- kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly   (after first unlock, this device)
- kSecAttrAccessibleAfterFirstUnlock                 (after first unlock, syncs)

RULE: Use "ThisDeviceOnly" variants for sensitive data (no iCloud sync).
RULE: Use kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly for highest security.
```

### 2. Data Protection

```
iOS Data Protection Classes (for files):

NSFileProtectionComplete:
  - Encrypted when device locked
  - Accessible only when device unlocked
  - Best for sensitive documents

NSFileProtectionCompleteUnlessOpen:
  - Can finish writing while locked
  - New reads require unlocked device

NSFileProtectionCompleteUntilFirstUserAuthentication:
  - Accessible after first unlock (even when locked)
  - Default for most apps
  - Suitable for background operations

// Set file protection
try data.write(to: fileURL, options: .completeFileProtection)

// Set via FileManager
try FileManager.default.setAttributes(
    [.protectionKey: FileProtectionType.complete],
    ofItemAtPath: filePath
)
```

### 3. App Transport Security (ATS)

```
RULE: Keep ATS enabled. Never disable it globally.

// Info.plist — default ATS (all HTTPS, TLS 1.2+, forward secrecy)
// No configuration needed — ATS is on by default

// If exceptions needed (e.g., third-party SDK with HTTP):
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>legacy-api.example.com</key>
        <dict>
            <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSTemporaryExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
        </dict>
    </dict>
</dict>

NEVER set NSAllowsArbitraryLoads to true in production.
App Store review may reject apps that disable ATS without justification.
```

### 4. Certificate Pinning

```
// Using TrustKit
TrustKit.initSharedInstance(withConfiguration: [
    kTSKSwizzleNetworkDelegates: false,
    kTSKPinnedDomains: [
        "api.example.com": [
            kTSKEnforcePinning: true,
            kTSKPublicKeyHashes: [
                "BASE64_HASH_OF_PUBLIC_KEY_1=",
                "BASE64_HASH_OF_PUBLIC_KEY_2="  // Backup pin
            ]
        ]
    ]
])

// Using URLSession delegate
func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    guard let serverTrust = challenge.protectionSpace.serverTrust,
          let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
        completionHandler(.cancelAuthenticationChallenge, nil)
        return
    }
    let serverKey = SecCertificateCopyKey(certificate)
    // Compare server key hash with pinned hash
}

RULE: Always include at least 2 pins (primary + backup).
RULE: Plan for pin rotation (emergency mechanism to update pins).
```

### 5. Jailbreak Detection

```
Detection checks (layered):
- Check for Cydia/Sileo: FileManager.default.fileExists(atPath: "/Applications/Cydia.app")
- Check for common paths: /private/var/lib/apt, /bin/bash, /usr/sbin/sshd
- Check sandbox integrity: try writing outside sandbox
- Check for dylib injection: _dyld_image_count() check
- Check for symbolic links: lstat on system directories
- Use App Attest (iOS 14+) for server-side integrity verification

// App Attest (server-side verification — strongest)
let service = DCAppAttestService.shared
if service.isSupported {
    service.generateKey { keyId, error in
        // Store keyId, use for attestation
        service.attestKey(keyId, clientDataHash: hash) { attestation, error in
            // Send attestation to server for verification
        }
    }
}

RULE: Jailbreak checks can be bypassed. Use for risk assessment, not absolute security.
RULE: Use App Attest for the strongest server-verified integrity.
```

### 6. Secure UI

```
// Prevent screenshot in task switcher
func applicationWillResignActive(_ application: UIApplication) {
    let blurEffect = UIBlurEffect(style: .light)
    let blurView = UIVisualEffectView(effect: blurEffect)
    blurView.frame = window?.frame ?? .zero
    blurView.tag = 999
    window?.addSubview(blurView)
}

func applicationDidBecomeActive(_ application: UIApplication) {
    window?.viewWithTag(999)?.removeFromSuperview()
}

// Disable text field caching (for sensitive inputs)
textField.autocorrectionType = .no
textField.autocapitalizationType = .none
textField.spellCheckingType = .no
textField.isSecureTextEntry = true  // For passwords

// Disable pasteboard for sensitive fields
override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    if action == #selector(paste(_:)) || action == #selector(copy(_:)) { return false }
    return super.canPerformAction(action, withSender: sender)
}
```

### 7. Biometric Authentication

```
let context = LAContext()
context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                        localizedReason: "Verify your identity") { success, error in
    if success {
        // Proceed — but bind to cryptographic operation
    }
}

RULE: Bind biometric auth to Keychain item access:
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "secureData",
    kSecAttrAccessControl as String: SecAccessControlCreateWithFlags(
        nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
        .biometryCurrentSet, nil
    )!
]
// Accessing this item will automatically prompt for biometric
```

### 8. Privacy

```
// Info.plist — purpose strings (required for permission prompts)
NSCameraUsageDescription: "We need camera access to scan QR codes"
NSPhotoLibraryUsageDescription: "We need photo access to upload your profile picture"
NSLocationWhenInUseUsageDescription: "We use your location to show nearby stores"

// Privacy Manifest (PrivacyInfo.xcprivacy — required since Spring 2024)
NSPrivacyAccessedAPITypes:
  - NSPrivacyAccessedAPICategoryUserDefaults (reason: CA92.1)
  - NSPrivacyAccessedAPICategoryFileTimestamp (reason: C617.1)

// Tracking Transparency (ATT)
ATTrackingManager.requestTrackingAuthorization { status in
    switch status {
    case .authorized: // Enable tracking
    default: // Disable tracking
    }
}
```

---

## References

- Apple Security Guide: https://support.apple.com/guide/security/
- OWASP MASVS iOS: https://mas.owasp.org/MASTG/iOS/
