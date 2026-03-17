# WORKFLOW Branch

## When to enter this branch
- Task involves code review, architecture design, or implementation planning
- Task involves codebase analysis, quality checks, or dead code detection
- Task involves research, task analysis, or context gathering
- Task involves documentation generation or execution flow artifacts
- Task involves E2E testing patterns, test writing, or test debugging
- Task involves unit testing, component testing, or test framework setup
- Task involves implementation gap analysis or plan-vs-code comparison
- Task involves technical context discovery before implementation
- Task involves creating or extending a skill, updating routing tree
- Task involves building project context at session start
- Task involves session wrap-up, handoff, or pause
- Task involves changelog generation, release prep, or sprint close
- Task involves changes spanning multiple repositories
- Task involves debugging, tracing errors, or root cause analysis
- Task involves clarifying user goals, writing acceptance criteria, or verifying feature value
- Task involves security review, hardening, or OWASP compliance check
- Task involves API contract design, versioning, or breaking change assessment
- Task involves CI/CD pipeline setup, quality gates, or deployment workflow
- Task involves observability instrumentation, logging, metrics, or alerting
- Task involves database migration planning, rollback strategy, or zero-downtime schema changes
- Task involves cross-cutting error handling design, retry strategy, or circuit breakers
- Task involves performance profiling, flamegraph analysis, or latency investigation
- Task involves feature flag design, rollout strategy, or flag cleanup
- User uses command-style requests: `/research`, `/plan`, `/docs-flow`, `/review`, `/e2e`, `/test`, `/code-quality-check`, `/debug`, `/handoff`, `/changelog`, `/context`, `/new-skill`, `/multi-repo`, `/intent`, `/security`, `/migrate`, `/observe`, `/profile`, `/flags`

## When NOT to enter this branch
- Task is about implementing frontend UI — use FRONTEND
- Task is about implementing backend logic — use BACKEND
- Task is about writing Dockerfiles or deployment — use INFRA
- Task is about writing SQL or designing schemas — use DATA
- Task is about implementing code (not reviewing or planning it) — use the appropriate domain branch

## Decision tree

For tasks matching this branch, read the next level:

| If the task involves... | Read next |
|---|---|
| `/intent`, feature purpose is unclear, "what should this do", acceptance criteria needed | skills/product-intent/SKILL.md |
| `/security`, security review, OWASP, auth vulnerabilities, secrets audit | skills/security-hardening/SKILL.md |
| `/migrate`, database migration, zero-downtime schema change, migration rollback | skills/migration-strategy/SKILL.md |
| `/observe`, logging setup, metrics, tracing, health endpoints, alerting | skills/observability/SKILL.md |
| `/profile`, performance profiling, flamegraph, latency SLO breach, memory leak | skills/performance-profiling/SKILL.md |
| `/flags`, feature flag design, rollout strategy, flag lifecycle, kill switch | skills/feature-flags/SKILL.md |
| API contract design, OpenAPI spec, versioning, breaking change assessment | skills/api-contract/SKILL.md |
| CI/CD pipeline, GitHub Actions, quality gates, deployment workflow | skills/ci-cd/SKILL.md |
| Error handling design, retry strategy, circuit breaker, graceful degradation | skills/error-handling/SKILL.md |
| `/test`, unit tests, component tests, Vitest, Jest, React Testing Library | skills/unit-testing/SKILL.md |
| GraphQL schema design, resolvers, N+1, subscriptions, DataLoader | skills/graphql/SKILL.md |
| Monorepo setup, Turborepo, Nx, workspace dependencies, affected builds | skills/monorepo-tooling/SKILL.md |
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

### Tier 2 skill combinations
- `/profile` → load `performance-profiling`; combine with `observability` (metrics are the input to profiling)
- `/profile` + Python → load `performance-profiling` + `python`
- `/profile` + Rust → load `performance-profiling` + `rust`
- `/flags` → load `feature-flags`; combine with `ci-cd` (deployment + flag activation are separate)
- GraphQL task → load `graphql` + `sql-and-database` (DataLoader patterns map to SQL batch queries)
- GraphQL + security → load `graphql` + `security-hardening` (depth/complexity limits, introspection)
- Monorepo task → load `monorepo-tooling`; combine with `ci-cd` for affected-only CI setup
- `/test` → load `unit-testing`; add `python-testing` for Python codebases
- `/test` + React → load `unit-testing` + `react`

### Tier 1 skill combinations
- `/security` → load `security-hardening`; combine with `code-review` when reviewing existing backend code
- `/security` + backend implementation → load `security-hardening` + domain skill (nestjs, python-fastapi, rust)
- `/migrate` → load `migration-strategy` + `sql-and-database`
- `/migrate` + API change → load `migration-strategy` + `api-contract`
- `/observe` → load `observability`; combine with `error-handling` for complete production instrumentation
- API contract review → load `api-contract` + `security-hardening`
- CI/CD setup → load `ci-cd` + `docker`; add `security-hardening` for audit gates
- Error handling design → load `error-handling` + `observability`
- `security-hardening` runs DURING: every backend code review — add as supplement to `code-review`
- `migration-strategy` runs BEFORE: any `sql-and-database` task changing existing production tables
- `observability` runs BEFORE: any service ships to production for the first time

### Existing combination rules
- `/intent` → load `product-intent`; run BEFORE `task-analysis` and `architecture-design`
- `/research` → load `task-analysis` + `codebase-analysis` (as needed)
- `/plan` → load `architecture-design` + `implementation-gap-analysis`
- `/docs-flow` → load `dev-docs-flow`
- `/review` → load `code-review` + `technical-context-discovery` + `security-hardening` (backend); add domain skills
- `/code-quality-check` → load `codebase-analysis` + `code-review`
- `/e2e` → load `e2e-testing` + `technical-context-discovery`
- `technical-context-discovery` — always load before implementation tasks from any branch
- `product-intent` runs BEFORE: `task-analysis`, `architecture-design` when feature purpose unclear
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
