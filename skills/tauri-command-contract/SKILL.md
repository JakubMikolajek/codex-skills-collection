---
name: tauri-command-contract
description: Define and enforce contracts between frontend `invoke` calls and Rust `#[tauri::command]` handlers in Tauri v2 apps. Use for command DTOs, error envelopes, command registration hygiene, and boundary-focused testing.
---

# Tauri Command Contract

Use this skill when a task crosses the frontend/Rust boundary through Tauri commands.

## When to Use

- Adding or changing `#[tauri::command]` handlers in `src-tauri`
- Modifying frontend `invoke` callsites or typed command wrappers
- Changing command payload/response DTOs or error format
- Refactoring command registration (`generate_handler!`) and command naming
- Reviewing boundary regressions where frontend and Rust drifted out of sync

## When NOT to Use

- Task is only about window controls/titlebar behavior with no command contract changes (use `tauri-window-shell`)
- Task is purely internal Rust logic with no Tauri command boundary
- Task is only UI styling and interaction with no invoke path

## Delivery Workflow

```
Tauri command contract progress:
- [ ] Step 1: Inventory touched commands and callsites
- [ ] Step 2: Define explicit DTOs for request/response at boundary
- [ ] Step 3: Normalize error envelope and map Rust errors intentionally
- [ ] Step 4: Verify command registration and frontend wrapper alignment
- [ ] Step 5: Add/adjust boundary tests (Rust + frontend invoke surface)
```

## Core Rules

- Treat each command as a versioned contract, not an internal function leak.
- Keep command handlers thin: validate/parse, delegate to service, map output.
- Avoid anonymous/loosely typed payloads at boundary; use explicit serializable DTOs.
- Do not return raw infrastructure errors directly to frontend.
- Keep command names stable and intention-revealing; avoid accidental renames.

## Contract Pattern

- Rust side:
  - define transport DTOs and explicit result shape
  - map domain/infrastructure errors to stable boundary error variants
- Frontend side:
  - centralize invoke wrappers instead of scattering raw `invoke(...)` strings
  - type wrappers to shared command DTO shapes

Boundary checklist:

```
- [ ] Command name unchanged or migration path documented
- [ ] Request DTO shape explicit
- [ ] Response DTO shape explicit
- [ ] Error envelope stable and parseable by frontend
- [ ] Frontend wrapper updated in same change
```

## Test Pattern

- Add quick command smoke tests in Rust where practical (command/service mapping)
- Add frontend boundary tests for wrapper parsing and error mapping
- For high-risk changes, add one integration path that validates roundtrip invoke payload

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Raw `invoke("someString", { ... })` scattered in many components | Centralize typed invoke adapters |
| Returning `String` error for every failure | Map to explicit envelope with stable codes/messages |
| Big command handlers with business logic | Delegate to Rust services, keep handlers thin |
| Renaming commands without updating wrappers/tests | Treat command name as public contract and migrate intentionally |
| Updating Rust DTO only | Always update Rust and frontend wrapper in the same change |

## Connected Skills

- `rust` - command handler/service decomposition and error mapping
- `react` - typed frontend wrappers and consumption patterns
- `tauri-runtime-lifecycle` - when commands depend on managed app state
- `technical-context-discovery` - verify existing command naming and DTO conventions first
