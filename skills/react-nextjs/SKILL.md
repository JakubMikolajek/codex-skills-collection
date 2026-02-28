---
name: react-nextjs
description: React and Next.js implementation and review patterns for server-rendered and hybrid web apps. Use when Codex needs to build, refactor, debug, or review Next.js routes, layouts, server components, client components, server actions, route handlers, metadata, caching, or full-stack React application flows.
---

# React Next.js Implementation Patterns

Use this skill when the task is specifically about Next.js behavior on top of React. Reuse the general `react` skill for component discipline and this skill for app-structure, rendering model, and data-fetching rules.

## Delivery Workflow

Use the checklist below and track progress:

```
React Next.js progress:
- [ ] Step 1: Discover App Router or Pages Router conventions
- [ ] Step 2: Map server and client boundaries explicitly
- [ ] Step 3: Implement data flow, routing, and mutations
- [ ] Step 4: Verify caching, metadata, and error/loading states
- [ ] Step 5: Test the route behavior and runtime assumptions
```

## Routing and Composition

- Follow the existing router model first. Do not introduce App Router patterns into Pages Router code or the reverse without need.
- Keep route structure intentional: layout, page, loading, error, and nested segments should reflect real product boundaries.
- Keep framework-level concerns in route files and push reusable UI into shared React components.
- Treat route params, search params, and server-derived state as explicit inputs, not implicit globals.

## Server and Client Boundaries

- Default to server-first where the project already uses that model.
- Add client components only when interactivity, browser APIs, or client-side state actually require them.
- Keep client boundaries small so most rendering can stay server-driven.
- Do not pass unnecessary heavy objects across server-client boundaries.
- Make serialization constraints visible when designing props and action payloads.

## Data Fetching and Mutations

- Keep reads and writes close to the route or capability that owns them.
- Model loading, empty, success, and error states explicitly.
- Use server actions, route handlers, or project-standard APIs intentionally rather than mixing multiple mutation styles casually.
- Be explicit about cache invalidation and revalidation after mutations.
- Avoid hiding network behavior deep inside presentational components.

## Rendering, Metadata, and SEO

- Keep metadata generation close to the route that owns the content.
- Avoid rendering client-only placeholders when the data is available server-side.
- Ensure loading and error boundaries match the route tree and user experience.
- Treat redirects, not-found states, and auth gating as first-class route outcomes.

## Runtime and Integration Safety

- Respect environment boundaries between server-only code and browser code.
- Keep secrets and privileged access on the server side.
- Avoid importing Node-only modules into client components.
- Keep edge/runtime assumptions explicit if the project uses them.

## Next.js Review Checklist

```
Structure:
- [ ] Route boundaries and shared component boundaries are clear
- [ ] Server vs client component choices are justified
- [ ] Metadata, loading, and error handling align with the route

Behavior:
- [ ] Data fetching and mutation paths are explicit
- [ ] Cache invalidation/revalidation is handled intentionally
- [ ] Redirect, not-found, and auth-sensitive flows are covered

Quality:
- [ ] Browser-only code stays in client components
- [ ] Sensitive/server-only logic stays on the server
- [ ] Tests or verification cover route-level behavior
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Marking large subtrees as client by default | Keep client boundaries small and intentional |
| Mixing multiple fetch/mutation patterns ad hoc | Reuse the project's dominant route/data pattern |
| Hiding revalidation needs after writes | Make invalidation explicit and local to the mutation |
| Route files full of UI detail | Extract reusable React components |
| Browser APIs in server components | Move that logic behind a client boundary |

## Connected Skills

- `react` - use for component, hooks, and client interaction discipline
- `shadcn-tailwind` - use when UI is built with shadcn/ui and Tailwind CSS
- `technical-context-discovery` - follow project Next.js conventions before editing
- `code-review` - validate routing, rendering, and integration quality
