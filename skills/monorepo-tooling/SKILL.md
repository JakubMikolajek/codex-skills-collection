---
name: monorepo-tooling
description: Monorepo setup and workflow patterns using Turborepo and Nx. Covers workspace dependency management, build caching, task pipelines, shared package conventions, and CI optimization for monorepos. Use when setting up a new monorepo, adding packages to an existing one, configuring build pipelines, or debugging slow monorepo CI.
---

# Monorepo Tooling

A monorepo is only as good as its tooling. Without caching and task pipelines, a monorepo becomes a slowrepo. This skill covers the patterns that make monorepos fast, coherent, and easy to navigate.

## When to Use

- Setting up a new monorepo with multiple apps and shared packages
- Adding a new app or package to an existing monorepo
- CI is running full builds on every change regardless of what changed
- Shared packages are inconsistently versioned or causing dependency conflicts
- Developers complain that `pnpm install` or builds are slow

## When NOT to Use

- Single-app repositories — monorepo tooling adds overhead without benefit
- Polyrepo architecture where repos are separate by design (use `multi-repo` skill)
- Python monorepos — different toolchain (uv workspaces, not Turborepo/Nx)

## Core Principles

### Affected-Only Builds

The entire point of a monorepo build tool is running only the tasks that are affected by what changed. If CI rebuilds everything on every commit, the monorepo tooling is not configured correctly.

### Package Boundaries are Contracts

A shared package is a contract with its consumers. Treat it like a library: explicit exports, versioned changes, no circular dependencies between packages.

### Caching is Correctness-Critical

A cache hit must produce identical output to a full build. If caching produces wrong results, the cache key is wrong — not the cache. Fix the key, not by disabling caching.

## Repository Structure

Standard monorepo layout:
```
/
├── apps/
│   ├── web/          # Next.js / Nuxt frontend
│   ├── api/          # NestJS / FastAPI backend
│   └── mobile/       # React Native / SwiftUI
├── packages/
│   ├── ui/           # Shared component library
│   ├── config/       # ESLint, TypeScript, Tailwind configs
│   ├── types/        # Shared TypeScript types
│   └── utils/        # Shared utility functions
├── turbo.json        # or nx.json
├── package.json      # Root workspace config
└── pnpm-workspace.yaml
```

Rules:
- `apps/` — deployable applications; depend on packages, never on other apps
- `packages/` — shared libraries; can depend on other packages, never on apps
- No circular dependencies between packages (enforce with lint rule)
- Each package has its own `package.json` with explicit `exports` field

## Turborepo Setup

`turbo.json` — task pipeline definition:
```json
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["**/.env.*local"],
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "!.next/cache/**", "dist/**"],
      "cache": true
    },
    "test": {
      "dependsOn": ["^build"],
      "outputs": ["coverage/**"],
      "cache": true
    },
    "lint": {
      "outputs": [],
      "cache": true
    },
    "typecheck": {
      "dependsOn": ["^build"],
      "outputs": [],
      "cache": true
    },
    "dev": {
      "cache": false,
      "persistent": true
    }
  }
}
```

Key pipeline semantics:
- `"dependsOn": ["^build"]` — build all dependencies first (topological order)
- `"dependsOn": ["build"]` — run `build` in the same package first
- `"outputs"` — what gets cached; must include all generated files
- `"cache": false` — for dev servers and watch tasks that should not be cached
- `"persistent": true` — for long-running tasks (dev servers)

Running tasks:
```bash
# Run across all packages (respects pipeline)
turbo run build
turbo run test lint typecheck  # parallel, respects deps

# Run for a specific package and its dependencies
turbo run build --filter=web
turbo run build --filter=...web  # web and everything that web depends on
turbo run build --filter=web...  # web and everything that depends on web

# Affected by changes since last commit
turbo run test --filter=[HEAD^1]
# Affected by changes on this branch vs main
turbo run test --filter=[origin/main]
```

Remote caching (Vercel or self-hosted):
```bash
# Link to Vercel remote cache (free tier available)
turbo login
turbo link

# Self-hosted: set TURBO_API, TURBO_TOKEN, TURBO_TEAM env vars
```

## Nx Setup

`nx.json` — project configuration:
```json
{
  "tasksRunnerOptions": {
    "default": {
      "runner": "nx/tasks-runners/default",
      "options": {
        "cacheableOperations": ["build", "test", "lint", "typecheck"]
      }
    }
  },
  "targetDefaults": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["{projectRoot}/dist"]
    },
    "test": {
      "dependsOn": ["^build"]
    }
  }
}
```

