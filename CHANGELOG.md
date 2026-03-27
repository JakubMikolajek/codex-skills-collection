# Changelog

## [1.3.0] - 2026-03-27

### Added
- Added new workflow skills: `test-strategy` and `session-learning`.
- Added `skills/routing/FAILURES.md` for failure-oriented skill routing.
- Added repository-level `LICENSE` and `ROADMAP.md`.

### Changed
- Updated `AGENTS.md` and `skills/routing/WORKFLOW.md` to include new workflow routing for added skills.
- Updated `README.md` project naming and repository overview text.

## [1.2.0] - 2026-03-18

### Added
- Added new workflow and platform skills for Python, API governance, reliability, and delivery (`python`, `python-fastapi`, `python-ai-ml`, `python-testing`, `api-contract`, `security-hardening`, `ci-cd`, `error-handling`, `observability`, `migration-strategy`, `product-intent`, `unit-testing`, `performance-profiling`, `monorepo-tooling`, `feature-flags`, `graphql`, `accessibility`).
- Added data and integration skills (`data-modeling`, `message-queue`, `websocket-realtime`) plus `i18n` and `kubernetes`.
- Added embedded domain support with a dedicated routing branch `skills/routing/EMBEDDED.md` and new skills (`c-embedded`, `embedded-toolchain`, `freertos`, `stm32-hal`).

### Changed
- Expanded routing coverage in `skills/routing/*` to include Python, AI pipelines, data/infrastructure skills, and embedded workflows.
- Updated shared template agent model in `templates/codex/agents/explorer.toml` to `gpt-5.3-codex`.
- Updated `AGENTS.md`, `README.md`, and `scripts/validate-routing-tree.sh` to reflect new routing/skill coverage and validation expectations.
- Refined skill docs in `skills/nestjs/SKILL.md`, `skills/code-review/SKILL.md`, `skills/frontend-implementation/SKILL.md`, and `skills/session-handoff/SKILL.md`.

### Removed
- Removed deprecated per-skill agent configs for `code-review`, `frontend-implementation`, and `nestjs` (`skills/*/agents/openai.yaml`).

## [1.1.0] - 2026-03-11

### Added
- Added routing-tree based skill navigation with new branch routers under `skills/routing/` (FRONTEND, BACKEND, INFRA, DATA, WORKFLOW, REACT, VUE, NATIVE, GENERIC_UI).
- Added new workflow skills: `debug-trace`, `session-handoff`, `changelog-generator`, `project-context`, `multi-repo`, and `skill-creator`.
- Added a dedicated `docker` skill and integrated it into routing and command handling.
- Added `scripts/validate-routing-tree.sh` to validate routing references, skill reachability, and skill frontmatter quality gates.
- Added shared Codex multi-agent templates under `templates/codex/`, including `config.toml` and `agents/*.toml`.
- Added bootstrap support for copying `.codex/config.toml` and `.codex/agents/*.toml` into downstream projects.
- Added multi-agent workflow guidance and examples in `AGENTS.md`.

### Changed
- Updated `scripts/bootstrap.sh` to bootstrap `.codex/AGENTS.md`, `.codex/skills/`, and `.codex/scripts/` (including executable script copy behavior), then improved overwrite/skip handling for copied `.codex` assets.
- Updated `AGENTS.md` and `README.md` with expanded command coverage, routing-first workflow documentation, and refreshed repository structure details.
- Performed README cleanup in follow-up commits to remove outdated sections and keep docs aligned with the Codex-first workflow.

## [1.0.0] - 2026-02-28

### Added
- Initial release of the Codex-first repository structure with core workflow documentation and base skill set.
- Initial frontend skill pack for Vue ecosystem (`vue`, `nuxt`, `pinia`, `vuetify-primevue`) and follow-up language/platform skills (`rust`, `swift-localization`, `docker`).

### Changed
- Established initial routing-first direction for skills, later expanded in subsequent releases.
