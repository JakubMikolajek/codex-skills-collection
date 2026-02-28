---
name: nuxt
description: Nuxt 3 implementation and review patterns for full-stack Vue applications. Use when Codex needs to build, refactor, debug, or review Nuxt 3 routes, layouts, pages, server APIs, composables, data fetching, middleware, SEO metadata, runtime config, or hybrid rendering behavior in a Nuxt codebase, especially where SSR is limited and most flows are client-first.
---

# Nuxt Implementation Patterns

Use this skill when the task is specifically about Nuxt 3 behavior on top of Vue. Reuse the general `vue` skill for component discipline and this skill for routing, server boundaries, data loading, composables, and app-level rendering concerns.

## Delivery Workflow

Use the checklist below and track progress:

```
Nuxt progress:
- [ ] Step 1: Discover route, layout, and module conventions
- [ ] Step 2: Map client, server, composable, and runtime-config boundaries
- [ ] Step 3: Implement pages, composables, data loading, and mutations
- [ ] Step 4: Verify middleware, metadata, and error/loading states
- [ ] Step 5: Test route behavior and runtime assumptions
```

## Project Profile Assumptions

- Assume Nuxt 3 by default.
- Assume most routes are client-first or hybrid unless the repository clearly leans on heavy SSR.
- Do not introduce SSR-specific complexity where simple client-side or hybrid rendering matches the current project shape.
- Keep server-side behavior explicit when it is actually required for auth, secrets, protected APIs, or route-level SEO.

## Routing and App Structure

- Follow the repository's routing model and file conventions exactly.
- Keep pages, layouts, and shared components clearly separated.
- Treat route params, query params, and server-derived state as explicit inputs.
- Keep framework-specific orchestration in Nuxt layers and push reusable UI into Vue components.
- Prefer composables for reusable route-adjacent logic before introducing broad global state.

## Data Fetching and Server Boundaries

- Keep server-only code on the server side.
- Use the project's established data-loading patterns consistently.
- Be explicit about where data is fetched, cached, transformed, and invalidated.
- Model loading, empty, success, and error states intentionally.
- Avoid hiding network behavior deep inside low-level presentational components.
- Prefer the project's existing Nuxt 3 composables and data-loading conventions over ad hoc fetch wrappers.

## Middleware, Auth, and Runtime Config

- Keep auth checks and route gating close to the app-level layer that owns them.
- Respect runtime config boundaries; do not leak server-only secrets into the client.
- Make middleware behavior explicit and predictable.
- Treat redirects and not-found outcomes as first-class route results.

## SEO and Metadata

- Keep page metadata close to the route or feature that owns it.
- Ensure SSR/SSG/hybrid assumptions are explicit when relevant, but default to the repository's lighter SSR posture.
- Avoid client-only placeholders when the server can render the real content.

## Composables and Shared Logic

- Use composables as the default unit for reusable feature logic in Nuxt 3.
- Keep composables capability-focused and separate from route files when the logic is reused.
- Avoid turning composables into hidden service locators or side-effect dumping grounds.
- Move state into `pinia` only when it truly needs shared ownership across views, routes, or long-lived app flows.

## Nuxt Review Checklist

```
Structure:
- [ ] Route, layout, and shared-component boundaries are clear
- [ ] Client vs server code placement is justified
- [ ] Middleware and runtime-config usage stay in the right layer

Behavior:
- [ ] Data loading and mutation paths are explicit
- [ ] Redirect, not-found, and auth-sensitive flows are covered
- [ ] Loading and error experiences align with the route behavior

Quality:
- [ ] Secrets and privileged logic stay server-side
- [ ] Metadata and SEO behavior are intentional
- [ ] Composables stay cohesive and reusable
- [ ] Tests or verification cover route-level behavior
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Mixing server and client concerns in one place | Keep boundaries explicit |
| SSR-heavy architecture for a mostly client-first app | Match the repository's current lighter SSR posture |
| Ad hoc data-loading patterns per page | Reuse the project's dominant Nuxt pattern |
| Route logic duplicated across pages | Extract a composable |
| Middleware doing business logic | Keep it focused on route-level concerns |
| Route files full of repeated UI detail | Extract shared Vue components |
| Leaking runtime config broadly | Read only what the current layer needs |

## Connected Skills

- `vue` - use for component, composable, and template discipline
- `pinia` - use when shared app state depends on store architecture
- `vuetify-primevue` - use when UI is built with Vuetify or PrimeVue
- `technical-context-discovery` - follow project Nuxt conventions before editing
- `code-review` - validate route, rendering, and integration quality
