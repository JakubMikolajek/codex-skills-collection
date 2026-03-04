---
name: docker
description: Dockerfile and Docker Compose implementation and review patterns for containerized applications. Use when Codex needs to build, refactor, debug, or review `Dockerfile`, `docker-compose.yml`, `compose.yaml`, multi-stage builds, runtime images, service definitions, or Turborepo-compatible container workflows, especially for TypeScript stacks such as Next.js, NestJS, Nuxt, Vite, SPA frontends, Node workers, and monorepos.
---

# Dockerfile and Compose Patterns

Use this skill to produce lean, reproducible container setups that match the repository's delivery style. Prefer multi-stage builds, explicit quality gates, small runtime images, non-root execution, and Compose definitions that are easy to run locally and in CI. Treat the user's Next.js example as the preferred quality bar and layering style, not as the only supported stack.

## Delivery Workflow

Use the checklist below and track progress:

```
Docker progress:
- [ ] Step 1: Discover runtime, package manager, and repo shape
- [ ] Step 2: Choose the correct stack pattern and single-app or Turborepo flow
- [ ] Step 3: Build a multi-stage Dockerfile with explicit quality gates
- [ ] Step 4: Add Docker Compose service wiring and runtime config
- [ ] Step 5: Verify image size, caching, security, and startup path
```

## Default Style

- Prefer `node:<version>-alpine` for TypeScript/Node-based app images unless the project requires another base.
- Enable `corepack` when the project uses `pnpm`.
- Use multi-stage builds with explicit stages such as:
  - `base`
  - `deps`
  - `lint`
  - `test`
  - `builder`
  - `runner`
- Keep quality gates inside the build when the project style expects lint/test/build enforcement before the runtime image exists.
- Use a dedicated non-root runtime user.
- Copy only the runtime artifacts needed by the final container.

## Stack Selection

Choose the Docker strategy based on the deployable target:

| Stack type | Preferred runtime model |
|---|---|
| Next.js SSR / standalone | Node runtime with framework build artifacts |
| Nuxt SSR / hybrid | Node runtime with Nuxt build output |
| NestJS / Node API | Node runtime with compiled `dist` output |
| Vite / SPA frontend | Static asset runtime, often Nginx/Caddy or project-standard static server |
| Worker / CLI / job runner | Minimal runtime image with explicit command, often no exposed port |
| Turborepo app | Same as target stack, but with pruned or scoped workspace build |

## TypeScript App Pattern

For most TypeScript apps, start from this baseline:

- `base` stage:
  - set `WORKDIR`
  - enable `corepack` if `pnpm` is used
  - declare only build args that are genuinely needed during build
- `deps` stage:
  - install compatibility packages if the base image requires them
  - copy lockfiles and package manifests before source code
  - run frozen dependency installation
- quality stages:
  - run `lint` if the repository expects it
  - run tests if the repository expects them
  - run build/compile step for the target app
- `runner` stage:
  - create a dedicated runtime user
  - copy only runtime artifacts and required static assets
  - define the startup command explicitly

Keep the user's multi-stage style as the default preference even when some stages are omitted because the stack does not need them.

## Next.js Single-App Pattern

Match the repository's preferred flow when containerizing a standalone Next.js app:

- `base` stage:
  - set `WORKDIR`
  - enable `corepack`
  - declare required build args and public envs explicitly
- `deps` stage:
  - install compatibility packages if the chosen base requires them
  - copy lockfiles and package manifests first
  - run frozen dependency installation
- `lint` stage:
  - copy project files
  - run lint
- `test` stage:
  - set test env explicitly
  - run tests
- `builder` stage:
  - run production build
- `runner` stage:
  - set production envs
  - create non-root user/group
  - copy `.next/standalone`, static assets, and other runtime-only files
  - expose the application port
  - start with a simple explicit `CMD`

## NestJS and Node API Pattern

For NestJS or similar TypeScript backend services:

- keep the same early `base` / `deps` / quality-stage pattern
- compile to `dist`
- copy only:
  - compiled output
  - production runtime dependencies or deployable package graph
  - required config/runtime assets
- expose only the API port the service actually uses
- start with an explicit runtime command such as `node dist/main.js` or the project-standard equivalent

Avoid shipping source files, test files, and build-only tooling in the runtime image.

## Static Frontend Pattern

For Vite or SPA-style frontends where the output is static:

- keep dependency, lint, test, and build stages in the Node build image
- treat the final stage as a static asset runtime, not necessarily a Node runtime
- copy only built frontend assets to the final image
- keep runtime config strategy explicit if the app requires environment injection at startup

