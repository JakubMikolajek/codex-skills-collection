---
name: code-review
description: Perform code review. Quality analysis. Acceptance criteria verification. Best practices review. Includes security lens for backend code — covers OWASP Top 10 patterns, injection, auth/authZ, and secrets hygiene as part of every review.
---

# Code review

This skill helps you verify that the implemented code follows all best practices and quality standards.

## Code Review Process

Use the checklist below and track your progress:

```
Analysis progress:
- [ ] Step 1: Understand the task description
- [ ] Step 2: Understand the plan to implement task
- [ ] Step 3: Analyse the implemented solution and compare that to task description and implementation plan
- [ ] Step 4: Verify that solution has implemented all necessary tests
- [ ] Step 5: Run the available tests
- [ ] Step 6: Verify that solution follows the best practices
- [ ] Step 7: Run static code analysis tools and formatting tools
- [ ] Step 8: Validate the solution is secure
- [ ] Step 9: Validate the solution is scalable
```

**Step 1: Understand the task description**

Look for `*.research.md` file to fully understand the business goal of the task.
In case of task being connected to task management tool make sure to use that tool to access even more context.

In case of missing research file, follow the conversation to understand the goal.

**Step 2: Understand the plan to implement task**

Look for `*.plan.md` file to understand the planned solution implementation.

In case of missing it follow the conversation to understand the goal.

**Step 3: Analyse the implemented solution and compare that to task description and implementation plan**

Based on implementation plan and task description, compare it to actually implementation.

Focus not only on files that were actually changed or added, but also those that claim to be already implemented.

**Step 4: Verify that solution has implemented all necessary tests**

Make sure that all critical paths of the solutions are fully tested by combination of different tests - e2e, unit, integration.

**Step 5: Run the available tests**

Make sure that all of the tests are working properly.

**Step 6: Verify that solution follows the best practices**

Check the implemented solution. Make sure it follow the best development practices.

Take into account project standards and a practices like SOLID, SRP, DDD, DRY, KISS, Atomic Design.

Make sure that solution is not over engineered. Keep the cognitive complexity on a lower side.

**Step 7: Run static code analysis tools and formatting tools**

Make sure to run linters, static code analysis tools and formatting tools.

**Step 8: Validate the solution is secure**

For backend code, run through the following security lens. Skip items that are not applicable to the task scope.

**Injection (OWASP A03)**
- SQL: all queries use parameterized statements or ORM — no string concatenation into SQL
- Command injection: no user input passed to `exec`, `spawn`, or shell commands without a strict allowlist
- Path traversal: file paths constructed from user input are resolved and validated against a safe base directory

**Authentication and Authorization (OWASP A01, A07)**
- Every route/handler that accesses user data has an explicit authorization check
- Object-level authorization: verify the requesting user owns or has access to the specific resource (not just "is logged in")
- Token signatures are verified cryptographically, not just decoded; expiry (`exp`) checked explicitly
- No credentials or tokens stored in localStorage — httpOnly cookies or server-side sessions only

**Sensitive Data Exposure (OWASP A02)**
- No secrets, API keys, or credentials in source code or committed config files
- `.env` files are in `.gitignore` — verify, do not assume
- Sensitive fields (passwords, tokens, PII) are not logged or included in error responses
- Passwords stored as hashed values (bcrypt/argon2), never plaintext

**Security Misconfiguration (OWASP A05)**
- Security headers present: `Content-Security-Policy`, `X-Content-Type-Options`, `Strict-Transport-Security`
- CORS `Access-Control-Allow-Origin` is not `*` for authenticated endpoints — explicit allowlist only
- Rate limiting applied to authentication endpoints (login, register, password reset)
- No debug endpoints, stack traces, or internal error details exposed to clients

**Vulnerable Components (OWASP A06)**
- Run `npm audit`, `pip audit`, or `cargo audit` — zero high/critical CVEs
- No `eval()`, `Function()`, or dynamic code execution from user-controlled input

**Severity classification for findings:**
- CRITICAL: exploitable without authentication, leads to data breach or full compromise
- HIGH: exploitable by authenticated users, significant data or privilege impact
- MEDIUM: requires specific conditions, limited direct impact
- LOW: defense-in-depth improvement

Load `security-hardening` for a full standalone security review when security is the primary task.

**Step 9: Validate the solution is scalable**

Analyse if the implemented solution is scalable. Focus on areas like being able to scale it horizontaly, not having a stateful components, not having code with high computational complexity.

## Connected Skills

- `implementation-gap-analysis`
- `technical-context-discovery` - for understanding project conventions and standards to review against
- `sql-and-database` - for validating SQL quality, index coverage, query performance, schema design, and ORM usage patterns
- `security-hardening` - load for a full dedicated security review; Step 8 above is the inline lens for standard reviews
- `observability` - validate that logging, structured error context, and health endpoints are present and correct