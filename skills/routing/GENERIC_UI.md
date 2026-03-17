# GENERIC UI Stack Sub-Branch

## When to enter this branch
- Task involves framework-agnostic frontend patterns: accessibility, design systems, component architecture
- Task involves UI verification: comparing implementation against a design spec or mockup
- Task involves design token mapping, semantic markup, keyboard navigation, ARIA patterns
- Task involves WCAG 2.1 AA compliance, screen reader compatibility, focus management
- Task involves unit or component tests for UI (React Testing Library, Vitest/Jest)
- Task does not target a specific framework, or the framework-specific sub-branch has already been loaded and this is loaded as a supplement

## When NOT to enter this branch
- Task is specifically about React, Next.js, or shadcn/ui — use skills/routing/REACT.md first, then add GENERIC_UI skills as supplements
- Task is specifically about Vue, Nuxt, Pinia, or Vuetify/PrimeVue — use skills/routing/VUE.md first, then add GENERIC_UI skills as supplements
- Task is specifically about SwiftUI or Swift localization — use skills/routing/NATIVE.md first, then add GENERIC_UI skills as supplements
- Task is about backend, infra, or data — use the appropriate domain branch

## Decision tree

For tasks matching this branch, load the appropriate leaf skill(s):

| If the task involves... | Read next |
|---|---|
| UI component patterns, design system usage, performance guidelines | skills/frontend-implementation/SKILL.md |
| WCAG 2.1 AA, ARIA, keyboard navigation, screen reader, focus management | skills/accessibility/SKILL.md |
| UI verification, design spec comparison, pixel-level accuracy | skills/ui-verification/SKILL.md |
| Unit tests, component tests, React Testing Library, Vitest/Jest | skills/unit-testing/SKILL.md |
| Unclear / general frontend guidance | skills/frontend-implementation/SKILL.md |

## Combination rules
- `accessibility` supplements every frontend implementation task — load alongside `frontend-implementation` whenever interactive components are being built
- `frontend-implementation` and `ui-verification` can be loaded independently or together
- `unit-testing` loaded when task includes writing or reviewing component tests
- For `/implement-ui` command, load `frontend-implementation` + `ui-verification` + `accessibility` + the appropriate framework skill
- For `/review-ui` command, load `ui-verification` + `accessibility` + the appropriate framework skill
- For `/a11y` or accessibility audit, load `accessibility` alone or with the relevant framework skill
- `frontend-implementation` is commonly loaded alongside any framework-specific skill (`react`, `vue`, `swiftui`) when building new UI components
- `ui-verification` is commonly loaded alongside any framework-specific skill when verifying implementation against designs
- `accessibility` is commonly loaded alongside `react` or `vue` for any feature with custom interactive components (modals, menus, comboboxes)
