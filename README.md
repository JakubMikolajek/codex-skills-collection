# Codex Skills Collections

Codex setup for delivery teams with shared workflow commands and reusable skills.

Focus on feature delivery while keeping execution consistent across projects.

## About

This repository is a reusable Codex operating model:

- process contract (`Research -> Plan -> Implement -> Review`)
- routing-first skill loading model
- shared templates for multi-agent execution

It is designed to be bootstrapped into downstream projects via `scripts/bootstrap.sh`.

## What This Repository Provides

- Shared delivery workflow: `Research -> Plan -> Implement -> Review`
- Command-style interaction model for common delivery tasks
- Reusable Codex skills stored in-repo
- Shared multi-agent template stored under `templates/codex/` for downstream bootstrap into `.codex/`
- Local-first workflow without external tracker/design integrations

## Workflow

Standard sequence:

1. `/research <task-description>`
2. `/plan <task-description>`
3. `/docs-flow <task-description>` (optional docs + flow artifact)
4. `/implement <task-description>`
5. `/review <task-description>`

Frontend-heavy flow:

1. `/research <task-description>`
2. `/plan <task-description>`
3. `/implement-ui <task-description>`
4. `/review <task-description>`

E2E flow:

1. `/research <task-description>`
2. `/plan <task-description>`
3. `/e2e <task-description>`

## Supported Commands

- `/research`: Research summary + assumptions + gaps + questions
- `/plan`: Phase-based implementation plan + acceptance criteria
- `/docs-flow`: Structured docs artifact + execution flow (Mermaid + checklist + gates)
- `/implement`: Plan-aligned implementation + test evidence
- `/implement-ui`: UI implementation with iterative verification loop
- `/review-ui`: Read-only PASS/FAIL verification with structured differences
- `/review`: Findings-first review with severity and risk
- `/e2e`: E2E scenarios, Page Objects, fixtures, and execution expectations
- `/code-quality-check`: Prioritized quality report and action plan
- `/debug`: Debug Report (reproduce → isolate → trace → hypothesize → verify) + root-cause fix
- `/handoff`: `.codex-handoff.md` with status, decisions, files, next steps
- `/changelog`: CHANGELOG block in Keep a Changelog format + version bump recommendation
- `/context`: Session Context Block (stack, runner, conventions, constraints)
- `/new-skill`: Scaffold SKILL.md + update routing tree
- `/multi-repo`: Per-repo change plan with contract-owner-first ordering + mandatory handoff
- `/test-strategy`: Risk-based test plan with levels, targets, and quality gates
- `/learn`: Append session learnings into per-skill and global failure pattern logs

## Skills Included

All skills live under `skills/` and are routed through `skills/routing/`:

### Domain Skills

- `docker` — Dockerfiles, Compose, multi-stage builds, CI images
- `c-embedded` — Embedded C patterns: volatile, ISR safety, memory/bitwise discipline
- `embedded-toolchain` — CMake cross-compilation, linker scripts, GCC toolchains, OpenOCD
- `freertos` — Task architecture, queues, semaphores, mutexes, timers, stack sizing
- `kotlin` — Kotlin domain modeling, coroutines, null-safety
- `nestjs` — NestJS modules, controllers, services, DTOs
- `react` — React components, hooks, state, forms, rendering
- `react-nextjs` — Next.js routing, server/client components, data fetching
- `rust` — Rust ownership, async, Tauri, systems logic
- `tauri-window-shell` — Tauri window shell UX (titlebar, drag regions, maximize/minimize, bounds)
- `tauri-command-contract` — Frontend `invoke` <-> Rust `#[tauri::command]` contracts
- `tauri-plugin-integration` — Tauri plugin wiring, permissions/capabilities, drift checks
- `tauri-runtime-lifecycle` — Tauri runtime managers, startup/shutdown, cancellation, lifecycle safety
- `shadcn-tailwind` — shadcn/ui components, Tailwind CSS utilities
- `sql-and-database` — SQL schema design, normalization, indexes, migrations, ORM
- `swift-localization` — Swift String Catalogs, pluralization, locale-aware formatting
- `swiftui` — SwiftUI views, MVVM, Observation API, Factory DI
- `stm32-hal` — STM32 HAL/LL drivers, CubeMX integration, DMA/interrupt patterns
- `vue` — Vue 3 Composition API, composables, reactivity
- `nuxt` — Nuxt 3 routing, SSR, middleware, composables
- `pinia` — Pinia stores, shared state, async actions
- `vuetify-primevue` — Vuetify/PrimeVue component composition, theming

### Cross-Cutting Skills

- `frontend-implementation` — UI patterns, accessibility, design system usage
- `ui-verification` — Design spec comparison, pixel-level verification
- `architecture-design` — Solution architecture, implementation planning
- `code-review` — Code review, quality analysis, best practices
- `codebase-analysis` — Full codebase audit, dependencies, architecture
- `dev-docs-flow` — Documentation + execution flow artifacts
- `e2e-testing` — E2E test patterns, Page Objects, CI readiness
- `implementation-gap-analysis` — Plan-vs-code comparison
- `task-analysis` — Task research, context gathering, PRD
- `technical-context-discovery` — Project conventions, patterns, standards