Do not force a Node runner for a purely static frontend unless the repository already standardizes that approach.

## Nuxt and Hybrid Frontend Pattern

For Nuxt or other hybrid TS frontends:

- choose the runtime based on whether the app is deployed as:
  - SSR/hybrid Node app
  - fully static output
- keep framework-specific artifacts explicit
- avoid applying Next.js-specific standalone assumptions to non-Next frameworks

## Worker and Tooling Pattern

For TypeScript workers, jobs, or CLI services:

- keep the same build hygiene and caching structure
- omit port exposure if the process does not listen on a socket
- use an explicit command focused on the job entrypoint
- keep Compose minimal unless the process depends on other local services

## Turborepo Compatibility

When the repository is a Turborepo or similar monorepo:

- Do not copy and install the whole repository into the runtime path unless required.
- Prefer a pruned build context for the selected app when the repo uses Turborepo tooling.
- Keep dependency installation scoped to the pruned workspace or filtered package graph.
- Build only the target app and the packages it actually depends on.
- Keep runtime images focused on one deployable service, not the whole monorepo.
- Preserve cache-friendly layer ordering so workspace changes do not invalidate everything unnecessarily.
- Keep stack-specific runtime behavior intact after pruning; pruning should reduce scope, not change how the target app runs.

## Dependency and Cache Hygiene

- Copy manifest files and lockfiles before source code when dependency caching matters.
- Use frozen/locked installs for reproducibility.
- Keep package-manager caches and temporary build artifacts out of the final image.
- Avoid invalidating dependency layers by copying the entire repository too early.
- Use `.dockerignore` expectations implicitly when the repository already has them; do not rely on Docker sending unnecessary files.

## Environment and Secrets

- Distinguish build-time args from runtime environment clearly.
- Do not bake sensitive server secrets into the image unless the deployment model truly requires it.
- Public client-exposed values may need to be available at build time for frameworks like Next.js or certain static frontend builds; treat them explicitly and intentionally.
- Keep runtime env declarations minimal and focused on what the process actually needs.

## Compose Patterns

- Prefer a single clear application service definition before adding complexity.
- Keep `build.context` and `target` explicit.
- Map ports intentionally and only as needed.
- Use `environment` for runtime variables and keep naming consistent with the app.
- Add `depends_on`, healthchecks, volumes, or extra services only when the application actually needs them.
- Prefer Compose files that are easy to run locally without hiding how the service starts.

## Security and Runtime Rules

- Run the final container as a non-root user whenever practical.
- Keep the runtime image small and free of dev-only tooling.
- Avoid leaving build tools, linters, test runners, or source-only files in the runtime stage unless necessary.
- Expose only the port the service actually listens on.

## Docker Review Checklist

```
Dockerfile:
- [ ] Multi-stage flow is intentional and readable
- [ ] Dependency caching is preserved
- [ ] Runtime image contains only required artifacts
- [ ] Final container does not run as root without reason

Build quality:
- [ ] Lint, test, and build stages match the repository's expectations
- [ ] Build args and env usage are explicit
- [ ] Turborepo compatibility is handled when the repo is a monorepo

Compose:
- [ ] Build target, ports, and environment are explicit
- [ ] Service wiring is as simple as the app allows
- [ ] No unnecessary local-only complexity is added
- [ ] Stack-specific runtime expectations are preserved
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| One-stage Dockerfile that installs, tests, builds, and runs everything | Split into explicit multi-stage flow |
| Copying the whole repo before dependency installation | Copy manifests first for caching |
| Running the runtime image as root by default | Create a dedicated runtime user |
| Shipping dev dependencies and build tools in the final image | Copy only runtime artifacts to the runner stage |
| Forcing every TypeScript stack into the same runtime shape | Match the runtime to the actual app type |
| Treating static frontend, API, and SSR app builds as interchangeable | Choose the stack-specific output and runner model |
| Treating Turborepo like a single-package repo | Prune or scope the build to the target app |
| Baking sensitive runtime secrets into image layers casually | Keep secret handling explicit and deployment-aware |
| Compose files full of unnecessary helpers and hidden behavior | Keep service definitions direct and minimal |

## Connected Skills

- `react` - use when the container target is a React application
- `react-nextjs` - use when the container target is a Next.js application
- `vue` - use when the container target is a Vue application
- `nuxt` - use when the container target is a Nuxt application
- `nestjs` - use when the container target is a NestJS API
- `rust` - use when the container target includes Rust or Tauri services
- `technical-context-discovery` - follow repository container conventions before editing
- `code-review` - validate runtime, security, and build quality
