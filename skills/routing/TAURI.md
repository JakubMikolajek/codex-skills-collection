# TAURI Cross-Branch

## When to enter this branch
- Task spans frontend + Rust boundary in a Tauri desktop app
- Task changes `#[tauri::command]` contracts and frontend `invoke` callsites together
- Task touches Tauri plugin setup across Rust and frontend packages
- Task involves app lifecycle/state managers and long-running background workers in `src-tauri`
- Task involves custom window shell behavior plus native window APIs

## When NOT to enter this branch
- Pure React web UI with no Tauri runtime — use skills/routing/REACT.md
- Pure Rust backend/system code with no Tauri boundary — use skills/routing/BACKEND.md -> skills/rust/SKILL.md
- Pure packaging/CI work with no app-runtime changes — use skills/routing/INFRA.md

## Decision tree

| If the task involves... | Read next |
|---|---|
| Window shell UX: custom titlebar, drag regions, minimize/maximize/restore, startup bounds | skills/tauri-window-shell/SKILL.md |
| Frontend `invoke` <-> Rust `#[tauri::command]` contract design, DTO mapping, error envelopes, command registry | skills/tauri-command-contract/SKILL.md |
| Tauri plugins (`tauri-plugin-*`, `@tauri-apps/plugin-*`), permission/capability alignment, plugin drift checks | skills/tauri-plugin-integration/SKILL.md |
| App state lifecycle, managers, background task orchestration, startup/shutdown hooks | skills/tauri-runtime-lifecycle/SKILL.md |
| Rust-heavy Tauri service internals (ownership, async, performance-sensitive logic) | skills/rust/SKILL.md |
| Unclear/cross-cutting Tauri task | skills/tauri-command-contract/SKILL.md |

## Combination rules
- Always load `technical-context-discovery` before implementing Tauri tasks
- `tauri-window-shell` pairs with `react` for frontend window behavior
- `tauri-command-contract` pairs with `rust` + `react` whenever both sides of invoke contract change
- `tauri-plugin-integration` pairs with `rust`; add `react` when plugin is consumed in frontend
- `tauri-runtime-lifecycle` pairs with `rust`; add `observability` for long-running/background runtime paths
- Use `security-hardening` when changing permissions/capabilities, CSP, or command exposure surface
