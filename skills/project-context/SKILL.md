---
name: project-context
description: Build a structured understanding of the current project at the start of a session. Use before any implementation, review, or architecture task to establish stack, conventions, and constraints.
---

# Project Context

This skill provides a systematic approach for building project understanding at the start of any non-trivial session. It produces a Session Context Block that anchors all subsequent work to verified facts about the project's stack, conventions, and constraints.

## When to Use

- At the start of any non-trivial session
- When switching to a different repo or branch mid-session
- Before running `architecture-design`, `code-review`, or `implementation-gap-analysis`
- When a teammate's task description references unfamiliar parts of the codebase

## When NOT to Use

- Task is a simple one-line answer or clarification question — do not run full context discovery
- Session Context Block was already produced in the current session and no branch/repo switch occurred
- Task explicitly says "skip context" or provides all context inline

## Core Principles

### Read Before Assuming

- Never infer stack or conventions from a single file — require at least 2 confirming sources
- If evidence conflicts, state the conflict explicitly — do not resolve it silently
- Do not guess business logic, framework version, or team decisions without evidence
- Treat the Session Context Block as a living document — update it when new evidence appears

### What to Read on Session Start

Read in this order, stopping once the Session Context Block can be filled:

1. Root manifest: `package.json` / `pubspec.yaml` / `build.gradle` / `Cargo.toml` (whichever exists)
2. `README.md` at repo root
3. `AGENTS.md` — check `.codex/AGENTS.md` first (primary location in bootstrapped projects), then repo root as fallback. Read the Skill Routing table and path convention note.
4. `skills/routing/` branch files (relative to `AGENTS.md`'s directory) — extract active skills and combination rules
5. Folder structure — max 2 levels deep
6. One representative source file per detected layer (e.g. one component, one service, one test)

## Session Context Block

Produce this block at the top of the first response, max 20 lines:

```
## Session Context
Stack: [languages, frameworks, runtimes]
Test runner: [jest / vitest / pytest / xctest / etc.]
Package manager: [npm / pnpm / yarn / swift pm / etc.]
Key conventions: [naming style, file structure, import pattern]
Active constraints: [anything from AGENTS.md or README that limits approach]
Open uncertainties: [anything that could not be confirmed from 2+ sources]
```

## Context Discovery Process

Use the checklist below and track your progress:

```
Context discovery progress:
- [ ] Step 1: Read root manifest and README
- [ ] Step 2: Read AGENTS.md and routing files
- [ ] Step 3: Scan folder structure (max 2 levels)
- [ ] Step 4: Read one representative file per layer
- [ ] Step 5: Produce Session Context Block
```

**Step 1: Read root manifest and README**

Identify the root manifest file and extract: language, framework, runtime version, package manager, test runner, key dependencies.

**Step 2: Read AGENTS.md and routing files**

Extract: workflow rules, routing constraints, active skills, any team conventions documented in AGENTS.md.

**Step 3: Scan folder structure (max 2 levels)**

Identify: project layout pattern (monorepo, single app, feature-based, layer-based), test location, config location.

**Step 4: Read one representative file per layer**

Read one file per detected layer to confirm: naming conventions, import patterns, code style, error handling patterns.

**Step 5: Produce Session Context Block**

Assemble the block. Mark anything confirmed from fewer than 2 sources as an open uncertainty.

## When to Re-Run Context Discovery

- Branch switch detected
- New folder opened that differs in stack from detected context
- Tool output contradicts the Session Context Block
- User explicitly says conventions have changed

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Inferring framework version from one import | Check manifest file for declared version |
| Stating convention as fact from one file sample | Mark as "observed in N files, unconfirmed" |
| Skipping context on "simple" tasks | Always run — simple tasks break conventions too |
| Writing Session Context Block mid-response | Always place it at the top, before any work |
| Resolving conflicting signals silently | List conflict in Open Uncertainties |
| Reading every file in the repo | Stop after 5 representative files — enough to fill the block |

## Connected Skills

- `architecture-design` — always run project-context first
- `code-review` — always run project-context first
- `multi-repo` — run project-context per repo before cross-repo work
- `session-handoff` — handoff document should include Session Context Block
- `technical-context-discovery` — project-context is the session-start complement to technical-context-discovery's per-task focus
