---
name: ci-cd
description: CI/CD pipeline design and implementation patterns for automated build, test, and deployment workflows. Covers GitHub Actions, quality gates, environment promotion, secret management in CI, Docker image publishing, and deployment safety patterns. Use when setting up or reviewing CI/CD pipelines, adding quality gates, configuring deployment workflows, or debugging pipeline failures.
---

# CI/CD Pipelines

This skill provides patterns for building CI/CD pipelines that are fast, reliable, and safe. A good pipeline is the automated enforcement of everything a team agrees must be true before code ships.

## When to Use

- Setting up CI for a new project or repository
- Adding quality gates (tests, linting, type-check, coverage) to an existing pipeline
- Designing deployment workflows for staging and production environments
- Reviewing or debugging a failing pipeline
- Migrating from manual deployment to automated delivery

## When NOT to Use

- Infrastructure provisioning (Terraform, Pulumi) — use a dedicated IaC skill
- Application-level health check implementation — use `observability`
- Containerization of the application itself — use `docker`

## Core Principles

### Pipeline as Code

Every pipeline lives in the repository it builds. No GUI-only configuration. No undocumented manual steps that the pipeline depends on. If the repo is cloned fresh, the pipeline should run from scratch.

### Fast Feedback First

Order pipeline stages so the fastest, cheapest failures happen first. A 10-second lint failure should not wait behind a 3-minute build. Structure stages so developers get signal in under 2 minutes for the most common failure modes.

### Quality Gates are Blocking

A quality gate that can be bypassed is not a gate — it is a suggestion. Test failures, type errors, and lint violations block merge. Coverage thresholds enforce minimums. Security scans block on high/critical CVEs. No overrides without explicit, audited justification.

### Least Privilege in CI

The CI runner has only the permissions it needs for the job it runs. Deployment jobs have deploy permissions. Test jobs have no cloud credentials. Secret exposure is minimized by scope.

## CI/CD Process

Use the checklist below and track progress:

```
CI/CD progress:
- [ ] Step 1: Design pipeline stage order and parallelism
- [ ] Step 2: Implement quality gates
- [ ] Step 3: Configure artifact build and publishing
- [ ] Step 4: Design environment promotion strategy
- [ ] Step 5: Configure secret and credential management
- [ ] Step 6: Add deployment safety mechanisms
```

**Step 1: Design pipeline stage order and parallelism**

Standard stage order (fastest-to-slowest, fail early):

```
[lint + format check] → parallel:
  [type-check]
  [unit tests]
  [security audit]
→ [integration tests]
→ [build artifact / Docker image]
→ [deploy to staging]
→ [smoke tests against staging]
→ [deploy to production]  ← manual approval gate or auto on main
```

Parallelism rules:
- Run lint, type-check, unit tests, and audit in parallel — they share no state
- Integration tests run after unit tests pass (fail fast on cheaper tests first)
- Build only after all tests pass — do not build artifacts you will not deploy
- Staging and production deployments are sequential, never concurrent

**Step 2: Implement quality gates**

Linting and formatting:
```yaml
- name: Lint
  run: pnpm lint        # or: ruff check . / cargo clippy
- name: Format check
  run: pnpm format:check  # or: ruff format --check / cargo fmt --check
```

Type checking:
```yaml
- name: Type check
  run: pnpm typecheck   # or: mypy --strict / pyright
```

Tests with coverage threshold:
```yaml
- name: Unit tests
  run: pnpm test --coverage --coverageThreshold='{"global":{"lines":80}}'
```

Security audit:
```yaml
- name: Dependency audit
  run: pnpm audit --audit-level=high  # or: pip-audit / cargo audit
```

Commit these as required status checks in branch protection rules — pull requests cannot merge if any gate fails.

**Step 3: Configure artifact build and publishing**

Docker image build and push pattern (GitHub Actions):
```yaml
- name: Build and push Docker image
  uses: docker/build-push-action@v5
  with:
    context: .
    push: ${{ github.ref == 'refs/heads/main' }}
    tags: |
      ghcr.io/${{ github.repository }}:${{ github.sha }}
      ghcr.io/${{ github.repository }}:latest
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

Image tagging strategy:
- Tag every image with the full Git SHA — never deploy `latest` to production
- Tag with `latest` only on main branch, never on feature branches
- Tag with semantic version when a release tag is pushed
- Store SHA in deployment manifest so the running version is always traceable

Build caching:
- Use GitHub Actions cache for `node_modules`, pip venv, cargo registry
- Use Docker layer cache (`type=gha`) to skip unchanged layers
- Cache lockfile hash as cache key — bust on lockfile change only

**Step 4: Design environment promotion strategy**

Standard environment chain: `feature branch → staging → production`

Staging deployment:
- Trigger: merge to `main` (or `develop`)
- Automatic, no human approval
- Runs smoke tests after deployment
- Rolls back automatically if smoke tests fail

Production deployment:
- Trigger: version tag push (`v*.*.*`) or manual workflow dispatch
- Requires explicit human approval (GitHub Environments + required reviewers)
- Uses the exact image SHA from staging — never rebuilds for production
- Deployment blocked if staging is unhealthy

```yaml
# Production deployment job
deploy-production:
  needs: [deploy-staging, smoke-tests]
  environment:
    name: production
    url: https://app.example.com
  if: startsWith(github.ref, 'refs/tags/v')
