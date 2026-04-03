---
name: tauri-window-shell
description: React + Tauri desktop shell patterns for native window behavior. Use when implementing or fixing custom titlebar, drag regions, maximize/minimize controls, startup bounds, and frontend-to-Tauri window APIs.
---

# Tauri Window Shell

Use this skill for desktop-shell behavior where React UI controls a native Tauri window.

## When to Use

- Custom titlebar implementation (frameless window, drag regions, native control buttons)
- Window controls (`minimize`, `toggleMaximize`, `close`, fullscreen)
- Drag/double-click behaviors in top bar (`startDragging`, maximize on titlebar double-click)
- Startup bounds/restore behavior and window state sync with frontend UI
- Regressions where web UI looks correct but native window behavior is broken

## When NOT to Use

- Pure web React work with no Tauri runtime
- Rust-side command/business logic with no window-shell behavior (use `rust`)
- General CSS/layout issues unrelated to native window integration

## Delivery Workflow

```
Tauri window shell progress:
- [ ] Step 1: Confirm runtime and API version (`@tauri-apps/api` v1 vs v2)
- [ ] Step 2: Map titlebar interaction zones (drag zone vs interactive controls)
- [ ] Step 3: Implement window API calls and event wiring
- [ ] Step 4: Verify startup bounds/maximize/minimize/close behavior
- [ ] Step 5: Re-test edge cases (double-click, resize, multi-monitor, relaunch)
```

## General References (Tauri v2)

Read [references/tauri-v2.md](references/tauri-v2.md) when:
- confirming current `@tauri-apps/api` window APIs
- wiring listeners for window state synchronization
- validating shell behavior and common desktop edge cases

## Core Rules

- Keep a single window adapter module for all `@tauri-apps/api/window` calls; avoid scattering raw API calls across components.
- Never attach drag behavior to interactive controls (search input, tabs, buttons); only dedicated drag regions.
- Handle titlebar double-click intentionally: either maximize/restore or disabled by product decision.
- Keep native-window state and UI state synchronized after every action (maximize icon, disabled states, menu affordances).
- Test behavior in real desktop runtime, not only browser dev mode.

## Interaction Zone Contract

- Mark drag regions explicitly (`data-tauri-drag-region`) and keep them free of clickable controls.
- Mark no-drag areas for interactive elements and nested controls.
- Use pointer events intentionally; drag region should not steal click handlers from controls.

## Verification Checklist

```
Window controls:
- [ ] Minimize works and does not blur/freeze the app
- [ ] Maximize/restore toggles correctly from both button and titlebar double-click
- [ ] Close action follows product guardrails (confirmation/unsaved state if required)

Drag + bounds:
- [ ] Drag works only from intended region
- [ ] Double-click in drag region does not trigger unintended actions
- [ ] Initial bounds/position are valid on relaunch and across displays

State sync:
- [ ] UI icon/state reflects actual native window state
- [ ] Event listeners are cleaned up on unmount
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Calling Tauri window APIs directly from many components | Centralize in one adapter/hook and reuse |
| Making the whole titlebar draggable | Define strict drag-only zones and no-drag controls |
| Handling double-click implicitly via browser defaults | Implement explicit maximize/restore behavior |
| Validating only in browser preview | Validate in actual Tauri runtime on desktop |
| Storing maximize state only in React local state | Read/subscribe to native state and sync UI |

## Connected Skills

- `react` - UI composition, hooks, and event handling discipline
- `tauri-command-contract` - when shell UI actions also change invoke payload/response contracts
- `tauri-runtime-lifecycle` - when shell state is coupled with long-running managers
- `frontend-implementation` - accessibility and robust interaction patterns
- `rust` - when window behavior depends on Rust-side configuration or commands
- `technical-context-discovery` - confirm project conventions and Tauri version before edits
