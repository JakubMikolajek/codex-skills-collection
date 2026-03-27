---
name: security-hardening
description: Security review and hardening patterns for production backend systems. Covers OWASP Top 10, authentication and authorization patterns, secrets management, input validation, security headers, and API security. Use before any backend code ships to production, during security-focused code review, or when a task involves auth, user data, file handling, or external API integration.
---

# Security Hardening

This skill enforces structured security analysis before code reaches production. It covers the most common vulnerabilities found in backend systems and provides concrete mitigation patterns per category.

## When to Use

- Any backend feature that handles user input, file uploads, or external data
- Any task involving authentication, authorization, sessions, or tokens
- Code review with a security focus (`/review` + security scope)
- Before deploying a new API endpoint, service, or integration to production
- When the codebase is new and no security baseline has been established

## When NOT to Use

- Pure frontend UI tasks with no backend interaction
- Infrastructure configuration reviewed separately under a dedicated infra checklist
- Internal tooling with no external network exposure and no user data

## Core Principle

**Assume breach at every boundary.** Every input is hostile, every token is potentially stolen, every dependency is potentially compromised. Security is not a final step — it is a constraint on every design decision.

## Security Hardening Process

Use the checklist below and track progress:

```
Security hardening progress:
- [ ] Step 1: Inventory trust boundaries and data flows
- [ ] Step 2: Audit authentication and authorization
- [ ] Step 3: Validate input handling and injection surface
- [ ] Step 4: Review secrets and credential management
- [ ] Step 5: Check security headers and transport
- [ ] Step 6: Verify dependency and supply chain hygiene
- [ ] Step 7: Produce Security Review output
```

**Step 1: Inventory trust boundaries and data flows**

Map every point where untrusted data enters the system:
- HTTP request bodies, query params, headers, cookies
- File upload content and filenames
- Webhook payloads from third parties
- Data read from external APIs or message queues
- Data read from the database that originated from user input

For each entry point, verify: who validates it, where, and how failures are handled.

**Step 2: Audit authentication and authorization**

Authentication (who are you):
- Token signatures verified cryptographically, not just decoded
- Token expiry (`exp`) checked explicitly
- Refresh token rotation implemented if long-lived sessions exist
- No credentials stored in localStorage — use httpOnly cookies or server-side sessions

Authorization (what are you allowed to do):
- Every route/handler has an explicit authorization check — no implicit "logged in = allowed"
- Object-level authorization: user A cannot access user B's resources by changing an ID
- Function-level authorization: low-privilege users cannot call admin endpoints by knowing the URL
- Authorization checked server-side, never trusted from client payload

**Step 3: Validate input handling and injection surface**

Injection (OWASP A03):
- SQL: use parameterized queries or ORM exclusively — no string concatenation into SQL
- Command injection: never pass user input to `exec`, `shell`, `spawn` without strict allowlist
- Path traversal: normalize and validate file paths, reject `../` sequences, use `path.resolve` + boundary check
- SSRF: if accepting URLs from users, validate against an allowlist of allowed hosts/schemes

Input validation:
- Validate shape, type, and length at the boundary — before any business logic
- Reject unexpected fields explicitly (strip unknown properties, do not silently pass them)
- Validate file uploads: MIME type (from content inspection, not filename), size limit, extension allowlist

XSS (OWASP A03 — frontend impact):
- Never render user content as raw HTML
- Set `Content-Type: application/json` explicitly on API responses
- Use `Content-Security-Policy` header (see Step 5)

**Step 4: Review secrets and credential management**

- No secrets in source code — no hardcoded API keys, passwords, tokens, or private keys
- No secrets in environment variable names that reveal their value (avoid `DB_PASSWORD=prod123`)
- Secrets loaded from environment or a secrets manager (Vault, AWS Secrets Manager, Doppler)
- `.env` files in `.gitignore` — verified, not assumed
- CI/CD secrets injected at runtime, not stored in repo or build artifacts
- JWT signing keys rotatable without service downtime
- Database passwords rotatable — connection pools handle graceful reconnection

Audit pattern: search for `password`, `secret`, `key`, `token`, `api_key` literals in source and committed config files.

**Step 5: Check security headers and transport**

Every HTTP response must include:

```
Content-Security-Policy: default-src 'self'; script-src 'self'; object-src 'none'
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=()
```

CORS:
- `Access-Control-Allow-Origin` must not be `*` for authenticated endpoints
- Allowed origins must be an explicit allowlist, not a regex match on user-controlled values
- Credentials (`withCredentials: true`) require explicit `Access-Control-Allow-Credentials: true` and a non-wildcard origin

Rate limiting:
- Authentication endpoints (login, register, password reset) must have rate limits
- Expensive compute or data endpoints must have rate limits
- Rate limits applied per IP and per user ID when authenticated

