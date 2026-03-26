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
- `/test-strategy <module-or-project>`
- `/learn`

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
- `/test-strategy`: `test-strategy.md` with risk map, test levels per zone, coverage targets, tooling, and quality gates.
- `/learn`: Appended entries in per-skill `references/failure-patterns.md` and global `skills/routing/FAILURES.md`.

## Skill Routing

All `skills/...` paths in this file and in routing/skill files are **relative to the directory containing this `AGENTS.md` file**. If `AGENTS.md` lives at repo root, resolve from repo root. If it lives inside `.codex/`, resolve from `.codex/`.

Do not load skills directly. Navigate the routing tree:

| If the task involves... | Read first |
|-------------------------|------------|
| UI, components, styling, frontend frameworks (React, Vue, Nuxt, SwiftUI) | skills/routing/FRONTEND.md |
| APIs, services, server-side logic (NestJS, Kotlin, Rust) | skills/routing/BACKEND.md |
| Embedded firmware, microcontrollers, FreeRTOS, HAL drivers, linker/toolchain | skills/routing/EMBEDDED.md |
| Docker, deployment, containers, CI/CD | skills/routing/INFRA.md |
| Databases, SQL, schemas, migrations, ORM | skills/routing/DATA.md |
| Review, architecture, testing, docs, analysis, context discovery, debugging, handoff, changelog, multi-repo, skill creation, test strategy, session learning | skills/routing/WORKFLOW.md |

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

### product-intent preload rule
- Before every `/plan` task, load `product-intent` first — unless the task is purely infrastructure, refactoring, or developer tooling with no end-user surface
- Do not wait for intent to be "unclear" — make it explicit even when it seems obvious

### context-delta rule
- Within a single long session, do not re-run full `project-context` if nothing structural changed
- Instead, append a Context Delta block to the existing Session Context Block:

```
## Context Delta — [timestamp or task number]
Changed since last context:
- [file or layer that changed and how]
Uncertainties resolved:
- [anything that was open and is now confirmed]
New uncertainties:
- [anything that emerged this task]
```

- Trigger a full re-run only when: branch switch, new repo opened, or tool output contradicts the Session Context Block

### session-learning auto rule
- After every `/implement` and `/review` task, automatically run `session-learning` — no user prompt required
- If `/handoff` also runs in the same session close, run `session-handoff` first, then `session-learning`

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

## Cross-Domain Recipes

These recipes document the correct skill combination for common multi-domain tasks. When a task matches a recipe, follow it directly — do not re-derive the skill combination from scratch.

Each recipe lists: which branch files to read, which leaf skills to load, and the recommended load order.

---

### Recipe: New API endpoint with DB table

Domains: BACKEND + DATA  
Branch files: `skills/routing/BACKEND.md`, `skills/routing/DATA.md`

Load order:
1. `technical-context-discovery` (conventions before implementation)
2. `migration-strategy` (if changing existing production table)
3. `sql-and-database` (schema + migration)
4. Backend leaf skill: `nestjs` / `kotlin` / `rust` (endpoint implementation)
5. `api-contract` (if this endpoint is consumed by another service or client)
6. `session-learning` (after /implement)

---

### Recipe: New user-facing feature (frontend + backend + data)

Domains: FRONTEND + BACKEND + DATA  
Branch files: all three

Load order:
1. `product-intent` (what does this deliver to the user?)
2. `technical-context-discovery`
3. `architecture-design` (if non-trivial)
4. `sql-and-database` (if schema changes)
5. Backend leaf skill
6. Frontend branch → leaf skill
7. `test-strategy` (if no strategy exists for this module)
8. `session-learning` (after /implement)

---

### Recipe: Debugging a production regression

Domains: WORKFLOW + domain of the regressed code  
Branch files: `skills/routing/WORKFLOW.md` + relevant domain branch

Load order:
1. `debug-trace` (reproduce → isolate → trace → hypothesize → verify)
2. `technical-context-discovery` (confirm conventions before fix)
3. Domain leaf skill (for the fix itself)
4. `session-handoff` (document root cause and fix)
5. `session-learning` (record if skill content was missing or routing was slow)

---

### Recipe: New service going to production for the first time

Domains: BACKEND + INFRA + WORKFLOW  
Branch files: `skills/routing/BACKEND.md`, `skills/routing/INFRA.md`, `skills/routing/WORKFLOW.md`

Load order:
1. `test-strategy` (define coverage before wiring CI)
2. `observability` (logging, metrics, health endpoint — before first deploy)
3. `ci-cd` (pipeline + quality gates)
4. `docker` / `kubernetes` (container and deployment config)
5. `security-hardening` (supplement every backend review)
6. `session-handoff` + `session-learning` after deploy

---

### Recipe: Cross-repo contract change (API owner + consumer)

Domains: WORKFLOW + BACKEND + FRONTEND  
Branch files: all three

Load order:
1. `project-context` per repo
2. `multi-repo` (change plan with contract-owner-first ordering)
3. Owner repo: `api-contract` + backend leaf skill
4. Consumer repo: frontend branch → leaf skill
5. `session-handoff` (mandatory for multi-repo)
6. `session-learning`

---

### Recipe: Performance investigation

Domains: WORKFLOW + domain of the slow code  
Branch files: `skills/routing/WORKFLOW.md` + relevant domain branch

Load order:
1. `performance-profiling` (flamegraph, latency, memory — before touching code)
2. Domain leaf skill (for the fix)
3. `observability` (if metrics are missing that would have caught this earlier)
4. `session-learning`

---

### Adding a new recipe

When a multi-domain task required non-obvious skill combination that is likely to recur, add it here. Minimum content: domains, branch files, load order. Use `session-learning` MISSING entries as input.

---

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
