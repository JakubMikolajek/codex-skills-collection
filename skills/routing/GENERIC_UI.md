# GENERIC UI Stack Sub-Branch

## When to enter this branch
- Task involves framework-agnostic frontend patterns: accessibility, design systems, component architecture
- Task involves UI verification: comparing implementation against a design spec or mockup
- Task involves design token mapping, semantic markup, keyboard navigation, ARIA patterns
- Task does not target a specific framework, or the framework-specific sub-branch has already been loaded and this is loaded as a supplement

## When NOT to enter this branch
- Task is specifically about React, Next.js, or shadcn/ui — use skills/routing/REACT.md first, then add GENERIC_UI skills as supplements
- Task is specifically about Vue, Nuxt, Pinia, or Vuetify/PrimeVue — use skills/routing/VUE.md first, then add GENERIC_UI skills as supplements
- Task is specifically about SwiftUI or Swift localization — use skills/routing/NATIVE.md first, then add GENERIC_UI skills as supplements
- Task is about backend, infra, or data — use the appropriate domain branch

## Decision tree

For tasks matching this branch, load the appropriate leaf skill(s):

| If the task involves... | Read next |
|-------------------------|-----------|
| UI component patterns, accessibility, design system usage, performance guidelines | skills/frontend-implementation/SKILL.md |
| UI verification, design spec comparison, pixel-level accuracy, mismatch reporting | skills/ui-verification/SKILL.md |
| Both implementation patterns and verification | Load both skills |
| Unclear / general frontend guidance | skills/frontend-implementation/SKILL.md |

## Combination rules
- `frontend-implementation` and `ui-verification` can be loaded independently or together
- `frontend-implementation` is commonly loaded alongside any framework-specific skill (`react`, `vue`, `swiftui`) when building new UI components
- `ui-verification` is commonly loaded alongside any framework-specific skill when verifying implementation against designs
- For `/implement-ui` command, load `frontend-implementation` + `ui-verification` + the appropriate framework skill from another sub-branch
- For `/review-ui` command, load `ui-verification` + the appropriate framework skill from another sub-branch
- These skills are never loaded alone for implementation tasks — they supplement framework-specific skills
