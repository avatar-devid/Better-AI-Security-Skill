# Symmetric Encryption — Deep Module

## Scope

AES, ChaCha20, key derivation, authenticated encryption modes, and practical implementation patterns.

---

## Algorithm Reference

### AES-256-GCM (Recommended Default)

```
Properties:
- Block cipher: 128-bit blocks
- Key size: 256 bits (32 bytes)
- Nonce: 12 bytes (96 bits) — MUST be unique per key
- Authentication tag: 16 bytes (128 bits)
- Mode: GCM (Galois/Counter Mode) — authenticated encryption (AEAD)

// Node.js
const crypto = require('crypto');
function encrypt(plaintext, key) {
  const nonce = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, nonce);
  const encrypted = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return Buffer.concat([nonce, tag, encrypted]);  // nonce|tag|ciphertext
}

function decrypt(data, key) {
  const nonce = data.subarray(0, 12);
  const tag = data.subarray(12, 28);
  const ciphertext = data.subarray(28);
  const decipher = crypto.createDecipheriv('aes-256-gcm', key, nonce);
  decipher.setAuthTag(tag);
  return Buffer.concat([decipher.update(ciphertext), decipher.final()]).toString('utf8');
}

// Python
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
key = AESGCM.generate_key(bit_length=256)
nonce = os.urandom(12)
aesgcm = AESGCM(key)
ciphertext = aesgcm.encrypt(nonce, plaintext, associated_data)
plaintext = aesgcm.decrypt(nonce, ciphertext, associated_data)

CRITICAL: Nonce reuse with the same key is CATASTROPHIC for GCM.
- Use a counter for nonces (guaranteed unique) OR
- Use random nonces but rotate key before 2^32 encryptions
```

### ChaCha20-Poly1305

```
Properties:
- Stream cipher + MAC
- Key: 256 bits (32 bytes)
- Nonce: 12 bytes (96 bits)
- No padding needed (stream cipher)
- Software-optimized (faster than AES without hardware acceleration)

Use when:
- Target hardware lacks AES-NI (mobile, embedded)
- Software-only performance matters
- Same security level as AES-256-GCM

XChaCha20-Poly1305 variant:
- Extended nonce: 24 bytes (192 bits)
- Safe to use random nonces (collision probability negligible)
- Preferred for systems where nonce management is difficult
```

### Key Derivation (KDF)

```
RULE: Derive encryption keys from passwords using a KDF. Never use passwords directly.

HKDF (derive key from strong key material):
  - Use when source is already high-entropy (e.g., Diffie-Hellman shared secret)
  - Fast, not designed for passwords

PBKDF2 (derive key from password):
  - Minimum 600,000 iterations for SHA-256 (OWASP 2023 recommendation)
  - Salt: 16+ random bytes
  - Output: 32 bytes (256 bits) for AES-256

Argon2 (derive key from password — best):
  - Use Argon2id variant
  - Memory: 64 MB+, iterations: 3+
  - Also suitable for key derivation (not just password hashing)

// Node.js PBKDF2
const key = crypto.pbkdf2Sync(password, salt, 600000, 32, 'sha256');

// Node.js HKDF
const derivedKey = crypto.hkdfSync('sha256', inputKey, salt, info, 32);
```

### Associated Data (AAD)

```
RULE: Use Associated Data to bind ciphertext to context.

AAD is authenticated but NOT encrypted. It prevents:
- Swapping ciphertext between different contexts
- Replay of encrypted data in wrong context

Example:
  const aad = Buffer.from(JSON.stringify({
    userId: 'user123',
    fieldName: 'ssn',
    version: 2
  }));

  // Encrypt with AAD
  cipher.setAAD(aad);

  // Decrypt with same AAD (must match or decryption fails)
  decipher.setAAD(aad);

Use AAD for:
- User ID (prevent one user's encrypted data being used for another)
- Field name (prevent swapping encrypted SSN into encrypted name field)
- Version (prevent using old encryption format)
- Timestamp range (prevent replay of old data)
```

---

## Practical Patterns

### Envelope Encryption

```
Pattern for encrypting data at scale:

1. Generate random DEK (Data Encryption Key): 32 random bytes
2. Encrypt data with DEK (AES-256-GCM)
3. Encrypt DEK with KEK (Key Encryption Key from KMS)
4. Store: encrypted_data + encrypted_DEK + nonce + metadata

Benefits:
- Rotate KEK without re-encrypting all data
- Each record can have unique DEK
- KEK stays in KMS (never in application memory for long)
- Fast key rotation (only re-encrypt DEKs)
```

### Searchable Encryption (Blind Index)

```
Problem: Encrypted data can't be searched (WHERE encrypted_email = ?).

Solution: Store a blind index alongside encrypted data.
  blind_index = HMAC-SHA256(field_value, search_key) → truncate to prevent rainbow table
  Store: { encrypted_email: "...", email_blind_index: "a1b2c3" }
  Search: WHERE email_blind_index = HMAC-SHA256(search_value, search_key)

Trade-off: Reveals equality (same input → same index) but not the actual value.
Truncate to reduce precision (e.g., first 16 bytes of HMAC → some false positives but more private).
```

---

## References

- NIST SP 800-38D (GCM): https://csrc.nist.gov/publications/detail/sp/800-38d/final
- libsodium documentation: https://doc.libsodium.org/
