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