**Step 6: Verify dependency and supply chain hygiene**

- Run `npm audit`, `pip audit`, or `cargo audit` — zero high/critical CVEs before deployment
- Lockfile committed and pinned — no floating `^` ranges in production without lockfile
- Dependency count minimized — remove unused packages
- Docker base images pinned to digest or minor version, not `latest`
- No `eval`, `Function()`, or dynamic code execution from user-controlled strings

**Step 7: Produce Security Review output**

```markdown
## Security Review — [service/feature] — [date]

### Trust Boundaries
[Enumerated entry points and data flows]

### Findings
| Severity | Category | Location | Issue | Mitigation |
|---|---|---|---|---|
| CRITICAL | Injection | auth/login.ts:42 | Raw SQL concatenation | Use parameterized query |
| HIGH | AuthZ | api/documents.ts | Missing object-level auth | Add ownership check |
| MEDIUM | Secrets | .env.example | Real credentials committed | Rotate + remove |
| LOW | Headers | middleware/cors.ts | Wildcard CORS on auth routes | Restrict to allowlist |

### Verified Clean
[Areas reviewed and confirmed free of issues]

### Deferred
[Known issues accepted with documented reason and owner]
```

Severity definitions:
- **CRITICAL**: exploitable without authentication, leads to data breach or full compromise
- **HIGH**: exploitable by authenticated users, significant data exposure or privilege escalation
- **MEDIUM**: requires specific conditions, limited impact
- **LOW**: defense-in-depth improvement, no direct exploitability

## Security Review Checklist

```
Authentication:
- [ ] Tokens verified cryptographically (signature + expiry)
- [ ] No credentials in localStorage
- [ ] Refresh token rotation implemented

Authorization:
- [ ] Every endpoint has explicit authZ check
- [ ] Object-level: user cannot access other users' resources
- [ ] Function-level: privilege escalation by URL is impossible

Input:
- [ ] All external input validated at entry boundary
- [ ] SQL uses parameterized queries exclusively
- [ ] File uploads validated by content, not filename
- [ ] No path traversal possible

Secrets:
- [ ] No secrets in source code or committed config
- [ ] .env in .gitignore — confirmed
- [ ] CI secrets injected at runtime

Transport:
- [ ] Security headers present on all responses
- [ ] CORS allowlist is explicit, not wildcard on authenticated routes
- [ ] Rate limiting on auth endpoints

Dependencies:
- [ ] npm/pip/cargo audit passes with no high/critical CVEs
- [ ] Lockfile committed and up to date
```

## OWASP Top 10 Quick Reference

| OWASP ID | Category | Primary Mitigation |
|---|---|---|
| A01 | Broken Access Control | Object-level + function-level authZ on every endpoint |
| A02 | Cryptographic Failures | TLS everywhere, no secrets in code, verified token signatures |
| A03 | Injection | Parameterized queries, input validation at boundary, no dynamic eval |
| A04 | Insecure Design | Threat modeling at design phase, principle of least privilege |
| A05 | Security Misconfiguration | Security headers, no default credentials, no debug endpoints in prod |
| A06 | Vulnerable Components | Regular dependency audits, pinned versions |
| A07 | Authentication Failures | Rate limiting, secure token storage, rotation support |
| A08 | Software Integrity | Lockfiles, signed artifacts, no untrusted CDN scripts |
| A09 | Logging Failures | Log auth events, never log credentials or tokens |
| A10 | SSRF | URL allowlists, block internal ranges from user-supplied URLs |

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Security review as final step before deploy | Security constraints baked into design and review |
| `SELECT * FROM users WHERE id = '${userId}'` | Parameterized query or ORM |
| Trusting user-supplied `role` or `isAdmin` from JWT payload | Verify against database at request time |
| `Access-Control-Allow-Origin: *` on authenticated API | Explicit origin allowlist |
| Plain-text or reversibly encrypted passwords | One-way password hashing (`argon2` or `bcrypt`) with strong parameters |
| Hardcoded `SECRET_KEY = "dev-secret"` in source | Environment variable, fail fast if missing |
| Logging `Authorization: Bearer <token>` for debugging | Log presence/absence only, never token value |
| File path: `path.join(uploadDir, userFilename)` | `path.resolve` + check result starts with `uploadDir` |
| `npm install` without lockfile in CI | Commit lockfile, use `npm ci` |

## Connected Skills

- `code-review` — run security-hardening as part of every backend code review
- `api-contract` — API design decisions (auth scheme, input validation contract) are security decisions
- `technical-context-discovery` — discover existing security patterns before introducing new ones
- `nestjs` — NestJS-specific guards, interceptors, and validation pipe patterns
- `python-fastapi` — FastAPI-specific dependency injection for auth and exception handlers
- `sql-and-database` — parameterized queries, least-privilege DB users, migration safety
