# FRONTEND Branch

## When to enter this branch
- Task involves UI components, views, screens, layouts, or visual presentation
- Task targets a frontend framework: React, Next.js, Vue, Nuxt, SwiftUI
- Task involves styling, design systems, design tokens, Tailwind CSS, shadcn/ui, Vuetify, PrimeVue
- Task involves accessibility (a11y), keyboard navigation, ARIA attributes
- Task involves frontend state management (hooks, composables, Pinia stores)
- Task involves UI verification or comparing implementation against a design spec
- Task involves web internationalization (i18n), locale routing, or translation files
- Task involves Swift/SwiftUI localization, String Catalogs, or locale-aware Apple platform UI
- Files being edited are `.tsx`, `.jsx`, `.vue`, `.swift`, `.css`, `.scss`, or component files

## When NOT to enter this branch
- Task is about APIs, server-side logic, or backend services — use BACKEND
- Task is about Dockerfiles, CI/CD, or deployment — use INFRA
- Task is about database schemas, SQL queries, or migrations — use DATA
- Task is about code review, architecture design, or analysis without a frontend scope — use WORKFLOW
- Task is about E2E test patterns, not UI implementation — use WORKFLOW

## Decision tree

| If the task involves... | Read next |
|---|---|
| React components, hooks, JSX, Next.js routing, server/client components | skills/routing/REACT.md |
| Vue components, composables, Nuxt routing, Pinia, Vuetify, PrimeVue | skills/routing/VUE.md |
| SwiftUI views, iOS 17+ MVVM, Swift localization, Apple platforms | skills/routing/NATIVE.md |
| Web i18n, i18next, ICU messages, locale routing, translation files | skills/i18n/SKILL.md |
| Framework-agnostic UI, accessibility, design system, UI verification, unit tests | skills/routing/GENERIC_UI.md |
| Unclear / cross-cutting frontend task | skills/routing/GENERIC_UI.md |

## Combination rules
- `i18n` combines with any framework skill when adding multi-language support
- `frontend-implementation` always loaded alongside framework skills when building new UI
- `accessibility` loaded alongside framework skills for any interactive custom components
- When implementing React UI against a design spec, load `react` + `ui-verification` + `accessibility`
- When implementing Vue UI against a design spec, load `vue` + `ui-verification` + `accessibility`
- `shadcn-tailwind` + `react` when the UI uses shadcn/ui components
- `pinia` + `vue` when the task involves Vue store logic
- `nuxt` + `vue` for Nuxt routing or app-level behavior
- `swift-localization` + `swiftui` for localized SwiftUI screens
- Framework skills are mutually exclusive across ecosystems — never combine React and Vue skills
