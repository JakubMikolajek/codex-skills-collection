# WORKFLOW Branch

## When to enter this branch
- Task involves code review, architecture design, or implementation planning
- Task involves codebase analysis, quality checks, or dead code detection
- Task involves research, task analysis, or context gathering
- Task involves documentation generation or execution flow artifacts
- Task involves E2E testing patterns, test writing, or test debugging
- Task involves implementation gap analysis or plan-vs-code comparison
- Task involves technical context discovery before implementation
- Task involves creating or extending a skill, updating routing tree
- Task involves building project context at session start
- Task involves session wrap-up, handoff, or pause
- Task involves changelog generation, release prep, or sprint close
- Task involves changes spanning multiple repositories
- Task involves debugging, tracing errors, or root cause analysis
- Task involves clarifying user goals, writing acceptance criteria, or verifying feature value
- User uses command-style requests: `/research`, `/plan`, `/docs-flow`, `/review`, `/e2e`, `/code-quality-check`, `/debug`, `/handoff`, `/changelog`, `/context`, `/new-skill`, `/multi-repo`, `/intent`

## When NOT to enter this branch
- Task is about implementing frontend UI — use FRONTEND
- Task is about implementing backend logic — use BACKEND
- Task is about writing Dockerfiles or deployment — use INFRA
- Task is about writing SQL or designing schemas — use DATA
- Task is about implementing code (not reviewing or planning it) — use the appropriate domain branch

## Decision tree

For tasks matching this branch, read the next level:

| If the task involves... | Read next |
|-------------------------|-----------| 
| `/intent`, feature purpose is unclear, "what should this do", acceptance criteria needed | skills/product-intent/SKILL.md |
| `/research`, task analysis, context gathering, PRD creation | skills/task-analysis/SKILL.md |
| `/plan`, architecture design, solution planning, implementation phases | skills/architecture-design/SKILL.md |
| `/docs-flow`, documentation artifacts, execution flow generation | skills/dev-docs-flow/SKILL.md |
| `/review`, code review, quality analysis, best practices verification | skills/code-review/SKILL.md |
| `/code-quality-check`, full codebase audit, dependency analysis, dead code | skills/codebase-analysis/SKILL.md |
| `/e2e`, E2E test writing, Page Objects, flaky test debugging, CI readiness | skills/e2e-testing/SKILL.md |
| Implementation gap analysis, plan-vs-code comparison | skills/implementation-gap-analysis/SKILL.md |
| Technical context discovery, project conventions, pattern analysis | skills/technical-context-discovery/SKILL.md |
| Creating or extending a skill, `/new-skill`, updating routing tree | skills/skill-creator/SKILL.md |
| Session start, `/context`, project context needed before implementation | skills/project-context/SKILL.md |
| Wrapping up, `/handoff`, pausing, handing off, or ending a session | skills/session-handoff/SKILL.md |
| Release prep, `/changelog`, sprint close, documenting shipped changes | skills/changelog-generator/SKILL.md |
| `/multi-repo`, changes spanning 2+ repos, shared contracts, coordinated releases | skills/multi-repo/SKILL.md |
| Bug, error, crash, `/debug`, failing test, unexpected behavior, root cause analysis | skills/debug-trace/SKILL.md |
| Unclear / cross-cutting workflow task | skills/task-analysis/SKILL.md |

## Combination rules
- `/intent` → load `product-intent`; run BEFORE `task-analysis` and `architecture-design` when feature purpose is ambiguous
- `/research` → load `task-analysis` + `codebase-analysis` (as needed)
- `/plan` → load `architecture-design` + `implementation-gap-analysis`
- `/docs-flow` → load `dev-docs-flow` (which internally composes other skills)
- `/review` → load `code-review` + `technical-context-discovery`; add domain-specific skills from other branches when the code under review targets a specific stack
- `/code-quality-check` → load `codebase-analysis` + `code-review`
- `/e2e` → load `e2e-testing` + `technical-context-discovery`
- `technical-context-discovery` is a supporting skill that should always be loaded before implementation tasks from any other branch — it is not exclusive to WORKFLOW
- `implementation-gap-analysis` is a supporting skill commonly loaded together with `architecture-design` during planning
- `product-intent` runs BEFORE: `task-analysis`, `architecture-design` when feature purpose is unclear
- `product-intent` runs AFTER: implementation — to verify user-value correctness alongside `implementation-gap-analysis`
- When `/implement` is used, route through the appropriate domain branch (FRONTEND, BACKEND, etc.) and load `technical-context-discovery` + `implementation-gap-analysis` as supporting skills from this branch
- When `/implement-ui` is used, route through FRONTEND and load `technical-context-discovery` + `frontend-implementation` + `ui-verification` from the FRONTEND branch
- When `/review-ui` is used, load `ui-verification` from FRONTEND and add framework-specific skills as needed
- `project-context` runs BEFORE: `architecture-design`, `code-review`, `implementation-gap-analysis`, `multi-repo`
- `debug-trace` runs BEFORE: any fix or patch implementation
- `session-handoff` runs AFTER: any completed implementation or review session
- `multi-repo` ALWAYS triggers: `session-handoff` at task end
- `skill-creator` MUST update: routing files in the same task, never deferred
- `changelog-generator` runs AFTER: `session-handoff` on release tasks
- `/debug` → load `debug-trace` + `technical-context-discovery`
- `/handoff` → load `session-handoff`; include `project-context` Session Context Block if available
- `/changelog` → load `changelog-generator`; run `session-handoff` first on release sessions
- `/context` → load `project-context`
- `/new-skill` → load `skill-creator` + `task-analysis`
- `/multi-repo` → load `multi-repo` + `project-context` (per repo); always end with `session-handoff`