```

Environment protection rules (configure in GitHub repo settings):
- Production: required reviewers, deployment branch rules (tags only)
- Staging: no approval required, `main` branch only

**Step 5: Configure secret and credential management**

Secret scoping — never give all jobs all secrets:
```yaml
jobs:
  test:
    # No cloud credentials — tests should not need them
    env:
      DATABASE_URL: postgresql://test:test@localhost/testdb

  deploy:
    environment: production
    # Cloud credentials scoped to deployment job only
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
```

Secret hygiene rules:
- Rotate secrets that are exposed in logs (treat as compromised)
- Use OIDC instead of long-lived credentials where the cloud provider supports it (AWS, GCP, Azure)
- Never print secrets in logs — mask with `::add-mask::` if dynamic
- Reference secrets by name only in workflow files — never hardcode values

OIDC pattern (eliminates stored cloud credentials):
```yaml
permissions:
  id-token: write
  contents: read

- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789:role/github-deploy
    aws-region: eu-west-1
```

**Step 6: Add deployment safety mechanisms**

Health check before traffic switch:
```yaml
- name: Wait for deployment health
  run: |
    for i in {1..30}; do
      STATUS=$(curl -sf https://staging.example.com/health | jq -r .status)
      [ "$STATUS" = "ok" ] && exit 0
      sleep 10
    done
    exit 1
```

Automatic rollback on smoke test failure:
```yaml
- name: Run smoke tests
  id: smoke
  run: pnpm test:smoke

- name: Rollback on failure
  if: failure() && steps.smoke.conclusion == 'failure'
  run: kubectl rollout undo deployment/app-staging
```

Deployment notifications:
- Post deployment success/failure to team Slack channel or equivalent
- Include: environment, version (SHA or tag), deployer, and link to the run
- Never skip failure notifications — silent failures are worse than noisy ones

## Pipeline Review Checklist

```
Structure:
- [ ] Stages ordered fastest-to-slowest (fail early)
- [ ] Lint, type-check, unit tests run in parallel
- [ ] Build artifact only after all tests pass

Quality gates:
- [ ] Lint failure blocks merge
- [ ] Type-check failure blocks merge
- [ ] Test failure blocks merge
- [ ] Coverage threshold enforced
- [ ] Dependency audit blocks on high/critical CVEs

Artifacts:
- [ ] Images tagged with Git SHA
- [ ] Build cache configured (saves time, saves money)
- [ ] No artifacts built for branches that won't deploy

Deployment:
- [ ] Staging deploys automatically on main merge
- [ ] Production requires explicit approval or tag trigger
- [ ] Production uses same image SHA as staging (never rebuild)
- [ ] Smoke tests run after every deployment

Secrets:
- [ ] Cloud credentials scoped to deployment jobs only
- [ ] OIDC used instead of long-lived keys where possible
- [ ] No secrets in workflow files or logs
```

## GitHub Actions Reference Patterns

Branch protection requirements (configure in repo settings):
```
Required status checks:
  ✓ lint
  ✓ type-check
  ✓ unit-tests
  ✓ security-audit
Require branches to be up to date: true
Require pull request before merging: true
```

Reusable workflow for shared quality gate (`.github/workflows/quality.yml`):
```yaml
on:
  workflow_call:

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'pnpm' }
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint
      - run: pnpm typecheck
      - run: pnpm test --coverage
      - run: pnpm audit --audit-level=high
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Tests run after build (slow feedback) | Tests run before build — fail fast |
| `latest` tag deployed to production | Deploy exact SHA from staging |
| All jobs have all secrets | Scope secrets to the job that needs them |
| Manual deployment steps outside the pipeline | Encode every step in workflow — no tribal knowledge |
| Bypassing failing tests with `[skip ci]` | Fix the test; skip only for docs-only commits |
| No smoke tests after deployment | Automated health check + smoke test post-deploy |
| Rebuilding the image for production | Promote the exact staging image to production |
| Long-lived cloud access keys in CI secrets | OIDC token exchange (no stored credentials) |

## Connected Skills

- `docker` — application containerization produces the artifact the pipeline deploys
- `security-hardening` — dependency audits, secret scanning, and SAST belong in the pipeline
- `technical-context-discovery` — discover existing pipeline conventions before modifying
- `observability` — deployment events should trigger monitoring alerts and dashboards
