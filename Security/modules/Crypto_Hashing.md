# Cryptographic Hashing — Deep Module

## Scope

Hash functions, HMAC, password hashing algorithms, integrity verification, and secure comparison.

---

## Hash Function Categories

### General-Purpose Hash Functions (Fast)

```
Use for: Data integrity, checksums, fingerprinting, deduplication, cache keys.
NOT for: Password hashing (too fast → brute-forceable).

✓ APPROVED:
- SHA-256 (32 bytes output, most common)
- SHA-384 (48 bytes output)
- SHA-512 (64 bytes output)
- SHA-3-256 / SHA-3-512 (Keccak-based, NIST standard)
- BLAKE2b (faster than SHA-256, equally secure)
- BLAKE3 (fastest, parallelizable, 256-bit security)

✗ BANNED:
- MD5 (broken — collisions found, never use for security)
- SHA-1 (broken — collisions demonstrated, deprecated)

// Node.js
const hash = crypto.createHash('sha256').update(data).digest('hex');

// Python
import hashlib
hash = hashlib.sha256(data).hexdigest()

// Go
hash := sha256.Sum256(data)
```

### HMAC (Hash-based Message Authentication Code)

```
Use for: Message authentication, API request signing, webhook verification, tamper detection.

HMAC = Hash(key, message) with specific construction that prevents length extension attacks.

// Node.js
const hmac = crypto.createHmac('sha256', secretKey).update(message).digest('hex');

// Python
import hmac
h = hmac.new(secret_key, message, hashlib.sha256).hexdigest()

// Verify with constant-time comparison
const isValid = crypto.timingSafeEqual(
  Buffer.from(computedHmac, 'hex'),
  Buffer.from(receivedHmac, 'hex')
);

Use cases:
- Webhook signature verification (Stripe, GitHub webhooks)
- API request signing (AWS Signature V4)
- Session token signing
- Cookie value integrity
- CSRF token generation (HMAC of session ID)

RULE: HMAC key must be at least as long as the hash output (32 bytes for HMAC-SHA256).
RULE: Use different HMAC keys for different purposes.
RULE: Always use constant-time comparison for HMAC verification.
```

### Password Hashing (Slow — by Design)

```
See modules/Password.md for full details.

Summary:
1. Argon2id (best — memory-hard, side-channel resistant)
2. bcrypt (good — battle-tested, 72-byte limit)
3. scrypt (good — memory-hard)
4. PBKDF2-SHA256 (acceptable — minimum 600,000 iterations)

RULE: Password hashing algorithms are intentionally slow.
      This is a feature, not a bug — it prevents brute force.
```

---

## Integrity Verification Patterns

### File Integrity

```
// Generate checksum
const hash = crypto.createHash('sha256');
const stream = fs.createReadStream(filePath);
stream.on('data', chunk => hash.update(chunk));
stream.on('end', () => console.log(hash.digest('hex')));

Use for:
- Verify downloaded files (compare with published hash)
- Detect file tampering (store hash, verify periodically)
- Deduplication (same hash = same content)
- Cache invalidation (content-based cache keys)

For tamper detection, use HMAC (not plain hash):
- Plain hash: attacker can modify file AND recompute hash
- HMAC: attacker needs the secret key to produce valid HMAC
```

### Data Integrity in Transit

```
Pattern: Sign data with HMAC before sending, verify on receipt.

Sender:
  const payload = JSON.stringify(data);
  const timestamp = Date.now();
  const signature = hmac(secretKey, `${timestamp}.${payload}`);
  // Send: { payload, timestamp, signature }

Receiver:
  // Verify timestamp (prevent replay — reject if > 5 minutes old)
  if (Date.now() - timestamp > 5 * 60 * 1000) reject();
  // Verify signature
  const expected = hmac(secretKey, `${timestamp}.${payload}`);
  if (!timingSafeEqual(expected, signature)) reject();
```

---

## Common Mistakes

```
1. Using MD5 or SHA-1 for security purposes
2. Using SHA-256 for password hashing (too fast)
3. Not using constant-time comparison for hash/HMAC verification
4. Comparing hashes as strings (timing attack)
5. Not including a salt (rainbow table attack)
6. Using the same key for HMAC and encryption
7. Hash without key for authentication (attacker can compute hash too)
8. Length extension attacks on SHA-256 (use HMAC, not hash(key+message))
9. Truncating hash output too much (collision probability increases)
10. Using hash for randomness (hash is deterministic, not random)
```

---

## References

- NIST FIPS 180-4 (SHA-2): https://csrc.nist.gov/publications/detail/fips/180/4/final
- NIST FIPS 202 (SHA-3): https://csrc.nist.gov/publications/detail/fips/202/final
- RFC 2104 (HMAC): https://tools.ietf.org/html/rfc2104
