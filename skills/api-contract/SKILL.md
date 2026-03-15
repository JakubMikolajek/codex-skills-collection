---
name: api-contract
description: API contract design, versioning, and breaking change management for HTTP APIs. Covers OpenAPI specification as source of truth, backward compatibility rules, deprecation lifecycle, consumer-driven contract principles, and API design standards. Use when designing new API endpoints, reviewing API changes, managing API versions, or coordinating changes that affect consumers in other services or clients.
---

# API Contract

An API is a promise. This skill ensures that promise is explicit, versioned, and broken only deliberately. It covers design, documentation, versioning, and the process for managing changes that affect consumers.

## When to Use

- Designing a new HTTP API or adding endpoints to an existing one
- Reviewing a PR that modifies request/response shapes, status codes, or auth requirements
- Planning a breaking change to an existing API
- Onboarding consumers (frontend, mobile, other services) to an API
- Before releasing a new API version

## When NOT to Use

- Internal function signatures or module interfaces — this skill is for network-boundary APIs
- gRPC or GraphQL (different contract mechanisms — see `graphql` skill when available)
- Database schema changes — use `migration-strategy`

## Core Principles

### Contract-First, Not Code-First

Design the API contract before writing implementation. The OpenAPI spec is the source of truth — not the code, not the documentation, not the Postman collection. If they diverge, the spec wins until the spec is deliberately updated.

### Backward Compatibility is a Hard Constraint

Once an API endpoint is consumed by any external client, any change that breaks existing consumers requires a version bump. The cost of breaking consumers silently is always higher than the cost of versioning.

### Every Endpoint is a Public Commitment

Design as if the endpoint will be consumed by a party you cannot contact. Document every field, every status code, every error case — because absent documentation, consumers will hardcode assumptions about your implementation details.

## API Contract Process

Use the checklist below and track progress:

```
API contract progress:
- [ ] Step 1: Design contract in OpenAPI spec before implementation
- [ ] Step 2: Apply API design standards
- [ ] Step 3: Define error contract explicitly
- [ ] Step 4: Assess backward compatibility impact
- [ ] Step 5: Version if breaking changes are required
- [ ] Step 6: Update deprecation markers and consumer communication
```

**Step 1: Design contract in OpenAPI spec before implementation**

Write (or update) the OpenAPI 3.1 spec before writing route handlers. The spec should define:
- Path, method, and operation ID
- All request parameters (path, query, header) with types and validation constraints
- Request body schema with required/optional fields, types, formats, examples
- All response schemas per status code — including error responses
- Authentication/authorization requirements per operation
- Rate limit headers if applicable

Store the spec in the repo (`openapi.yaml` or `docs/api/openapi.yaml`). Generate server stubs or validation from it — do not write the spec to match code written first.

**Step 2: Apply API design standards**

URL structure:
- Use nouns for resources, not verbs: `/documents/{id}` not `/getDocument`
- Use plural nouns for collections: `/documents`, `/users`
- Nest resources only when the child cannot exist without the parent: `/projects/{id}/members`
- Avoid deep nesting beyond two levels — flatten with query parameters instead
- Use `kebab-case` for multi-word path segments: `/api/user-profiles`

HTTP methods:
| Method | Use | Body | Idempotent |
|---|---|---|---|
| GET | Read resource(s) | None | Yes |
| POST | Create resource or non-idempotent action | Yes | No |
| PUT | Replace resource entirely | Yes | Yes |
| PATCH | Partial update | Yes | No |
| DELETE | Remove resource | None | Yes |

Status codes — use precisely:
| Code | When |
|---|---|
| 200 | Successful GET, PUT, PATCH |
| 201 | Successful POST that creates a resource — include `Location` header |
| 204 | Successful DELETE or action with no response body |
| 400 | Client error: malformed request, validation failure |
| 401 | Missing or invalid authentication |
| 403 | Authenticated but not authorized for this resource/action |
| 404 | Resource not found — never use for auth failures |
| 409 | Conflict: resource already exists, optimistic lock failure |
| 422 | Semantic validation failure (request was well-formed but invalid) |
| 429 | Rate limit exceeded — include `Retry-After` header |
| 500 | Unexpected server error — never expose internal details |

Field naming:
- Use `snake_case` for JSON fields consistently across all endpoints
- Use ISO 8601 for all timestamps: `"created_at": "2025-03-15T14:30:00Z"`
- Use string UUIDs for IDs, never numeric auto-increments in public APIs
- Use explicit `null` vs absent field semantics — document both
- Boolean fields: prefix with `is_`, `has_`, `can_` for clarity

