# Asymmetric Encryption — Deep Module

## Scope

RSA, ECDSA, Ed25519, key exchange, digital signatures, certificate management, and PKI patterns.

---

## Algorithm Reference

### RSA

```
Key sizes:
- 2048 bits: Minimum acceptable (secure until ~2030)
- 3072 bits: Recommended for new systems
- 4096 bits: High security (slower but future-proof)

Encryption (RSA-OAEP):
- Use OAEP padding (NOT PKCS#1 v1.5 — padding oracle attacks)
- Hash: SHA-256 or SHA-384
- Max plaintext size: key_size - 2*hash_size - 2 bytes
- For large data: use hybrid encryption (RSA encrypts AES key, AES encrypts data)

Signatures (RSA-PSS):
- Use PSS padding (NOT PKCS#1 v1.5)
- Hash: SHA-256 minimum
- Salt length: hash length (default)

// Node.js — Generate RSA key pair
const { generateKeyPairSync } = require('crypto');
const { publicKey, privateKey } = generateKeyPairSync('rsa', {
  modulusLength: 4096,
  publicKeyEncoding: { type: 'spki', format: 'pem' },
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
});

// Sign
const sign = crypto.createSign('RSA-SHA256');
sign.update(data);
const signature = sign.sign({ key: privateKey, padding: crypto.constants.RSA_PKCS1_PSS_PADDING });

// Verify
const verify = crypto.createVerify('RSA-SHA256');
verify.update(data);
const isValid = verify.verify({ key: publicKey, padding: crypto.constants.RSA_PKCS1_PSS_PADDING }, signature);
```

### ECDSA (Elliptic Curve Digital Signature)

```
Curves:
- P-256 (secp256r1/prime256v1): NIST standard, widely supported, 128-bit security
- P-384 (secp384r1): Higher security (192-bit), slightly slower
- P-521 (secp521r1): Highest security (256-bit), rarely needed

Advantages over RSA:
- Smaller keys (256-bit ECDSA ≈ 3072-bit RSA security)
- Faster signature generation
- Smaller signatures
- Less bandwidth/storage

// Node.js
const { generateKeyPairSync } = require('crypto');
const { publicKey, privateKey } = generateKeyPairSync('ec', {
  namedCurve: 'P-256',
  publicKeyEncoding: { type: 'spki', format: 'pem' },
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
});

CRITICAL: ECDSA requires a unique random nonce (k) per signature.
If k is reused or predictable → private key can be extracted!
Use deterministic nonce (RFC 6979) or a library that handles this.
```

### Ed25519 (Recommended for Signatures)

```
Properties:
- EdDSA (Edwards-curve Digital Signature Algorithm)
- Fixed key size: 256 bits (32 bytes)
- Deterministic signatures (no random nonce — immune to nonce reuse attacks)
- Fast verification
- Small signatures (64 bytes)
- Simple API (less room for misconfiguration)

Use for:
- API request signing
- JWT signing (EdDSA algorithm)
- Software update signing
- Document signing
- Any new system where signature is needed

// Node.js
const { generateKeyPairSync, sign, verify } = require('crypto');
const { publicKey, privateKey } = generateKeyPairSync('ed25519');
const signature = crypto.sign(null, data, privateKey);
const isValid = crypto.verify(null, data, publicKey, signature);
```

### Key Exchange (X25519 / ECDH)

```
X25519 (Recommended):
- Curve25519-based Diffie-Hellman
- 256-bit keys
- Fast, constant-time implementation
- Used in TLS 1.3, Signal Protocol, WireGuard

ECDH (P-256):
- Elliptic Curve Diffie-Hellman
- NIST P-256 curve
- Widely supported

Flow:
1. Alice generates key pair (privateA, publicA)
2. Bob generates key pair (privateB, publicB)
3. Alice and Bob exchange public keys
4. Both compute: sharedSecret = DH(myPrivate, theirPublic)
5. Derive encryption key from shared secret using HKDF
6. Use derived key for symmetric encryption (AES-256-GCM)

RULE: Never use raw shared secret directly. Always derive key with HKDF.
RULE: Authenticate the key exchange (prevent MITM) — verify public keys.
```

---

## Key Management

### Key Storage

```
Storage options (most to least secure):
1. HSM (Hardware Security Module): FIPS 140-2/3, tamper-resistant
2. Cloud KMS (AWS KMS, GCP Cloud KMS, Azure Key Vault)
3. HashiCorp Vault: self-hosted secret management
4. OS keychain (macOS Keychain, Windows CNG/DPAPI, Linux kernel keyring)
5. Encrypted file with passphrase (emergency backup only)

RULE: Private keys MUST be encrypted at rest.
RULE: Private keys MUST have restricted file permissions (600 or more restrictive).
RULE: Private keys MUST NOT be in version control.
RULE: Private keys MUST NOT be logged or transmitted in plain text.
```

### Key Rotation

```
RULE: Implement key rotation for all asymmetric keys.

Rotation schedule:
- TLS certificates: 90 days (Let's Encrypt default) to 1 year
- Signing keys: 1-2 years (with overlap period)
- Encryption keys: 1-2 years

Rotation process:
1. Generate new key pair
2. Publish new public key (add to JWKS, trust store)
3. Start signing/encrypting with new key
4. Keep old key for verification/decryption during transition
5. After transition period: remove old public key
6. Securely destroy old private key

Tag encrypted data with key identifier:
  { "keyId": "key-2024-q3", "algorithm": "RSA-OAEP", "ciphertext": "..." }
```

---

## Hybrid Encryption Pattern

```
Problem: Asymmetric encryption is slow and has message size limits.
Solution: Encrypt data with symmetric key, encrypt symmetric key with asymmetric key.

Encrypt:
1. Generate random AES-256 key (DEK)
2. Encrypt data with AES-256-GCM using DEK
3. Encrypt DEK with recipient's RSA/ECDH public key
4. Package: encrypted_DEK + nonce + ciphertext + tag

Decrypt:
1. Decrypt DEK with recipient's private key
2. Decrypt data with AES-256-GCM using DEK

This is how PGP, TLS, and most encryption systems work.
```

---

## References

- NIST SP 800-56A (Key Establishment): https://csrc.nist.gov/publications/detail/sp/800-56a/rev-3/final
- RFC 8032 (Ed25519): https://tools.ietf.org/html/rfc8032
- RFC 7748 (X25519): https://tools.ietf.org/html/rfc7748
