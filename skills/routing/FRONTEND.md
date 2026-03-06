# FRONTEND Branch

## When to enter this branch
- Task involves UI components, views, screens, layouts, or visual presentation
- Task targets a frontend framework: React, Next.js, Vue, Nuxt, SwiftUI
- Task involves styling, design systems, design tokens, Tailwind CSS, shadcn/ui, Vuetify, PrimeVue
- Task involves accessibility (a11y), keyboard navigation, ARIA attributes
- Task involves frontend state management (hooks, composables, Pinia stores)
- Task involves UI verification or comparing implementation against a design spec
- Task involves Swift/SwiftUI localization, String Catalogs, or locale-aware UI
- Files being edited are `.tsx`, `.jsx`, `.vue`, `.swift`, `.css`, `.scss`, or component files

## When NOT to enter this branch
- Task is about APIs, server-side logic, or backend services — use BACKEND
- Task is about Dockerfiles, CI/CD, or deployment — use INFRA
- Task is about database schemas, SQL queries, or migrations — use DATA
- Task is about code review, architecture design, or analysis without a frontend scope — use WORKFLOW
- Task is about E2E test patterns, not UI implementation — use WORKFLOW

## Decision tree

For tasks matching this branch, read the next level:

| If the task involves... | Read next |
|-------------------------|-----------|
| React components, hooks, JSX, Next.js routing, server/client components | skills/routing/REACT.md |
| Vue components, composables, Nuxt routing, Pinia stores, Vuetify, PrimeVue | skills/routing/VUE.md |
| SwiftUI views, iOS 17+ MVVM, Swift localization, String Catalogs, Apple platforms | skills/routing/NATIVE.md |
| Framework-agnostic UI patterns, design system usage, accessibility, UI verification | skills/routing/GENERIC_UI.md |
| Unclear / cross-cutting frontend task | skills/routing/GENERIC_UI.md |

## Combination rules
- When implementing React UI against a design spec, load both `react` (or `react-nextjs`) and `ui-verification`
- When implementing Vue UI against a design spec, load both `vue` (or `nuxt`) and `ui-verification`
- When implementing SwiftUI UI against a design spec, load both `swiftui` and `ui-verification`
- `frontend-implementation` is always loaded together with any framework-specific skill when building new UI components
- `swift-localization` and `swiftui` are always loaded together when the task involves localized SwiftUI screens
- `shadcn-tailwind` and `react` are always loaded together when the UI uses shadcn/ui components
- `pinia` and `vue` are always loaded together when the task involves Vue store logic
- `vuetify-primevue` and `vue` are always loaded together when the task involves Vuetify or PrimeVue components
- `nuxt` and `vue` are always loaded together when the task involves Nuxt routing or app-level behavior
- Framework-specific skills (`react`, `vue`, `swiftui`) and library-specific skills (`shadcn-tailwind`, `vuetify-primevue`, `pinia`) are mutually exclusive across ecosystems — never combine React skills with Vue skills or vice versa
