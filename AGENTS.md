# Codex Workflow Contract

This repository provides a Codex-first delivery workflow and reusable skills.

## Default Workflow

Always follow:

1. Research
2. Plan
3. Implement
4. Review

Do not skip phases unless the user explicitly asks to skip them.

## Commands

These command-like requests are supported:

- `/research <task-description>`
- `/plan <task-description>`
- `/docs-flow <task-description>`
- `/implement <task-description>`
- `/implement-ui <task-description>`
- `/review-ui`
- `/review <task-description>`
- `/e2e <task-description>`
- `/code-quality-check`

## Expected Outputs

- `/research`: Research summary, assumptions, identified gaps, clarification questions, and next-step recommendation.
- `/plan`: Phase-based implementation plan with acceptance criteria and explicit quality gates.
- `/docs-flow`: Structured documentation artifact plus execution flow artifact (Mermaid + phase checklist + gates).
- `/implement`: Scoped implementation aligned with the plan, including test evidence.
- `/implement-ui`: Iterative UI implementation with verification loop and mismatch fixes.
- `/review-ui`: Read-only PASS/FAIL verification report with precise diff table.
- `/review`: Findings-first review report ordered by severity (bugs, regressions, risk, test gaps).
- `/e2e`: Scenario list, Page Object and test implementation guidance, execution report expectations.
- `/code-quality-check`: Prioritized quality report with concrete action plan.

## Skills

Use the following skills from this repository:

- `architecture-design` (file: `skills/architecture-design/SKILL.md`)
- `code-review` (file: `skills/code-review/SKILL.md`)
- `codebase-analysis` (file: `skills/codebase-analysis/SKILL.md`)
- `dev-docs-flow` (file: `skills/dev-docs-flow/SKILL.md`)
- `e2e-testing` (file: `skills/e2e-testing/SKILL.md`)
- `frontend-implementation` (file: `skills/frontend-implementation/SKILL.md`)
- `implementation-gap-analysis` (file: `skills/implementation-gap-analysis/SKILL.md`)
- `kotlin` (file: `skills/kotlin/SKILL.md`)
- `nestjs` (file: `skills/nestjs/SKILL.md`)
- `nuxt` (file: `skills/nuxt/SKILL.md`)
- `pinia` (file: `skills/pinia/SKILL.md`)
- `react` (file: `skills/react/SKILL.md`)
- `react-nextjs` (file: `skills/react-nextjs/SKILL.md`)
- `rust` (file: `skills/rust/SKILL.md`)
- `shadcn-tailwind` (file: `skills/shadcn-tailwind/SKILL.md`)
- `sql-and-database` (file: `skills/sql-and-database/SKILL.md`)
- `swiftui` (file: `skills/swiftui/SKILL.md`)
- `task-analysis` (file: `skills/task-analysis/SKILL.md`)
- `technical-context-discovery` (file: `skills/technical-context-discovery/SKILL.md`)
- `ui-verification` (file: `skills/ui-verification/SKILL.md`)
- `vue` (file: `skills/vue/SKILL.md`)
- `vuetify-primevue` (file: `skills/vuetify-primevue/SKILL.md`)

## Trigger Rules

If a user explicitly names a skill (for example `architecture-design`), use that skill.

If a task clearly targets SwiftUI, Kotlin, Rust, React, Next.js, NestJS, Vue, Nuxt, Pinia, Vuetify/PrimeVue, or shadcn/ui + Tailwind, use the corresponding dedicated skill even when the user does not name it explicitly.

If a user uses command-style requests, route as follows:

- `/research` -> `task-analysis` + `codebase-analysis` (as needed)
- `/plan` -> `architecture-design` + `implementation-gap-analysis`
- `/docs-flow` -> `dev-docs-flow` (which composes dev skills contextually)
- `/implement` -> `technical-context-discovery` + `implementation-gap-analysis`; add `sql-and-database` when data/storage is involved; add `swiftui`, `kotlin`, `rust`, `react`, `react-nextjs`, `shadcn-tailwind`, `vue`, `nuxt`, `pinia`, `vuetify-primevue`, or `nestjs` when stack-specific
- `/implement-ui` -> `technical-context-discovery` + `frontend-implementation` + `ui-verification`; add `react`, `react-nextjs`, `shadcn-tailwind`, `vue`, `nuxt`, `vuetify-primevue`, or `swiftui` when framework-specific
- `/review-ui` -> `ui-verification`; add `react`, `react-nextjs`, `shadcn-tailwind`, `vue`, `nuxt`, `vuetify-primevue`, or `swiftui` when framework-specific
- `/review` -> `code-review` + `technical-context-discovery`; add `swiftui`, `kotlin`, `rust`, `react`, `react-nextjs`, `shadcn-tailwind`, `vue`, `nuxt`, `pinia`, `vuetify-primevue`, or `nestjs` when stack-specific
- `/e2e` -> `e2e-testing` + `technical-context-discovery`
- `/code-quality-check` -> `codebase-analysis` + `code-review`

## Escalation and Validation Rules

- Ask focused clarification questions only when required details are missing or ambiguous.
- Prefer discovering facts from the repository and tools before asking the user.
- For implementation tasks, run relevant tests and checks before handoff.
- For review tasks, report findings first and include residual risk/testing gaps.
- Keep outputs concise, explicit, and directly actionable.
