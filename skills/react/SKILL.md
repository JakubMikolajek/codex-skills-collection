---
name: react
description: React implementation and review patterns for component-driven web UI. Use when Codex needs to build, refactor, debug, or review React components, hooks, forms, client-side state, rendering behavior, accessibility, or data-driven interaction flows.
---

# React Implementation Patterns

Use this skill to build React UI that is predictable, composable, and easy to reason about under change.

## Delivery Workflow

Use the checklist below and track progress:

```
React progress:
- [ ] Step 1: Discover project conventions, routing, and state boundaries
- [ ] Step 2: Define component API and ownership of state
- [ ] Step 3: Implement rendering and interaction flow
- [ ] Step 4: Control effects, async state, and performance
- [ ] Step 5: Verify accessibility and tests
```

## Component Design

- Prefer small focused components with a stable public API.
- Keep state as close as possible to where it is used, but no closer than clarity allows.
- Lift state only when multiple consumers genuinely need shared ownership.
- Separate presentational pieces from data orchestration when complexity grows.
- Reuse existing design-system and shared primitives before creating new ones.

## State and Effects

- Treat derived data as derived data; do not duplicate it in state.
- Use effects only for synchronization with the outside world.
- Avoid effects that merely reshuffle props into state.
- Keep async state explicit: idle, loading, success, empty, error.
- Clean up subscriptions, timers, and in-flight async work where relevant.

## Hooks Guidance

- Keep custom hooks cohesive and named after the capability they provide.
- Do not hide critical side effects inside generic utility hooks.
- Respect hook dependency rules instead of muting them casually.
- Memoize only when it improves observable behavior or avoids real cost.
- Prefer straightforward code over defensive over-abstraction.

## Forms and Interaction

- Model validation, dirty state, and submission states explicitly.
- Prevent duplicate submits and inconsistent optimistic UI.
- Keep error messages actionable and close to the affected control.
- Preserve keyboard accessibility and logical tab order.

## Rendering Performance

- Avoid re-renders caused by unstable props, inline objects, or unnecessary lifted state.
- Use memoization selectively after identifying a real render issue.
- Keep list keys stable and meaningful.
- Do not solve structural state problems with blanket `memo` usage.

## React Review Checklist

```
Architecture:
- [ ] Component boundaries are clear
- [ ] State ownership is appropriate
- [ ] Effects are only used for external synchronization

Behavior:
- [ ] Loading, error, and empty states are intentional
- [ ] Forms and interactive flows handle invalid and repeat actions
- [ ] Derived values are not duplicated in state

Quality:
- [ ] Accessibility semantics are present
- [ ] Tests cover critical user behavior
- [ ] Reuse beats one-off component invention
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Syncing props to state without a hard reason | Derive directly from props or lift ownership properly |
| Huge all-purpose component | Split by responsibility and data flow |
| `useEffect` as default control flow tool | Prefer direct render logic, handlers, or dedicated data hooks |
| Missing dependencies in `useEffect` / `useCallback` | Declare full dependency arrays or refactor to avoid stale closures |
| Using list index as `key` for dynamic collections | Use stable item identity keys to avoid reorder/delete bugs |
| Creating inline object/array props in hot render paths | Use stable references (`const` or memoized values) |
| Using global Context for rapidly changing local state | Keep fast-changing state local or in dedicated stores |
| Blanket memoization | Fix unstable boundaries or measure real bottlenecks |
| One-off styles/components that bypass the system | Extend existing shared UI patterns |

## Connected Skills

- `react-nextjs` - use when the task is specifically about Next.js route and rendering behavior
- `shadcn-tailwind` - use when the UI stack relies on shadcn/ui and Tailwind CSS
- `technical-context-discovery` - follow project React conventions before editing
- `frontend-implementation` - apply UI, design-system, and accessibility guidance
- `ui-verification` - verify implementation against approved designs when relevant
