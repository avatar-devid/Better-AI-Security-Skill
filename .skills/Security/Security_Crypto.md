# Security — Cryptography

## Scope

This module covers cryptographic operations: encryption, decryption, hashing, digital signatures, key management, and secure random number generation.

## Sub-Router

```
IF task contains [AES, ChaCha20, Symmetric Encryption, Encrypt Data, Decrypt Data, IV, Nonce, GCM, CBC, Key Derivation, KDF, PBKDF2]
    LOAD modules/Crypto_Symmetric.md

IF task contains [RSA, ECDSA, Ed25519, Asymmetric, Public Key, Private Key, Key Pair, Certificate, X.509, PKI, Key Exchange, Diffie-Hellman, ECDH]
    LOAD modules/Crypto_Asymmetric.md

IF task contains [Hash, SHA, SHA-256, SHA-512, HMAC, bcrypt, argon2, scrypt, Checksum, Integrity, Fingerprint, Digest, Password Hashing]
    LOAD modules/Crypto_Hashing.md
```

## Universal Cryptography Rules

### 1. Never Roll Your Own Crypto

```
ABSOLUTE RULE: Use established, audited cryptographic libraries.

Recommended libraries:
- Node.js: built-in crypto, libsodium (sodium-native), jose (JWT)
- Python: cryptography, PyNaCl, hashlib, secrets
- Java: JCA/JCE, Bouncy Castle, Google Tink
- C#: System.Security.Cryptography, NSec, Bouncy Castle
- Go: crypto/*, golang.org/x/crypto
- Rust: ring, RustCrypto, sodiumoxide
- PHP: sodium (built-in), openssl

NEVER:
- Implement your own encryption algorithm
- Implement your own hash function
- Implement your own key derivation function
- Implement your own random number generator
- Use XOR "encryption" in production
- Use base64 as "encryption"
```

### 2. Algorithm Selection

```
RULE: Use modern, standard algorithms. Reject deprecated ones.

✓ APPROVED algorithms:
- Symmetric encryption: AES-256-GCM, ChaCha20-Poly1305, XChaCha20-Poly1305
- Asymmetric encryption: RSA-OAEP (2048+ bits), ECIES
- Digital signatures: Ed25519, ECDSA (P-256, P-384), RSA-PSS (2048+ bits)
- Hashing: SHA-256, SHA-384, SHA-512, SHA-3, BLAKE2b, BLAKE3
- Password hashing: Argon2id, bcrypt, scrypt
- Key derivation: HKDF, PBKDF2 (with high iterations)
- MAC: HMAC-SHA256, Poly1305
- Key exchange: X25519, ECDH (P-256)

✗ BANNED algorithms (insecure):
- DES, 3DES, RC4, Blowfish
- MD5, SHA-1 (for security purposes)
- RSA < 2048 bits
- ECB mode (for any cipher)
- CBC without HMAC (unauthenticated encryption)
- PKCS#1 v1.5 padding (for encryption)
- Raw RSA without proper padding
```

### 3. Secure Random Number Generation

```
RULE: Use CSPRNG for ALL security-sensitive random values.

Use cases requiring CSPRNG:
- Session IDs
- Tokens (reset, verification, API keys)
- Encryption keys
- IVs / Nonces
- Salt values
- CSRF tokens
- Password generation
- Any value that must be unpredictable

CSPRNG sources:
- Node.js: crypto.randomBytes(), crypto.randomUUID()
- Python: secrets.token_bytes(), secrets.token_urlsafe()
- Java: SecureRandom
- C#: RandomNumberGenerator.GetBytes()
- Go: crypto/rand.Read()
- Browser: crypto.getRandomValues()

NEVER use for security:
- Math.random() (JavaScript)
- random.random() (Python)
- java.util.Random (Java)
- System.Random (C#)
- time-based seeds
```

### 4. Key Management

