# INFRA Branch

## When to enter this branch
- Task involves Dockerfiles, Docker Compose, container images, or multi-stage builds
- Task involves deployment configuration, CI/CD pipelines, or environment setup
- Task involves containerizing an application or service
- Files being edited are `Dockerfile`, `docker-compose.yml`, `.dockerignore`, or CI config files

## When NOT to enter this branch
- Task is about application code (frontend or backend logic) — use FRONTEND or BACKEND
- Task is about database schemas or SQL — use DATA
- Task is about reviewing architecture or code quality — use WORKFLOW
- Task is about running E2E tests (even if Docker is involved for test infra) — use WORKFLOW

## Decision tree

For tasks matching this branch, read the next level:

| If the task involves... | Read next |
|-------------------------|-----------|
| Dockerfile, Docker Compose, container images, multi-stage builds, CI images | skills/docker/SKILL.md |
| Unclear / infrastructure task not clearly Docker-related | skills/docker/SKILL.md |

## Combination rules
- When containerizing a frontend app, also read `skills/routing/FRONTEND.md` to load the appropriate framework skill (e.g., `react`, `vue`, `nuxt`)
- When containerizing a backend service, also read `skills/routing/BACKEND.md` to load the appropriate backend skill (e.g., `nestjs`, `rust`)
- `technical-context-discovery` should always be loaded before editing infrastructure files — read it from WORKFLOW branch
- `code-review` should be loaded when reviewing Docker or infra configuration — read it from WORKFLOW branch
