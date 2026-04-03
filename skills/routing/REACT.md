# REACT Stack Sub-Branch

## When to enter this branch
- Task involves React components, hooks, JSX, or client-side React state
- Task involves Next.js: App Router, Pages Router, server components, client components, route handlers, server actions
- Task involves shadcn/ui components, Radix primitives, Tailwind CSS utility classes in a React context
- Files being edited are `.tsx`, `.jsx`, or Next.js route/layout/page files

## When NOT to enter this branch
- Task involves Vue, Nuxt, Pinia, Vuetify, or PrimeVue — use skills/routing/VUE.md
- Task involves SwiftUI, iOS, or Apple platforms — use skills/routing/NATIVE.md
- Task is framework-agnostic UI guidance or UI verification only — use skills/routing/GENERIC_UI.md
- Task is about backend Node.js/NestJS logic (not frontend React) — use skills/routing/BACKEND.md
- Task crosses React + Rust boundary in a Tauri app (invoke contracts, plugin/runtime coupling) — use skills/routing/TAURI.md

## Decision tree

For tasks matching this branch, load the appropriate leaf skill(s):

| If the task involves... | Read next |
|-------------------------|-----------|
| React components, hooks, state, forms, rendering, accessibility | skills/react/SKILL.md |
| Next.js routing, server/client components, data fetching, metadata, caching | skills/react-nextjs/SKILL.md |
| shadcn/ui components, Tailwind CSS, component variants, utility hygiene | skills/shadcn-tailwind/SKILL.md |
| React in Tauri desktop app (window shell + runtime boundary) | skills/routing/TAURI.md |
| General React work without Next.js or shadcn specifics | skills/react/SKILL.md |

## Combination rules
- `react` and `react-nextjs` are always loaded together when the task is about Next.js — `react` provides component discipline, `react-nextjs` provides routing/rendering rules
- `shadcn-tailwind` is always loaded together with `react` when the UI uses shadcn/ui — never load `shadcn-tailwind` without `react`
- For React tasks inside Tauri desktop apps, route through `TAURI` branch to select `tauri-window-shell` / `tauri-command-contract` / `tauri-runtime-lifecycle` as needed
- For Next.js + shadcn/ui tasks, load all three: `react` + `react-nextjs` + `shadcn-tailwind`
- When implementing UI against a design spec, also load `frontend-implementation` and `ui-verification` from GENERIC_UI
- `react` skills are mutually exclusive with `vue`, `nuxt`, `pinia`, `vuetify-primevue`, `swiftui`, and `swift-localization`