Nx-specific features:
```bash
# Visualize dependency graph
nx graph

# Run only affected tasks
nx affected --target=test
nx affected --target=build --base=origin/main

# Generate a new app or library
nx generate @nx/next:app web
nx generate @nx/js:library shared-types

# Show what a task will run without running it
nx run-many --target=build --dry-run
```

## Shared Package Conventions

Every shared package must have:

`package.json` minimum:
```json
{
  "name": "@myorg/ui",
  "version": "0.0.0",
  "private": true,
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.mjs",
      "require": "./dist/index.js"
    }
  },
  "scripts": {
    "build": "tsc",
    "dev": "tsc --watch",
    "lint": "eslint .",
    "typecheck": "tsc --noEmit"
  },
  "peerDependencies": {
    "react": "^18.0.0"
  }
}
```

`tsconfig.json` — extend from root config:
```json
{
  "extends": "@myorg/config/tsconfig.base.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src"]
}
```

Shared config package (`packages/config`):
```
packages/config/
├── eslint-preset.js      # shared ESLint config
├── tsconfig.base.json    # shared TypeScript base
├── tsconfig.react.json   # React-specific extends
└── tailwind.config.js    # shared Tailwind preset
```

Apps consume via `"extends": "@myorg/config/tsconfig.react.json"` — no duplicated config.

## Workspace Dependency Management (pnpm)

`pnpm-workspace.yaml`:
```yaml
packages:
  - 'apps/*'
  - 'packages/*'
```

Internal package references — always use `workspace:*` protocol:
```json
{
  "dependencies": {
    "@myorg/ui": "workspace:*",
    "@myorg/types": "workspace:*"
  }
}
```

`workspace:*` means "use the local version" — never pins to a published version in development.

Useful pnpm workspace commands:
```bash
# Install a dep in a specific workspace
pnpm add lodash --filter @myorg/web

# Install a workspace package as a dep
pnpm add @myorg/ui --filter @myorg/web --workspace

# Run a script in a specific package
pnpm --filter @myorg/api run build

# Run across all packages matching a filter
pnpm --filter "./packages/**" run build
```

## CI Optimization

With Turbo remote cache, CI should only rebuild what changed:
```yaml
# GitHub Actions — Turborepo with remote cache
- name: Cache Turborepo
  uses: actions/cache@v4
  with:
    path: .turbo
    key: ${{ runner.os }}-turbo-${{ github.sha }}
    restore-keys: ${{ runner.os }}-turbo-

- name: Build and test affected
  run: turbo run build test lint --filter=[origin/main]
  env:
    TURBO_TOKEN: ${{ secrets.TURBO_TOKEN }}
    TURBO_TEAM: ${{ vars.TURBO_TEAM }}
```

Expected CI behavior:
- First run after a change: rebuilds only affected packages + their dependents
- Repeated runs or unrelated package changes: full cache hit in seconds
- If CI always rebuilds everything: check `outputs` configuration in `turbo.json`

## Monorepo Checklist

```
Structure:
- [ ] apps/ and packages/ separation enforced
- [ ] No circular dependencies between packages
- [ ] Each package has explicit exports field
- [ ] Shared configs in packages/config

Turborepo / Nx:
- [ ] Pipeline defined with correct dependsOn
- [ ] outputs field covers all generated artifacts
- [ ] Remote cache configured for CI
- [ ] dev task marked cache: false

Workspace:
- [ ] Internal deps use workspace:* protocol
- [ ] peerDependencies declared correctly in shared packages
- [ ] tsconfig extends from shared base

CI:
- [ ] Affected-only builds configured
- [ ] Cache restored before build task
- [ ] Full rebuild only triggered on lockfile change
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| No `outputs` field on cached tasks | Define all generated files in `outputs` |
| `"cache": true` on dev server task | `"cache": false` + `"persistent": true` |
| Absolute imports from app into package | Packages never import from apps |
| `"@myorg/ui": "0.1.0"` in workspace | `"@myorg/ui": "workspace:*"` |
| Duplicated tsconfig/eslint config per package | Shared config package + extends |
| Running `turbo run build` without filter in CI | Use `--filter=[origin/main]` for affected-only |
| Circular: `packages/a` → `packages/b` → `packages/a` | Extract shared dep to `packages/c` |

## Connected Skills

- `ci-cd` — monorepo affected builds plug directly into CI pipeline design
- `docker` — each app in a monorepo needs its own Dockerfile; Turborepo prune for efficient images
- `technical-context-discovery` — discover existing workspace conventions before restructuring
- `multi-repo` — when a package genuinely needs to be a separate repo (external consumers, separate deploy)
