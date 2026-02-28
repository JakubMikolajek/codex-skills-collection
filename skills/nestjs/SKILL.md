---
name: nestjs
description: NestJS implementation and review patterns for modular backend systems. Use when Codex needs to build, refactor, debug, or review NestJS modules, controllers, services, DTOs, validation, guards, interceptors, background processing, dependency injection, or test coverage for API behavior.
---

# NestJS Implementation Patterns

Use this skill to keep NestJS code modular, testable, and aligned with clear request-to-domain boundaries.

## Delivery Workflow

Use the checklist below and track progress:

```
NestJS progress:
- [ ] Step 1: Discover module boundaries and framework conventions
- [ ] Step 2: Model DTOs, validation, and authorization boundaries
- [ ] Step 3: Implement controller/service/repository responsibilities cleanly
- [ ] Step 4: Handle errors, side effects, and infrastructure concerns explicitly
- [ ] Step 5: Verify tests, security, and observability paths
```

## Architecture Rules

- Keep controllers thin: accept requests, delegate work, return mapped responses.
- Put business logic in services or dedicated domain collaborators, not decorators or controllers.
- Keep modules cohesive and avoid circular dependencies.
- Make provider ownership clear; do not register the same concern in multiple modules casually.
- Reuse project-standard patterns for config, logging, and cross-cutting concerns.

## DTOs, Validation, and Transformation

- Validate external input at the boundary.
- Keep DTOs focused on transport shape, not internal domain behavior.
- Map DTOs to domain/service inputs explicitly when complexity grows.
- Avoid leaking persistence entities directly through controller responses unless the project already standardizes that pattern.
- Treat parsing, defaults, and coercion as explicit choices.

## Security and Request Pipeline

- Apply guards, roles, and authorization checks where the project expects them.
- Keep authentication, authorization, validation, and business rules as separate concerns.
- Use interceptors, pipes, and filters intentionally for cross-cutting behavior.
- Return predictable error shapes and status codes.
- Do not expose internal exception details or persistence internals to clients.

## Services and Data Access

- Keep service methods focused on one business use case.
- Isolate database access behind the project's existing repository/data-access pattern.
- Make transactions explicit when a use case spans multiple writes.
- Keep external API calls and message publishing visible in orchestration code.
- Avoid mixing persistence, authorization, validation, and mapping logic in one method.

## Testing Checklist

```
HTTP/API:
- [ ] Request validation and status codes are covered
- [ ] Auth and authorization branches are covered where critical
- [ ] Error mapping is asserted explicitly

Service layer:
- [ ] Core business rules are tested directly
- [ ] Side effects and integration boundaries are isolated or mocked intentionally

Design:
- [ ] Controllers remain thin
- [ ] Module boundaries stay cohesive
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Fat controller with business logic | Delegate to service/domain layer |
| DTO reused as domain model everywhere | Separate transport and domain concerns |
| Ad hoc validation inside service methods | Validate at the framework boundary first |
| Circular module/provider wiring | Reshape boundaries or extract shared concern |
| Generic catch-and-log-everything blocks | Map errors intentionally and preserve useful context |

## Connected Skills

- `technical-context-discovery` - follow established NestJS and repo conventions before editing
- `sql-and-database` - use when persistence, migrations, or query design are involved
- `code-review` - validate architecture, security, and testing quality
