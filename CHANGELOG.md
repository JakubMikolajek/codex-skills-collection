# Changelog

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