Pagination (for collection endpoints):
```json
{
  "data": [...],
  "meta": {
    "total": 150,
    "page": 2,
    "per_page": 20,
    "has_next": true
  }
}
```
Cursor-based pagination preferred over offset for large datasets or real-time data.

**Step 3: Define error contract explicitly**

All error responses must follow a consistent schema across all endpoints:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": [
      { "field": "email", "message": "must be a valid email address" }
    ],
    "request_id": "req_abc123"
  }
}
```

- `code`: machine-readable string constant, stable across versions
- `message`: human-readable, English, safe to display in logs (no secrets)
- `details`: optional array of field-level errors for validation failures
- `request_id`: correlation ID for tracing — must match the `X-Request-ID` response header

Never expose: stack traces, internal exception messages, SQL errors, file paths, or service internals in error responses.

**Step 4: Assess backward compatibility impact**

Before any API change, classify it:

**Non-breaking changes** (safe to deploy without version bump):
- Adding a new optional field to a response
- Adding a new optional query parameter
- Adding a new endpoint
- Adding a new enum value to a response field (caution: consumers must handle unknown values)
- Relaxing validation constraints (accepting more input)

**Breaking changes** (require version bump or deprecation period):
- Removing a field from a response
- Renaming a field in a request or response
- Changing a field's type
- Changing a required field to a different format
- Removing an endpoint
- Changing an HTTP status code
- Adding a new required request field
- Tightening validation constraints (rejecting previously valid input)
- Changing authentication requirements

When in doubt, treat the change as breaking.

**Step 5: Version if breaking changes are required**

Versioning strategy (choose one, apply consistently):

URL path versioning (preferred for REST APIs):
```
/api/v1/documents
/api/v2/documents
```

Header versioning (less discoverable but cleaner URLs):
```
Accept: application/vnd.api+json; version=2
```

Rules:
- Run v1 and v2 in parallel during transition period
- v1 must continue to work unchanged for all existing consumers
- Announce deprecation timeline at `v2` launch — minimum 6 months for external consumers
- Add `Deprecation` and `Sunset` headers to v1 responses:
  ```
  Deprecation: true
  Sunset: Sat, 15 Mar 2026 00:00:00 GMT
  Link: <https://api.example.com/v2/docs>; rel="successor-version"
  ```

**Step 6: Update deprecation markers and consumer communication**

When deprecating:
- Mark deprecated operations in OpenAPI with `deprecated: true`
- Add `x-deprecation-date` and `x-sunset-date` custom extensions
- Update changelog with migration instructions
- If consumers are internal teams: notify directly with migration guide
- If consumers are external: publish breaking change notice, migration guide, and timeline

## API Design Checklist

```
Design:
- [ ] OpenAPI spec written before implementation
- [ ] Resources use nouns, not verbs
- [ ] Status codes match semantics precisely
- [ ] All response fields documented including nullability
- [ ] Error contract defined and consistent

Security:
- [ ] Authentication requirement documented per operation
- [ ] Authorization scope documented per operation
- [ ] Sensitive fields not exposed unnecessarily

Versioning:
- [ ] Breaking change classified explicitly
- [ ] Version bump included if breaking
- [ ] Old version remains functional during transition
- [ ] Deprecation headers added to sunset versions

Consumer contract:
- [ ] Error codes are machine-readable string constants
- [ ] Timestamps in ISO 8601
- [ ] IDs are UUIDs, not sequential integers
- [ ] Pagination implemented for collection endpoints
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| `GET /getUser` or `POST /createDocument` | `GET /users/{id}`, `POST /documents` |
| `{"status": "ok", "data": ..., "error": ""}` — mixed success/error schema | Separate schemas per status code |
| Using 200 for errors with `{"success": false}` | Use correct 4xx/5xx status codes |
| Exposing `{"error": "NullPointerException at line 42"}` | Generic error code with request ID |
| Changing a response field type from `string` to `number` without versioning | Break = version bump |
| Undocumented nullable fields | Explicitly mark `nullable: true` in OpenAPI |
| Auto-increment IDs in public APIs (`/users/1`, `/users/2`) | UUID strings |
| No rate limiting on public endpoints | Rate limits + `Retry-After` header |
| Spec written after code to match implementation | Spec first, implementation follows |

## Connected Skills

- `security-hardening` — API design decisions directly affect the security attack surface
- `multi-repo` — breaking API changes require coordinated multi-repo releases
- `nestjs` — NestJS DTOs, Swagger decorators, and validation pipes implement the contract
- `python-fastapi` — FastAPI response models and OpenAPI generation implement the contract
- `technical-context-discovery` — discover existing API conventions before designing new endpoints
- `migration-strategy` — API schema changes and database schema changes often need coordinated rollout
