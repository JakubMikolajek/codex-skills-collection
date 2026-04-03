---
name: tauri-runtime-lifecycle
description: Manage Tauri v2 runtime lifecycle and long-running Rust managers safely. Use for app state ownership, startup/shutdown hooks, cancellation, background tasks, and listener cleanup across desktop app sessions.
---

# Tauri Runtime Lifecycle

Use this skill when task complexity centers on runtime state, long-lived managers, and lifecycle correctness.

## When to Use

- Adding/refactoring Tauri `State<>` managers and shared runtime services
- Implementing startup/shutdown logic, background workers, or supervisor loops
- Fixing leaks/zombie processes/listener buildup across app relaunches
- Coordinating command handlers with long-running tasks and cancellation flows

## When NOT to Use

- Task is only command DTO boundary work (use `tauri-command-contract`)
- Task is only window/titlebar UX behavior (use `tauri-window-shell`)
- Task is purely static config/build packaging with no runtime manager logic

## Delivery Workflow

```
Tauri runtime lifecycle progress:
- [ ] Step 1: Map runtime owners (State, managers, workers, event channels)
- [ ] Step 2: Define startup, ready, degraded, shutdown states explicitly
- [ ] Step 3: Implement cancellation and cleanup paths for long-running tasks
- [ ] Step 4: Verify command interactions with manager lifecycle
- [ ] Step 5: Add lifecycle smoke tests and shutdown/restart verification
```

## Core Rules

- Each long-lived service must have explicit owner, start path, and stop path.
- Commands that trigger background work must expose cancellable or idempotent behavior.
- Keep synchronization explicit; avoid ad-hoc shared mutable state across unrelated managers.
- Ensure listeners/subscriptions are detached on shutdown/unmount.
- Prefer structured events and state snapshots over implicit flags scattered in code.

## Runtime Safety Checklist

```
- [ ] Manager init happens once per app lifecycle (or intentionally per workspace/session)
- [ ] Cancellation path exists for each long-running task
- [ ] Shutdown closes resources (PTY/processes/watchers/channels)
- [ ] Command handlers validate manager readiness before use
- [ ] Restart/relaunch path does not duplicate workers/listeners
```

## Test Matrix (Lifecycle)

- startup -> ready: manager initialization and registration
- ready -> running task -> cancel: cancellation semantics and resource cleanup
- runtime error path: degraded/recoverable behavior
- shutdown: all workers/listeners/resources released
- relaunch: no duplicated background tasks from prior session

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Long-running worker without explicit cancellation | Add cancellation token/signal and deterministic stop |
| `State<>` holding unrelated capabilities | Split managers by capability and ownership |
| Commands assuming manager is always ready | Guard readiness and return explicit boundary error |
| Listener registration in many paths without cleanup | Centralize subscription lifecycle and unlisten on teardown |
| Fixing race conditions with sleeps/retries only | Model explicit state transitions and synchronization |

## Connected Skills

- `rust` - ownership, async runtime, and manager implementation details
- `tauri-command-contract` - stable command semantics over runtime state
- `observability` - logging/metrics around startup, cancellation, and shutdown
- `technical-context-discovery` - check existing manager/state conventions first
