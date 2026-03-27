---
name: vue
description: Vue implementation and review patterns for Composition API frontend applications. Use when Codex needs to build, refactor, debug, or review Vue components, composables, forms, reactive state, template logic, accessibility, or data-driven interaction flows in a Vue codebase, especially when the project is composables-first.
---

# Vue Implementation Patterns

Use this skill to build Vue UI that stays composable, predictable, and easy to evolve. Prefer Composition API and composables-first patterns. Reuse framework-specific skills like `nuxt`, `pinia`, and `vuetify-primevue` when the task depends on those layers.

## Delivery Workflow

Use the checklist below and track progress:

```
Vue progress:
- [ ] Step 1: Discover project conventions, routing, and component structure
- [ ] Step 2: Define component responsibilities and reactive ownership
- [ ] Step 3: Implement template, composables, and user interaction flow
- [ ] Step 4: Control async behavior and rendering cost
- [ ] Step 5: Verify accessibility and tests
```

## Component Design

- Prefer Composition API patterns already established in the codebase.
- Keep components small, focused, and explicit about their public props and emitted events.
- Prefer composition over large option bags and multi-purpose components.
- Push repeated logic into composables when it is truly reusable.
- Keep display-only components thin and move orchestration into higher-level components or stores.
- Reuse established design-system or shared UI primitives before inventing new component patterns.

## Reactivity Rules

- Keep one clear owner for each piece of state.
- Avoid duplicating derived values in local reactive state.
- Use `computed` for derivation and watchers only when synchronizing with external systems or imperative APIs.
- Keep reactivity explicit enough that updates are easy to trace.
- Avoid burying business-critical mutations inside generic helpers.

## Templates and Interaction

- Keep templates readable; extract subcomponents before nesting becomes hard to scan.
- Prefer explicit event and prop flows over implicit magic across many layers.
- Model loading, error, empty, success, and invalid-input states explicitly.
- Keep forms and validation flows close to the controls they affect.
- Preserve keyboard support and semantic structure.

## Composables Guidance

- Prefer composables as the default place for reusable client logic that does not belong in global state.
- Name composables after the capability they provide.
- Keep composables cohesive; each should own one capability or one closely related slice of behavior.
- Avoid composables that silently mutate broad global state.
- Return stable, intention-revealing APIs instead of exposing raw implementation details.
- Keep composables separate from Pinia stores unless shared state ownership is actually required.

## Vue Review Checklist

```
Architecture:
- [ ] Component boundaries are clear
- [ ] Reactive ownership is appropriate
- [ ] Composables are cohesive and not overly magical

Behavior:
- [ ] Async, loading, error, and empty states are intentional
- [ ] Form and interaction paths handle invalid or repeated actions
- [ ] Derived values are not duplicated in reactive state

Quality:
- [ ] Accessibility semantics are present
- [ ] Tests cover critical user behavior
- [ ] Shared patterns are reused instead of re-created
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| One massive SFC doing everything | Split into focused components and composables |
| Mutating props directly in child components | Emit updates to parent and keep one-way data flow |
| Using `reactive()` for primitives | Use `ref()` for primitive values |
| Using `v-if` and `v-for` on the same element | Filter before render or wrap with `<template v-for>` |
| Reusable logic duplicated across views | Extract a focused composable |
| Watchers as default state management tool | Use direct reactive ownership and `computed` first |
| Derived values stored and synced manually | Derive them with `computed` |
| Hidden mutations in generic composables | Keep mutation ownership explicit |
| Recreating UI primitives per feature | Reuse the shared component vocabulary |

## Connected Skills

- `nuxt` - use when routing, SSR, or app-level Nuxt behavior matters
- `pinia` - use when the task depends on store design or shared state
- `vuetify-primevue` - use when the UI stack depends on Vuetify or PrimeVue
- `technical-context-discovery` - follow project Vue conventions before editing
- `frontend-implementation` - apply UI, accessibility, and design-system rules
