---
name: tauri-plugin-integration
description: Integrate and maintain Tauri v2 plugins across Rust and frontend with consistent configuration, permissions/capabilities, and runtime behavior. Use when adding, updating, or debugging `tauri-plugin-*` and `@tauri-apps/plugin-*` dependencies.
---

# Tauri Plugin Integration

Use this skill for plugin-related changes that span Cargo, frontend packages, and runtime configuration.

## When to Use

- Adding/removing/upgrading Tauri plugins (`tauri-plugin-*`, `@tauri-apps/plugin-*`)
- Plugin works on one side (Rust/frontend) but fails or is missing on the other
- Updating permissions/capabilities/CSP related to plugin access
- Reviewing plugin drift and initialization order in `src-tauri`

## When NOT to Use

- Task is pure Rust domain logic unrelated to Tauri plugins
- Task is pure web UI work with no Tauri runtime APIs
- Task is only command DTO contract updates (use `tauri-command-contract`)

## Delivery Workflow

```
Tauri plugin integration progress:
- [ ] Step 1: Inventory plugin usage points (Rust + frontend)
- [ ] Step 2: Align dependency declarations and versions
- [ ] Step 3: Verify registration/init order in app builder
- [ ] Step 4: Validate permissions/capabilities/security settings
- [ ] Step 5: Run plugin smoke checks in desktop runtime
```

## Core Rules

- Keep plugin declarations aligned across Rust and frontend where both sides are used.
- Register/init plugins in one clear app bootstrap path.
- Treat permissions/capabilities as part of plugin implementation, not optional extras.
- Keep plugin-specific behavior behind small adapters to avoid API sprawl in feature code.
- Validate plugin behavior in desktop runtime, not only browser dev mode.

## Drift Check

Before merge, confirm:

```
- [ ] `src-tauri/Cargo.toml` plugin deps aligned with use in Rust code
- [ ] `package.json` plugin deps aligned with use in frontend code
- [ ] Plugin init/registration exists and order is intentional
- [ ] Permissions/capabilities/CSP updated where needed
- [ ] At least one runtime smoke path verified per touched plugin
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Adding plugin dependency only in frontend or only in Rust | Align both sides according to actual usage |
| Plugin API called directly from many components | Wrap plugin usage behind small feature adapters |
| Assuming plugin works because web dev server works | Validate in actual Tauri runtime |
| Ignoring permissions/capabilities updates | Update security config in same change |
| Mixing unrelated plugin setup changes in one patch | Keep plugin changes scoped and testable |

## Connected Skills

- `rust` - plugin bootstrap and backend-side usage
- `react` - frontend plugin consumption patterns
- `tauri-command-contract` - when plugin calls are routed through commands
- `security-hardening` - permissions/capabilities and exposure review
- `technical-context-discovery` - confirm project plugin conventions before edits
