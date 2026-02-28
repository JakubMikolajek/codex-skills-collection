---
name: kotlin
description: Kotlin implementation and review patterns for application, backend, and shared business logic. Use when Codex needs to build, refactor, debug, or review Kotlin code involving domain modeling, null-safety, coroutines, error handling, collections, service logic, or tests.
---

# Kotlin Implementation Patterns

Use this skill to keep Kotlin code explicit, null-safe, and aligned with structured concurrency and domain-driven modeling.

## Delivery Workflow

Use the checklist below and track progress:

```
Kotlin progress:
- [ ] Step 1: Discover module conventions and architecture boundaries
- [ ] Step 2: Model domain types and error shapes explicitly
- [ ] Step 3: Implement behavior with small focused functions
- [ ] Step 4: Handle concurrency and side effects safely
- [ ] Step 5: Verify tests and failure paths
```

## Core Rules

- Prefer `val` over `var` unless mutation is required and contained.
- Keep functions small and intention-revealing.
- Use types to make invalid states difficult to represent.
- Preserve null-safety instead of bypassing it with forceful shortcuts.
- Reuse existing architectural boundaries rather than introducing parallel patterns.

## Modeling Data and Behavior

- Prefer data classes for value-like structures.
- Use sealed hierarchies or explicit result models for finite state and outcome sets.
- Keep extension functions narrow, local, and unsurprising.
- Avoid primitive obsession when domain concepts deserve named types.
- Make side effects visible at call sites.

## Null-Safety and Errors

- Eliminate nullable values as close to the boundary as possible.
- Avoid `!!` unless the invariant is proven and documented by nearby code.
- Differentiate validation failures, missing data, and infrastructure failures.
- Prefer explicit result mapping over swallowing exceptions.
- Keep exception translation near integration boundaries.

## Coroutines and Concurrency

- Use structured concurrency and inherit the project's coroutine conventions.
- Keep cancellation behavior intact; do not swallow cancellation exceptions.
- Avoid blocking calls inside suspending flows unless isolated appropriately.
- Keep dispatching decisions explicit when work crosses CPU, IO, or main-thread boundaries.
- Model loading and concurrent work so callers can reason about lifecycle and failure.

## Collections and Transformations

- Prefer readable collection pipelines over clever one-liners.
- Avoid repeated transformations when a single pass is clearer and cheaper.
- Use sequences only when laziness materially helps and remains understandable.
- Name intermediate results when pipelines become hard to scan.

## Testing Checklist

```
Correctness:
- [ ] Happy path behavior is covered
- [ ] Null and invalid input paths are covered
- [ ] Result/error mapping is asserted explicitly

Concurrency:
- [ ] Coroutine behavior is testable and deterministic
- [ ] Cancellation and timeout-sensitive logic is not ignored

Design:
- [ ] Public API stays small and intention-revealing
- [ ] Hidden side effects are minimized
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| `!!` scattered through logic | Resolve nullability at the boundary or model it explicitly |
| Massive service method with branching everywhere | Extract focused private functions or domain collaborators |
| Throwing generic exceptions for business cases | Use explicit domain/result modeling |
| Blocking calls in coroutine code | Use proper suspending APIs or isolate blocking work |
| Unnamed booleans and strings carrying domain meaning | Introduce domain types or enums/sealed models |

## Connected Skills

- `technical-context-discovery` - mirror existing Kotlin patterns before editing
- `code-review` - review correctness, complexity, and failure handling
- `sql-and-database` - use when persistence, SQL, or ORM concerns are involved
