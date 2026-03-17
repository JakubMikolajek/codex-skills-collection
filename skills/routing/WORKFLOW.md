# WORKFLOW Branch

## When to enter this branch
- Task involves code review, architecture design, or implementation planning
- Task involves codebase analysis, quality checks, or dead code detection
- Task involves research, task analysis, or context gathering
- Task involves documentation generation or execution flow artifacts
- Task involves E2E or unit testing patterns, test framework setup
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
- Task involves observability, logging, metrics, tracing, or alerting
- Task involves database migration planning, rollback strategy, or zero-downtime schema changes
- Task involves cross-cutting error handling, retry strategy, or circuit breakers
- Task involves performance profiling, flamegraph analysis, or latency investigation
- Task involves feature flag design, rollout strategy, or flag lifecycle
- Task involves monorepo tooling, Turborepo/Nx setup, or workspace dependency management
- Task involves GraphQL schema, resolvers, N+1 problem, or subscriptions
- User uses command-style requests: `/research`, `/plan`, `/docs-flow`, `/review`, `/e2e`, `/test`, `/code-quality-check`, `/debug`, `/handoff`, `/changelog`, `/context`, `/new-skill`, `/multi-repo`, `/intent`, `/security`, `/migrate`, `/observe`, `/profile`, `/flags`, `/a11y`, `/graph`

## When NOT to enter this branch
- Task is about implementing frontend UI — use FRONTEND
- Task is about implementing backend logic — use BACKEND
- Task is about writing Dockerfiles or Kubernetes manifests — use INFRA
- Task is about writing SQL or designing schemas — use DATA
- Task is about implementing code (not reviewing or planning it) — use the appropriate domain branch

## Decision tree

| If the task involves... | Read next |
|---|---|
| `/intent`, feature purpose unclear, "what should this do", acceptance criteria | skills/product-intent/SKILL.md |
| `/security`, security review, OWASP, auth vulnerabilities, secrets audit | skills/security-hardening/SKILL.md |
| `/migrate`, database migration, zero-downtime schema change, rollback | skills/migration-strategy/SKILL.md |
| `/observe`, logging setup, metrics, tracing, health endpoints, alerting | skills/observability/SKILL.md |
| `/profile`, flamegraph, latency SLO breach, memory leak, bottleneck | skills/performance-profiling/SKILL.md |
| `/flags`, feature flag design, rollout, kill switch, flag cleanup | skills/feature-flags/SKILL.md |
| `/a11y`, WCAG audit, ARIA review, keyboard navigation, screen reader | skills/accessibility/SKILL.md |
| `/graph`, GraphQL schema, resolvers, N+1, DataLoader, subscriptions | skills/graphql/SKILL.md |
| API contract design, OpenAPI spec, versioning, breaking change assessment | skills/api-contract/SKILL.md |
| CI/CD pipeline, GitHub Actions, quality gates, deployment workflow | skills/ci-cd/SKILL.md |
| Error handling design, retry strategy, circuit breaker, graceful degradation | skills/error-handling/SKILL.md |
| `/test`, unit tests, component tests, Vitest, Jest, React Testing Library | skills/unit-testing/SKILL.md |
| Monorepo, Turborepo, Nx, workspace dependencies, affected builds | skills/monorepo-tooling/SKILL.md |
| `/research`, task analysis, context gathering, PRD creation | skills/task-analysis/SKILL.md |
| `/plan`, architecture design, solution planning, implementation phases | skills/architecture-design/SKILL.md |
| `/docs-flow`, documentation artifacts, execution flow generation | skills/dev-docs-flow/SKILL.md |
| `/review`, code review, quality analysis, best practices verification | skills/code-review/SKILL.md |
| `/code-quality-check`, codebase audit, dependency analysis, dead code | skills/codebase-analysis/SKILL.md |
| `/e2e`, E2E test writing, Page Objects, flaky test debugging | skills/e2e-testing/SKILL.md |
| Implementation gap analysis, plan-vs-code comparison | skills/implementation-gap-analysis/SKILL.md |
| Technical context discovery, project conventions, pattern analysis | skills/technical-context-discovery/SKILL.md |
| Creating or extending a skill, `/new-skill`, updating routing tree | skills/skill-creator/SKILL.md |
| Session start, `/context`, project context before implementation | skills/project-context/SKILL.md |
| Wrapping up, `/handoff`, pausing, handing off, ending a session | skills/session-handoff/SKILL.md |
| Release prep, `/changelog`, sprint close, documenting shipped changes | skills/changelog-generator/SKILL.md |
| `/multi-repo`, changes spanning 2+ repos, coordinated releases | skills/multi-repo/SKILL.md |
| Bug, error, crash, `/debug`, failing test, unexpected behavior | skills/debug-trace/SKILL.md |
| Unclear / cross-cutting workflow task | skills/task-analysis/SKILL.md |

## Combination rules
- `product-intent` BEFORE `task-analysis`, `architecture-design` — when feature purpose is unclear
- `security-hardening` DURING every backend code review — supplement `code-review` on all backend tasks
- `migration-strategy` BEFORE any `sql-and-database` task changing existing production tables
- `observability` BEFORE any service ships to production for the first time
- `debug-trace` BEFORE any fix or patch implementation
- `project-context` BEFORE `architecture-design`, `code-review`, `implementation-gap-analysis`, `multi-repo`
- `session-handoff` AFTER any completed implementation or review session
- `changelog-generator` AFTER `session-handoff` on release tasks
- `skill-creator` MUST update routing files in the same task — never deferred
- `multi-repo` ALWAYS ends with `session-handoff`
- `/security` → `security-hardening`; + `code-review` for backend review; + domain skill for implementation
- `/migrate` → `migration-strategy` + `sql-and-database`; + `api-contract` when schema and API change together
- `/observe` → `observability`; + `error-handling` for complete production instrumentation
- `/profile` → `performance-profiling`; + `observability` (metrics are the profiling input); + `python` or `rust` for ecosystem tools
- `/flags` → `feature-flags`; + `ci-cd` (deploy dark, enable separately)
- `/a11y` → `accessibility`; + framework skill (`react`, `vue`) for component-specific patterns
- `/graph` → `graphql`; + `sql-and-database` (DataLoader → SQL batching); + `security-hardening` (depth/complexity limits)
- `/test` → `unit-testing`; + `react` for component tests; + `python-testing` for Python
- Monorepo → `monorepo-tooling`; + `ci-cd` for affected-only CI
- Error handling design → `error-handling` + `observability`
- API contract review → `api-contract` + `security-hardening`
- CI/CD setup → `ci-cd` + `docker`; + `security-hardening` for audit gates; + `kubernetes` for k8s deploy
- `/intent` → `product-intent`
- `/research` → `task-analysis` + `codebase-analysis`
- `/plan` → `architecture-design` + `implementation-gap-analysis`
- `/docs-flow` → `dev-docs-flow`
- `/review` → `code-review` + `technical-context-discovery` + `security-hardening` (backend)
- `/code-quality-check` → `codebase-analysis` + `code-review`
- `/e2e` → `e2e-testing` + `technical-context-discovery`
- `/debug` → `debug-trace` + `technical-context-discovery`
- `/handoff` → `session-handoff` + `project-context` Session Context Block
- `/changelog` → `changelog-generator` (after `session-handoff` on release sessions)
- `/context` → `project-context`
- `/new-skill` → `skill-creator` + `task-analysis`
- `/multi-repo` → `multi-repo` + `project-context` (per repo) + `session-handoff` at end
- `technical-context-discovery` — always load before implementation tasks from any branch