### New Workflow Skills

- `skill-creator` — Scaffold new skills, wire into routing tree
- `project-context` — Build structured project understanding at session start
- `session-handoff` — Produce structured handoff documents at session end
- `session-learning` — Capture what worked/failed in skill routing and content after each session
- `test-strategy` — Define risk-based test strategy before implementation/testing
- `changelog-generator` — Generate CHANGELOG entries from git/PR/handoff
- `multi-repo` — Coordinate changes spanning multiple repositories
- `debug-trace` — Structured root cause analysis before writing fixes

Each skill includes:

- `SKILL.md` with triggerable instructions
- optional `references/` for examples/templates

## Skill Routing

Skills are not loaded directly from `AGENTS.md`. Instead, the agent navigates a routing tree:

```
AGENTS.md (Root Router)
└── skills/routing/
    ├── FRONTEND.md → REACT.md / VUE.md / NATIVE.md / GENERIC_UI.md → leaf skills
    ├── BACKEND.md → nestjs / kotlin / rust
    ├── TAURI.md → tauri-window-shell / tauri-command-contract / tauri-plugin-integration / tauri-runtime-lifecycle / rust
    ├── EMBEDDED.md → c-embedded / freertos / stm32-hal / embedded-toolchain
    ├── INFRA.md → docker
    ├── DATA.md → sql-and-database
    └── WORKFLOW.md → all cross-cutting and workflow skills
```

## Repository Structure

```text
.
├── AGENTS.md
├── templates/
│   └── codex/
│       ├── config.toml
│       └── agents/
├── skills/
│   ├── routing/
│   │   ├── FRONTEND.md
│   │   ├── BACKEND.md
│   │   ├── TAURI.md
│   │   ├── EMBEDDED.md
│   │   ├── INFRA.md
│   │   ├── DATA.md
│   │   ├── WORKFLOW.md
│   │   ├── REACT.md
│   │   ├── VUE.md
│   │   ├── NATIVE.md
│   │   └── GENERIC_UI.md
│   ├── architecture-design/
│   ├── changelog-generator/
│   ├── code-review/
│   ├── codebase-analysis/
│   ├── debug-trace/
│   ├── dev-docs-flow/
│   ├── docker/
│   ├── e2e-testing/
│   ├── embedded-toolchain/
│   ├── c-embedded/
│   ├── freertos/
│   ├── frontend-implementation/
│   ├── implementation-gap-analysis/
│   ├── kotlin/
│   ├── multi-repo/
│   ├── nestjs/
│   ├── nuxt/
│   ├── pinia/
│   ├── project-context/
│   ├── react/
│   ├── react-nextjs/
│   ├── rust/
│   ├── tauri-window-shell/
│   ├── tauri-command-contract/
│   ├── tauri-plugin-integration/
│   ├── tauri-runtime-lifecycle/
│   ├── session-handoff/
│   ├── session-learning/
│   ├── shadcn-tailwind/
│   ├── skill-creator/
│   ├── sql-and-database/
│   ├── stm32-hal/
│   ├── swift-localization/
│   ├── swiftui/
│   ├── task-analysis/
│   ├── technical-context-discovery/
│   ├── test-strategy/
│   ├── ui-verification/
│   ├── vue/
│   └── vuetify-primevue/
├── CHANGELOG.md
└── README.md
```

## Scope

This repository currently assumes no required external integrations.
All workflows should be executable from task descriptions, local files, and repository context.

## Getting Started

Clone repository:

```bash
git clone <this-repo-url> codex-skills-collections
cd codex-skills-collections
```

## Bootstrap Into Another Project

Use the bootstrap script from this repository to copy the Codex setup into an existing project.

Bootstrap writes the following into the target project's `.codex/` directory:

- `AGENTS.md`
- `skills/`
- `scripts/`
- `config.toml`
- `agents/*.toml`

```bash
./scripts/bootstrap.sh /path/to/your-project
```

Useful options:

- `--dry-run` to preview changes
- `--force` to overwrite existing `.codex/AGENTS.md`, `.codex/config.toml`, agent templates, and replace existing skill directories

Examples:

```bash
./scripts/bootstrap.sh /path/to/your-project --dry-run
./scripts/bootstrap.sh /path/to/your-project --force
```

## Versioning and Releases

- Versioning follows SemVer (`MAJOR.MINOR.PATCH`).
- Release history is tracked in `CHANGELOG.md`.
- New skills and routing-capability expansions are treated as minor releases.
- Fix-only updates are patch releases.

## Roadmap

High-level update plan is tracked in [`ROADMAP.md`](ROADMAP.md).

## License

Licensed under the [MIT License](LICENSE).
