---
name: pinia
description: Pinia store implementation and review patterns for Vue and Nuxt applications. Use when Codex needs to build, refactor, debug, or review Pinia stores, shared app state, setup stores, getters, actions, async store flows, persistence boundaries, or coordination between composables, components, and stores.
---

# Pinia Store Patterns

Use this skill when the task depends on shared state architecture in Vue or Nuxt. Keep stores explicit, cohesive, and easy to reason about under concurrent UI updates. Prefer composables for reusable local logic and Pinia only for state that truly deserves shared ownership.

## Delivery Workflow

Use the checklist below and track progress:

```
Pinia progress:
- [ ] Step 1: Discover existing store boundaries and naming conventions
- [ ] Step 2: Define ownership of shared vs local state
- [ ] Step 3: Implement state, getters, and actions explicitly
- [ ] Step 4: Handle async flows, persistence, and invalidation safely
- [ ] Step 5: Verify store behavior and component integration
```

## Store Design Rules

- Create a store only when state genuinely needs shared ownership or cross-route lifetime.
- Keep stores organized around a coherent business capability, not around random convenience helpers.
- Keep local component state out of Pinia unless sharing it materially improves the design.
- Prefer setup-style stores when that matches the repository's Composition API conventions.
- Expose intention-revealing state, getters, and actions.
- Avoid turning a store into a dumping ground for every side effect in a feature.

## State, Getters, and Actions

- Store source-of-truth state, not duplicated derivations.
- Use getters for derived values that are meaningfully reused.
- Keep actions focused on one business interaction or one tightly related mutation flow.
- Make async actions explicit about loading, success, error, and invalidation behavior.
- Prefer clear action names over generic verbs.

## Async and Persistence Boundaries

- Keep API calls and cache invalidation logic visible in the action that owns them.
- Make hydration, persistence, and reset behavior explicit.
- Avoid silent background mutations that make UI updates hard to reason about.
- Prevent duplicate concurrent requests when the feature should behave idempotently.
- Keep composables and stores in clear roles: composables for reusable feature logic, stores for shared long-lived state.

## Pinia Review Checklist

```
Architecture:
- [ ] Store boundaries are cohesive
- [ ] Shared state is justified instead of over-centralized
- [ ] Local-only UI state is not unnecessarily global

Behavior:
- [ ] Async actions model loading and error states intentionally
- [ ] Derived values are not redundantly stored
- [ ] Reset and invalidation behavior are explicit

Quality:
- [ ] Store API is intention-revealing
- [ ] Component/store responsibilities remain clear
- [ ] Tests cover critical store transitions and async paths
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Giant app-wide mega store | Split by domain capability |
| Putting every composable concern into Pinia | Keep non-shared logic in composables |
| Storing every derived value | Use getters or component-level derivation |
| Hidden API mutations in utility helpers | Keep network and mutation ownership explicit |
| Globalizing form-only or modal-only state | Keep it local unless sharing is required |
| Generic `setData`/`updateState` style actions | Expose business-oriented actions |

## Connected Skills

- `vue` - use for component boundaries and reactive UI integration
- `nuxt` - use when store behavior interacts with route and app lifecycle
- `technical-context-discovery` - follow existing store patterns before editing
- `code-review` - validate state ownership, async behavior, and test quality
