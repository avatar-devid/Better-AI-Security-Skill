# RCE (Remote Code Execution) — Deep Module

## Threat Description

RCE allows an attacker to execute arbitrary code on the server. It is the most critical vulnerability class — full system compromise.

**CWE**: CWE-94 (Code Injection), CWE-78 (OS Command Injection)

---

## Common RCE Vectors

### 1. OS Command Injection

```
THREAT: User input passed to system commands.

VULNERABLE:
  // Node.js
  exec(`ping ${userInput}`);           // userInput: "8.8.8.8; rm -rf /"
  exec(`convert ${filename} output.png`); // filename: "file.jpg; cat /etc/passwd"

  // Python
  os.system(f"ping {user_input}")
  subprocess.call(f"ls {directory}", shell=True)

  // PHP
  system("ping " . $_GET['host']);

SAFE:
  // Node.js — use execFile (no shell interpretation)
  execFile('ping', ['-c', '4', userInput]);  // Arguments as array, no shell

  // Python — use list arguments, shell=False
  subprocess.run(['ping', '-c', '4', user_input], shell=False)

  // Better: avoid shell commands entirely — use language libraries
  // Instead of exec('ping'), use net.Socket or icmp library

RULE: NEVER use shell=True or exec() with user input.
RULE: NEVER concatenate user input into command strings.
RULE: Use array-based argument passing (no shell interpretation).
RULE: Prefer native libraries over shell commands.
```

### 2. Code Injection (eval)

```
THREAT: User input passed to code evaluation functions.

DANGEROUS functions:
  JavaScript: eval(), new Function(), setTimeout(string), setInterval(string)
  Python: eval(), exec(), compile()
  PHP: eval(), assert(), preg_replace with /e flag
  Ruby: eval(), send(), instance_eval()
  Java: ScriptEngine.eval(), Runtime.exec()

RULE: NEVER use eval() or equivalent with user input.
RULE: If dynamic code execution is needed, use a sandboxed environment (VM2, Pyodide, WASM).
```

### 3. Deserialization

```
THREAT: Deserializing untrusted data can execute arbitrary code.

Dangerous deserialization:
  Java: ObjectInputStream.readObject() — gadget chains → RCE
  Python: pickle.loads() — arbitrary code execution by design
  PHP: unserialize() — magic methods → RCE
  .NET: BinaryFormatter.Deserialize() — known RCE vector
  Ruby: Marshal.load() — code execution possible
  Node.js: node-serialize — known RCE via IIFE

SAFE alternatives:
  - Use JSON (no code execution, data only)
  - Use Protocol Buffers (schema-validated, no code execution)
  - Use MessagePack (data only)
  - If serialization needed: whitelist allowed classes
  - Java: use ObjectInputFilter (JEP 290)
  - .NET: use System.Text.Json (not BinaryFormatter)

RULE: NEVER deserialize untrusted data with native serialization.
RULE: Use data-only formats (JSON, Protobuf) for external data.
```

### 4. Template Injection (SSTI)

```
THREAT: User input rendered as template code.

VULNERABLE:
  // Python Jinja2
  template = Template(user_input)  // User controls template!
  // Attack: {{ config.__class__.__init__.__globals__['os'].popen('id').read() }}

  // Node.js Pug
  pug.render(userInput)  // User controls template!

  // Java Freemarker
  new Template("user", new StringReader(userInput), cfg)

SAFE:
  // Pass user input as DATA, not as TEMPLATE
  template = Template("Hello {{ name }}")
  template.render(name=user_input)  // User input is data, not code

RULE: User input is DATA, never TEMPLATE CODE.
RULE: If user-customizable templates are needed, use a sandboxed template engine (Liquid, Mustache — logic-less).
```

---

## Prevention Summary

```
1. Never pass user input to system commands, eval, or template engines as code
2. Use parameterized/array-based command execution
3. Prefer native libraries over shell commands
4. Never deserialize untrusted data with native serialization
5. Use sandboxed environments for dynamic code execution
6. Disable dangerous functions in production (eval, exec)
7. Apply least privilege — app should not run as root
8. Use WAF rules to detect common RCE patterns
9. Monitor for suspicious process execution (EDR)
10. Keep all dependencies updated (known RCE CVEs)
```

---

## References

- OWASP Command Injection: https://owasp.org/www-community/attacks/Command_Injection
- OWASP Code Injection: https://owasp.org/www-community/attacks/Code_Injection
- CWE-78: https://cwe.mitre.org/data/definitions/78.html
