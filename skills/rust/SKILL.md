---
name: rust
description: Rust implementation and review patterns for systems, backend, and desktop application logic. Use when Codex needs to build, refactor, debug, or review Rust code involving ownership, borrowing, async workflows, error handling, modules, serialization, concurrency, or performance-sensitive logic, especially when Rust is used with Tauri for advanced desktop applications such as a custom IDE.
---

# Rust Implementation Patterns

Use this skill for idiomatic Rust with a practical bias toward Tauri-backed desktop application logic. Assume the Rust side often owns heavy operations such as filesystem work, process orchestration, indexing, background tasks, editor services, and stable IPC with the frontend.

## Delivery Workflow

Use the checklist below and track progress:

```
Rust progress:
- [ ] Step 1: Discover crate boundaries, module layout, and Tauri integration points
- [ ] Step 2: Model ownership, data flow, and error shapes explicitly
- [ ] Step 3: Implement logic with small focused types and functions
- [ ] Step 4: Handle async work, IO, and concurrency without blocking UI flows
- [ ] Step 5: Verify tests, formatting, linting, and boundary behavior
```

## Core Rust Rules

- Model ownership intentionally before writing broad mutable flows.
- Prefer simple types and explicit lifetimes over clever abstractions.
- Use the type system to make invalid states difficult to represent.
- Keep functions small, intention-revealing, and focused on one capability.
- Avoid writing TypeScript, C++, or Java in Rust syntax.

## Data Modeling and Errors

- Prefer structs and enums that encode real domain meaning.
- Use `Result` and `Option` intentionally; do not erase failure modes behind generic strings.
- Model recoverable application errors explicitly and keep infrastructure errors distinguishable.
- Use `thiserror` or the project-standard error pattern when structured errors improve clarity.
- Keep serialization DTOs separate from internal domain types when the boundary is non-trivial.

## Async, IO, and Concurrency

- Keep blocking filesystem, process, or indexing work off the main async path when it can stall responsiveness.
- Use the project's async runtime conventions consistently.
- Preserve cancellation and shutdown behavior where long-running tasks exist.
- Prefer message passing, task isolation, or scoped ownership over broad shared mutable state.
- Make background work observable and controllable when it affects the UI experience.

## Tauri Boundaries

- Keep Tauri commands thin: parse input, delegate work, map output, return serializable results.
- Keep frontend-facing DTOs stable and explicit.
- Do not leak internal Rust-only types directly across the Tauri boundary.
- Keep app state injection and shared service ownership clear.
- Move heavy desktop capabilities such as file scanning, process launching, indexing, and project analysis into focused Rust services rather than command handlers.

## Custom IDE-Oriented Concerns

- Keep editor features separated by capability: workspace, files, diagnostics, search, indexing, processes, language tooling.
- Design long-running services so they can be refreshed, cancelled, or restarted predictably.
- Treat filesystem watchers, subprocesses, and background indexing as failure-prone boundaries.
- Make state transitions explicit for loading, ready, stale, rebuilding, and failed states when those affect the desktop UX.
- Prefer incremental and capability-focused architecture over one giant app state object.

## Module and Crate Hygiene

- Keep modules organized around cohesive responsibilities.
- Extract shared logic only when the boundary is real and stable.
- Avoid prematurely splitting crates if module boundaries are sufficient.
- Keep public APIs small and intention-revealing.

## Performance and Memory

- Allocate consciously in hot paths, but do not micro-optimize before the design is clear.
- Prefer clear ownership and correct behavior before low-level tuning.
- Avoid unnecessary cloning in critical paths, but do not contort code to eliminate harmless clones.
- Make cache and indexing invalidation rules explicit.

## Rust Review Checklist

```
Correctness:
- [ ] Ownership and mutation boundaries are clear
- [ ] Error handling is explicit and meaningful
- [ ] Async and blocking work are separated appropriately

Architecture:
- [ ] Module boundaries are cohesive
- [ ] Tauri commands stay thin
- [ ] Heavy IDE capabilities live in dedicated services

Quality:
- [ ] Public API is intention-revealing
- [ ] Serialization boundaries are explicit
- [ ] Tests cover critical flows and failure paths
- [ ] `cargo fmt` and `clippy` expectations are respected
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| One massive Tauri command doing everything | Delegate to focused Rust services |
| Generic `String` errors everywhere | Use structured errors or explicit variants |
| Shared mutable state spread across tasks | Isolate ownership and coordinate intentionally |
| Blocking IO inside latency-sensitive async paths | Offload or separate blocking work clearly |
| Giant global app state for all IDE capabilities | Split state by capability and ownership |
| Over-abstracting lifetimes and generics too early | Keep APIs concrete until a real abstraction appears |

## Connected Skills

- `technical-context-discovery` - follow existing Rust and Tauri conventions before editing
- `code-review` - validate correctness, boundaries, and runtime behavior
