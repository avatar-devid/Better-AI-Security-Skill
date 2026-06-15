# Android Security — Deep Module

## Scope

Android-specific security: Keystore, data storage, network security config, intent security, root detection, and ProGuard/R8 obfuscation.

---

## Android Security Rules

### 1. Android Keystore

```
RULE: Use Android Keystore for all cryptographic keys and sensitive data.

// Generate key in Keystore
val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
keyGenerator.init(
    KeyGenParameterSpec.Builder("myKey", KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
        .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
        .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
        .setUserAuthenticationRequired(true)  // Require biometric
        .setUserAuthenticationValidityDurationSeconds(300)
        .build()
)
val key = keyGenerator.generateKey()

Properties:
- Keys stored in hardware-backed secure element (if available)
- Keys never leave the Keystore (all operations happen inside)
- Can require biometric authentication for key use
- Survives app uninstall only if setIsStrongBoxBacked(true)
```

### 2. Data Storage

```
SECURE storage options:
✓ EncryptedSharedPreferences (Jetpack Security):
  val masterKey = MasterKey.Builder(context)
      .setKeyScheme(MasterKey.KeyScheme.AES256_GCM).build()
  val prefs = EncryptedSharedPreferences.create(context, "secret_prefs", masterKey,
      EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
      EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM)

✓ EncryptedFile (Jetpack Security):
  val encryptedFile = EncryptedFile.Builder(context, file, masterKey,
      EncryptedFile.FileEncryptionScheme.AES256_GCM_HKDF_4KB).build()

✓ Room with SQLCipher (encrypted database)

INSECURE storage:
✗ SharedPreferences (plain text XML in app sandbox)
✗ SQLite without encryption
✗ External storage (SD card — world-readable)
✗ Internal storage files without encryption (accessible on rooted devices)

NEVER store in plain text:
- Tokens, API keys, passwords
- PII (names, emails, phone numbers)
- Financial data
- Health data
```

### 3. Network Security Configuration

```
// res/xml/network_security_config.xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <!-- Block all cleartext traffic -->
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>

    <!-- Certificate pinning for API -->
    <domain-config>
        <domain includeSubdomains="true">api.example.com</domain>
        <pin-set expiration="2025-01-01">
            <pin digest="SHA-256">BASE64_ENCODED_HASH=</pin>
            <pin digest="SHA-256">BACKUP_PIN_HASH=</pin>
        </pin-set>
    </domain-config>

    <!-- Debug-only: allow cleartext for local development -->
    <debug-overrides>
        <trust-anchors>
            <certificates src="user" />
        </trust-anchors>
    </debug-overrides>
</network-security-config>

// AndroidManifest.xml
<application android:networkSecurityConfig="@xml/network_security_config">
```

### 4. Component Security

```
// AndroidManifest.xml — exported components
<activity android:name=".AdminActivity" android:exported="false" />
<receiver android:name=".SensitiveReceiver" android:exported="false" />
<provider android:name=".DataProvider"
    android:exported="true"
    android:permission="com.example.READ_DATA"
    android:readPermission="com.example.READ_DATA"
    android:writePermission="com.example.WRITE_DATA" />
<service android:name=".BackgroundService" android:exported="false" />

Rules:
- Set exported="false" for internal components
- Use custom permissions for exported components
- Validate all Intent extras (type check, sanitize)
- Use explicit intents for internal communication
- Use PendingIntent.FLAG_IMMUTABLE for PendingIntents
```

### 5. WebView Security

```
webView.settings.apply {
    javaScriptEnabled = false  // Enable only if absolutely necessary
    allowFileAccess = false
    allowFileAccessFromFileURLs = false
    allowUniversalAccessFromFileURLs = false
    allowContentAccess = false
    domStorageEnabled = false  // Enable only if needed
}

// Restrict navigation
webView.webViewClient = object : WebViewClient() {
    override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
        val url = request.url.toString()
        return !url.startsWith("https://trusted.example.com")
    }
}

// If using JavaScript interface
@JavascriptInterface  // Only annotated methods are exposed
fun safeMethod(input: String): String {
    val sanitized = sanitize(input)  // Validate ALL input
    return processedResult
}
```

### 6. Root Detection

```
Checks (layered — don't rely on a single check):
- Check for su binary: File("/system/xbin/su").exists()
- Check for Magisk: File("/sbin/.magisk").exists()
- Check build tags: Build.TAGS?.contains("test-keys")
- Check for root management apps (Magisk Manager, SuperSU)
- Use SafetyNet/Play Integrity API (server-side verification)

// Play Integrity API (recommended)
val integrityManager = IntegrityManagerFactory.create(context)
val request = IntegrityTokenRequest.builder()
    .setNonce(generateNonce())
    .build()
val token = integrityManager.requestIntegrityToken(request).await()
// Send token to server for verification

Policy options on root detection:
A. Block app entirely (banking apps)
B. Disable sensitive features (payment, biometric)
C. Show warning and continue (most apps)
D. Log and monitor (analytics)
```

### 7. ProGuard / R8 Obfuscation

```
// proguard-rules.pro
-keepattributes SourceFile,LineNumberTable  # Keep for crash reports
-renamesourcefileattribute SourceFile

# Don't obfuscate model classes (serialization)
-keep class com.example.model.** { *; }

# Keep Retrofit/API interfaces
-keep interface com.example.api.** { *; }

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static int d(...);
    public static int v(...);
}

Enable in build.gradle:
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

### 8. Biometric Authentication

```
val biometricPrompt = BiometricPrompt(this, executor,
    object : BiometricPrompt.AuthenticationCallback() {
        override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
            val cipher = result.cryptoObject?.cipher
            // Use the authenticated cipher to decrypt data
            // This binds biometric auth to a cryptographic operation
        }
    })

val promptInfo = BiometricPrompt.PromptInfo.Builder()
    .setTitle("Verify identity")
    .setNegativeButtonText("Use password")
    .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
    .build()

// Bind to crypto operation (not just boolean check)
val cipher = getCipher()
cipher.init(Cipher.DECRYPT_MODE, getKeyFromKeystore())
biometricPrompt.authenticate(promptInfo, BiometricPrompt.CryptoObject(cipher))

RULE: Always bind biometric auth to a CryptoObject. A boolean-only check can be bypassed.
```

---

## References

- Android Security Best Practices: https://developer.android.com/topic/security/best-practices
- OWASP MASVS: https://mas.owasp.org/MASVS/
