# Path Traversal — Deep Module

## Threat Description

Path traversal (directory traversal) allows attackers to access files outside the intended directory by manipulating file paths with sequences like `../`.

**CWE**: CWE-22 (Improper Limitation of a Pathname to a Restricted Directory)

---

## Attack Patterns

```
Basic:           ../../../etc/passwd
Windows:         ..\..\..\windows\system32\config\sam
URL encoded:     %2e%2e%2f%2e%2e%2fetc%2fpasswd
Double encoded:  %252e%252e%252f
Null byte:       ../../../etc/passwd%00.jpg  (bypass extension check)
Dot segments:    ....//....//etc/passwd  (bypass ../ filter)
Mixed slashes:   ..\/..\/etc/passwd
Unicode:         %c0%ae%c0%ae/etc/passwd  (overlong UTF-8)
```

## Prevention

```
1. NEVER use user input directly in file paths
2. Use path.resolve() and verify result starts with base directory
3. Use a file ID → path mapping (user never sees real paths)
4. Reject paths containing: .., \0, ~, and non-printable characters
5. Normalize path before validation (resolve symlinks)
6. Use chroot/sandbox for file operations

// Node.js
const safePath = path.resolve(BASE_DIR, userInput);
if (!safePath.startsWith(path.resolve(BASE_DIR) + path.sep)) {
  throw new Error('Path traversal');
}

// Python
safe_path = os.path.realpath(os.path.join(BASE_DIR, user_input))
if not safe_path.startswith(os.path.realpath(BASE_DIR) + os.sep):
    raise ValueError("Path traversal")
```

---

## References

- OWASP Path Traversal: https://owasp.org/www-community/attacks/Path_Traversal
- CWE-22: https://cwe.mitre.org/data/definitions/22.html
