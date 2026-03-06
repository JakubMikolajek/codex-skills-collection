# VUE Stack Sub-Branch

## When to enter this branch
- Task involves Vue 3 components, Composition API, composables, or reactive state
- Task involves Nuxt 3: routing, SSR, server APIs, middleware, runtime config, SEO
- Task involves Pinia stores, shared state, setup stores, async actions
- Task involves Vuetify or PrimeVue component composition, theming, forms
- Files being edited are `.vue`, Nuxt route files, Pinia store files, or Vue composables

## When NOT to enter this branch
- Task involves React, Next.js, JSX, or shadcn/ui — use skills/routing/REACT.md
- Task involves SwiftUI, iOS, or Apple platforms — use skills/routing/NATIVE.md
- Task is framework-agnostic UI guidance or UI verification only — use skills/routing/GENERIC_UI.md
- Task is about backend logic (not frontend Vue) — use skills/routing/BACKEND.md

## Decision tree

For tasks matching this branch, load the appropriate leaf skill(s):

| If the task involves... | Read next |
|-------------------------|-----------|
| Vue components, composables, reactive state, templates, accessibility | skills/vue/SKILL.md |
| Nuxt 3 routing, SSR, data fetching, middleware, composables, SEO | skills/nuxt/SKILL.md |
| Pinia stores, shared state, async actions, store design | skills/pinia/SKILL.md |
| Vuetify or PrimeVue components, theming, forms, responsive behavior | skills/vuetify-primevue/SKILL.md |
| General Vue work without Nuxt, Pinia, or UI library specifics | skills/vue/SKILL.md |

## Combination rules
- `vue` is always loaded together with `nuxt` when the task is Nuxt-specific — `vue` provides component discipline, `nuxt` provides routing/rendering rules
- `vue` is always loaded together with `pinia` when the task involves store logic
- `vue` is always loaded together with `vuetify-primevue` when the task uses Vuetify or PrimeVue components
- For Nuxt + Pinia tasks, load all three: `vue` + `nuxt` + `pinia`
- For Nuxt + Vuetify/PrimeVue tasks, load: `vue` + `nuxt` + `vuetify-primevue`
- When implementing UI against a design spec, also load `frontend-implementation` and `ui-verification` from GENERIC_UI
- `vue` skills are mutually exclusive with `react`, `react-nextjs`, `shadcn-tailwind`, `swiftui`, and `swift-localization`
