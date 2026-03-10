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
- `/debug <bug-description>`
- `/handoff`
- `/changelog`
- `/context`
- `/new-skill <skill-name>`
- `/multi-repo <task-description>`

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
- `/debug`: Debug Report (reproduce → isolate → trace → hypothesize → verify) followed by root-cause fix with regression test.
- `/handoff`: `.codex-handoff.md` with status, in-progress, blocked, decisions, files modified, next steps, open questions.
- `/changelog`: CHANGELOG block in Keep a Changelog format with version bump recommendation.
- `/context`: Session Context Block (stack, test runner, package manager, conventions, constraints, uncertainties).
- `/new-skill`: Scaffolded SKILL.md with quality gates enforced, routing tree updated in same task.
- `/multi-repo`: Per-repo change plan with contract-owner-first ordering, cross-repo impact map, mandatory handoff.

## Skill Routing

All `skills/...` paths in this file and in routing/skill files are **relative to the directory containing this `AGENTS.md` file**. If `AGENTS.md` lives at repo root, resolve from repo root. If it lives inside `.codex/`, resolve from `.codex/`.

Do not load skills directly. Navigate the routing tree:

| If the task involves... | Read first |
|-------------------------|------------|
| UI, components, styling, frontend frameworks (React, Vue, Nuxt, SwiftUI) | skills/routing/FRONTEND.md |
| APIs, services, server-side logic (NestJS, Kotlin, Rust) | skills/routing/BACKEND.md |
| Docker, deployment, containers, CI/CD | skills/routing/INFRA.md |
| Databases, SQL, schemas, migrations, ORM | skills/routing/DATA.md |
| Review, architecture, testing, docs, analysis, context discovery, debugging, handoff, changelog, multi-repo, skill creation | skills/routing/WORKFLOW.md |

### Routing rules
- Always read the branch file BEFORE loading any skill
- Never load a skill directly from this file — always go through the branch
- If a task spans 2 domains, read both branch files, then load only the leaf skills that apply
- If no branch matches, read skills/routing/WORKFLOW.md as fallback
- If a user explicitly names a skill by name, you may load it directly as an override

### Preload rule
- Before any non-trivial `/implement`, `/review`, or `/debug` task, always load `project-context` (for session-start context) or `technical-context-discovery` (for per-task conventions) first
- This rule is enforced at root level — domain branches do not repeat it
- Simple one-line answers and clarification questions are exempt

### Routing examples

**Example 1: `/debug` — Nuxt page shows wrong data**
`AGENTS.md` → WORKFLOW.md → `debug-trace` + `technical-context-discovery`
After Debug Report: FRONTEND.md → VUE.md → `vue` + `nuxt` (for the fix)

**Example 2: `/implement` — NestJS endpoint with new DB table**
`AGENTS.md` → BACKEND.md → `nestjs` + WORKFLOW.md → `technical-context-discovery`
Also: DATA.md → `sql-and-database` (cross-domain — two branches read)

**Example 3: `/multi-repo` — API contract change + frontend consumer update**
`AGENTS.md` → WORKFLOW.md → `multi-repo` + `project-context` (per repo)
Owner repo: BACKEND.md → `nestjs`
Consumer repo: FRONTEND.md → REACT.md → `react` + `react-nextjs`
End: `session-handoff` (mandatory)

## Escalation and Validation Rules

- Ask focused clarification questions only when required details are missing or ambiguous.
- Prefer discovering facts from the repository and tools before asking the user.
- For implementation tasks, run relevant tests and checks before handoff.
- For review tasks, report findings first and include residual risk/testing gaps.
- Keep outputs concise, explicit, and directly actionable.

## Multi-Agent Workflows

### 1. Roll out the shared multi-agent template in this repo

**Prompt**
`Implement the shared multi-agent template for this repository.`

**Spawn order**
- Parallel: `explorer` maps the routing tree, current workflow contract, and template injection surface; `auditor` checks current bootstrap and workflow risks
- Sequential: `planner` turns those findings into the final role split and validation gates
- Parallel: `builder_backend` updates bootstrap/template wiring while `coordinator` updates docs and evaluation scenarios
- Sequential: `auditor` runs the final read-only quality gate

**Responsibilities**
- `explorer`: identify source files, template locations, and any routing constraints that must stay intact
- `planner`: lock role boundaries, handoffs, and validation criteria
- `builder_backend`: implement script and template-copy logic
- `coordinator`: update docs, workflows, and evaluation artifacts
- `auditor`: review correctness, overwrite behavior, and residual risk

**Consolidated output**
- Template files added under `templates/codex/`
- Bootstrap support for injecting target `.codex/config.toml` and `.codex/agents/*.toml`
- Updated docs and validation summary

### 2. Review a branch that changes routing, skills, and bootstrap

**Prompt**
`Review this branch against main. Focus on routing correctness, skill reachability, and bootstrap safety.`

**Spawn order**
- Parallel: `explorer` + `auditor`
- Sequential: `planner` only if the branch appears to break the workflow contract or routing logic

**Responsibilities**
- `explorer`: map affected routing branches, skills, and bootstrap paths
- `auditor`: report correctness, regression, security, and missing-test findings ordered by severity
- `planner`: decide whether the branch creates deeper architecture or contract issues

**Consolidated output**
- Findings-first review report with affected files
- Explicit note on whether the Research -> Plan -> Implement -> Review flow still holds

### 3. Debug bootstrap failures in a target project

**Prompt**
`Investigate why bootstrap.sh copied AGENTS and skills but the target project still lacks a working multi-agent setup.`

**Spawn order**
- Parallel: `explorer` traces the script and target paths while `auditor` reproduces and isolates the failure
- Sequential: `builder_backend` implements the smallest defensible fix
- Sequential: `auditor` verifies the fix and any overwrite edge cases

**Responsibilities**
- `explorer`: map source template paths, destination `.codex/` paths, and overwrite behavior
- `auditor`: complete `Reproduce -> Isolate -> Trace -> Hypothesize -> Verify` before any code change
- `builder_backend`: patch the script without changing unrelated workflow behavior

**Consolidated output**
- Root cause summary
- Minimal bootstrap fix
- Validation notes for dry-run and real copy modes

### 4. Add a new skill and wire it into routing

**Prompt**
`Create a new skill, place it in the routing tree, and make sure it bootstraps cleanly into downstream projects.`

**Spawn order**
- Parallel: `explorer` audits overlap in existing skills while `planner` checks where the new capability belongs
- Sequential: `coordinator` scaffolds the skill, updates routing, and adjusts any bootstrap-facing docs
- Sequential: `auditor` verifies reachability and duplication risk

**Responsibilities**
- `explorer`: find similar skills and combination rules that already exist
- `planner`: validate domain placement and required handoffs
- `coordinator`: scaffold files, update routing, and keep reachability intact in the same task
- `auditor`: verify no duplicate scope or missing routing path remains

**Consolidated output**
- New skill files
- Updated routing entries
- Verification that the skill is reachable from `AGENTS.md`

### 5. Prepare a release after workflow and bootstrap changes

**Prompt**
`Prepare the next release after routing, skill, template, and bootstrap updates.`

**Spawn order**
- Parallel: `explorer` summarizes shipped surface area while `auditor` checks for release-blocking risks
- Sequential: `coordinator` writes the handoff and changelog artifacts

**Responsibilities**
- `explorer`: summarize what changed and where
- `auditor`: flag release blockers, missing validations, or regression risk
- `coordinator`: generate handoff status and changelog-ready release notes

**Consolidated output**
- Release-focused summary of shipped changes
- Handoff document and changelog draft
- Residual risks that must be resolved before tagging