```
RULE: Keys are the crown jewels. Protect them accordingly.

Key lifecycle:
1. Generation: Use CSPRNG, appropriate key size
2. Storage: Hardware Security Module (HSM), KMS, or encrypted at rest
3. Distribution: Secure channels only (TLS, pre-shared)
4. Rotation: Regular schedule (90 days for symmetric, 1-2 years for asymmetric)
5. Revocation: Immediate on compromise suspicion
6. Destruction: Secure wipe, log the event

NEVER:
- Hard-code keys in source code
- Store keys in version control
- Store keys in plain text files
- Store keys in environment variables (acceptable for non-critical, use KMS for critical)
- Log keys
- Transmit keys over unencrypted channels
- Reuse keys across environments (dev/staging/prod)

Key storage options (most to least secure):
1. Hardware Security Module (HSM) — FIPS 140-2 Level 3
2. Cloud KMS (AWS KMS, GCP Cloud KMS, Azure Key Vault)
3. HashiCorp Vault
4. Encrypted config with key from KMS
5. OS-level keychain (macOS Keychain, Windows DPAPI)
```

### 5. Encryption Modes

```
RULE: Always use authenticated encryption (AEAD).

AEAD modes (encrypt + integrity):
- AES-256-GCM (most common, hardware accelerated)
- ChaCha20-Poly1305 (excellent for software, mobile)
- XChaCha20-Poly1305 (extended nonce, safer for random nonces)

NEVER use unauthenticated encryption:
- AES-ECB (reveals patterns)
- AES-CBC without MAC (malleable)
- AES-CTR without MAC (malleable)
- Any stream cipher without MAC

Nonce/IV rules:
- GCM: 12-byte nonce, MUST be unique per key (counter or random)
- ChaCha20-Poly1305: 12-byte nonce, unique per key
- XChaCha20-Poly1305: 24-byte nonce, safe to use random
- NEVER reuse nonce with same key (catastrophic for GCM and CTR)
- For random nonces: track usage count, rotate key before 2^32 messages (GCM)
```

### 6. Envelope Encryption

```
RULE: For data encryption, use envelope encryption pattern.

Pattern:
1. Generate a Data Encryption Key (DEK) — random AES-256 key
2. Encrypt data with DEK
3. Encrypt DEK with Key Encryption Key (KEK) stored in KMS
4. Store: encrypted_data + encrypted_DEK + metadata
5. To decrypt: decrypt DEK with KEK, then decrypt data with DEK

Benefits:
- Can rotate KEK without re-encrypting all data
- Can use HSM/KMS for KEK without sending all data to it
- Each data item can have unique DEK
- Easy key rotation and access revocation
```

### 7. Cryptographic Comparison

```
RULE: Use constant-time comparison for all security-sensitive comparisons.

Vulnerable to timing attacks:
- Token comparison (API keys, session IDs, HMAC digests)
- Password hash comparison (handled by bcrypt/argon2)
- Signature verification

Constant-time functions:
- Node.js: crypto.timingSafeEqual()
- Python: hmac.compare_digest()
- Java: MessageDigest.isEqual()
- C#: CryptographicOperations.FixedTimeEquals()
- Go: subtle.ConstantTimeCompare()
```

### 8. Data Integrity

```
RULE: Use HMAC or digital signatures for data integrity verification.

HMAC (symmetric — shared secret):
- Use for API request signing
- Use for webhook payload verification
- Use for tamper detection on stored data
- Algorithm: HMAC-SHA256 minimum

Digital signatures (asymmetric — public/private key):
- Use for non-repudiation
- Use for software updates / code signing
- Use for document signing
- Algorithm: Ed25519, ECDSA P-256, or RSA-PSS 2048+
```

### 9. Certificate Management

```
IF the application uses TLS certificates:

- Use automated certificate management (Let's Encrypt, ACME)
- Monitor certificate expiry (alert 30 days before)
- Use certificate pinning for mobile apps (with backup pins)
- Validate certificate chain (do not disable verification)
- Use OCSP stapling for revocation checking
- Keep private keys secure (600 permissions, root-owned)
- Separate certificates per environment
```

### 10. Cryptographic Deprecation Plan

```
RULE: Have a plan for algorithm migration.

When an algorithm is deprecated:
1. Identify all usage points
2. Implement new algorithm alongside old (dual support)
3. Re-encrypt/re-sign data with new algorithm (batch migration)
4. Verify migration completeness
5. Remove old algorithm support
6. Update all documentation

Store algorithm identifier with encrypted data:
{
  "algorithm": "AES-256-GCM",
  "version": 2,
  "key_id": "key-2024-01",
  "ciphertext": "...",
  "nonce": "...",
  "tag": "..."
}
This allows migrating to a new algorithm without breaking existing data.
```
