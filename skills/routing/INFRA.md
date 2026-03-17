# INFRA Branch

## When to enter this branch
- Task involves Dockerfiles, Docker Compose, container images, or multi-stage builds
- Task involves Kubernetes manifests, Helm charts, or k3s deployment configuration
- Task involves deployment configuration, CI/CD pipelines, or environment setup
- Task involves containerizing an application or service
- Files being edited are `Dockerfile`, `docker-compose.yml`, `.dockerignore`, `*.yaml` (k8s manifests), or `Chart.yaml` (Helm)

## When NOT to enter this branch
- Task is about application code (frontend or backend logic) — use FRONTEND or BACKEND
- Task is about database schemas or SQL — use DATA
- Task is about reviewing architecture or code quality — use WORKFLOW
- Task is about running E2E tests (even if Docker is involved for test infra) — use WORKFLOW
- Task is about CI/CD pipeline logic (GitHub Actions) — use WORKFLOW (ci-cd skill)

## Decision tree

For tasks matching this branch, read the next level:

| If the task involves... | Read next |
|---|---|
| Dockerfile, Docker Compose, multi-stage builds, container images | skills/docker/SKILL.md |
| Kubernetes manifests, Deployments, Services, Ingress, Helm, k3s | skills/kubernetes/SKILL.md |
| Both containerization and Kubernetes deployment | Load both skills |
| Unclear / infrastructure task not clearly categorized | skills/docker/SKILL.md |

## Combination rules
- Kubernetes tasks always also load `docker` — a k8s manifest references a Docker image
- When containerizing a frontend app, also read `skills/routing/FRONTEND.md` for the framework skill
- When containerizing a backend service, also read `skills/routing/BACKEND.md` for the backend skill
- `technical-context-discovery` should always be loaded before editing infrastructure files — read it from WORKFLOW branch
- `security-hardening` should be loaded when reviewing Kubernetes security context, secrets, or network policies
- `observability` should be loaded when configuring health probes or metrics scraping in manifests
- `ci-cd` (from WORKFLOW branch) is the deployment pipeline that executes `kubectl apply` or `helm upgrade`
