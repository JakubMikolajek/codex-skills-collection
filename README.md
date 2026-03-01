# Codex Collections

Opinionated Codex setup for delivery teams with shared workflow commands and reusable skills.

Focus on feature delivery while keeping execution consistent across projects.

## What This Repository Provides

- Shared delivery workflow: `Research -> Plan -> Implement -> Review`
- Command-style interaction model for common delivery tasks
- Reusable Codex skills stored in-repo
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

## Skills Included

All skills live under `skills/`:

- `architecture-design`
- `code-review`
- `codebase-analysis`
- `dev-docs-flow`
- `e2e-testing`
- `frontend-implementation`
- `implementation-gap-analysis`
- `kotlin`
- `nestjs`
- `nuxt`
- `pinia`
- `react`
- `react-nextjs`
- `rust`
- `shadcn-tailwind`
- `sql-and-database`
- `swiftui`
- `task-analysis`
- `technical-context-discovery`
- `ui-verification`
- `vue`
- `vuetify-primevue`

Each skill includes:

- `SKILL.md` with triggerable instructions
- `agents/openai.yaml` with UI metadata
- optional `references/` for examples/templates

## Repository Structure

```text
.
├── AGENTS.md
├── skills/
│   ├── architecture-design/
│   ├── code-review/
│   ├── codebase-analysis/
│   ├── dev-docs-flow/
│   ├── e2e-testing/
│   ├── frontend-implementation/
│   ├── implementation-gap-analysis/
│   ├── kotlin/
│   ├── nestjs/
│   ├── nuxt/
│   ├── pinia/
│   ├── react/
│   ├── react-nextjs/
│   ├── rust/
│   ├── shadcn-tailwind/
│   ├── sql-and-database/
│   ├── swiftui/
│   ├── task-analysis/
│   ├── technical-context-discovery/
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

1. Clone repository:

```bash
git clone <this-repo-url> codex-collections
cd codex-collections
```

2. Open the repository in your Codex environment.
3. Start with `/research <task>` and follow the workflow.
4. Use `AGENTS.md` as the source of command routing and skill usage rules.

## Bootstrap Into Another Project

Use the bootstrap script from this repository to copy the Codex setup into an existing project.

```bash
./scripts/bootstrap.sh /path/to/your-project
```

Useful options:

- `--dry-run` to preview changes
- `--force` to overwrite existing `AGENTS.md` and replace existing skill directories

Examples:

```bash
./scripts/bootstrap.sh /path/to/your-project --dry-run
./scripts/bootstrap.sh /path/to/your-project --force
```

## Migration Notes

This repository is now Codex-first.

Removed from previous setup:

- Legacy agent and prompt bundles
- External integration-first workflow assumptions

Replaced with:

- `AGENTS.md` workflow and routing contract
- In-repo Codex skills under `skills/`
- Local-first, task-description driven execution

## License

This project is licensed under the MIT License.
