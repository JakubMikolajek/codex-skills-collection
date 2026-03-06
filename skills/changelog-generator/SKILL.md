---
name: changelog-generator
description: Generate structured CHANGELOG entries from git history, PR descriptions, or session handoffs. Use when preparing a release, closing a sprint, or documenting changes for end users.
---

# Changelog Generator

This skill provides a structured process for generating CHANGELOG entries in [Keep a Changelog](https://keepachangelog.com) format. It supports three input modes (git log, PR descriptions, handoff documents) and enforces user-facing language, proper categorization, and version bump recommendations.

## When to Use

- Preparing a version release or tag
- Closing a sprint and documenting what shipped
- After `session-handoff` on tasks that produce user-facing changes
- When `CHANGELOG.md` is missing and needs to be bootstrapped from history

## When NOT to Use

- Documenting internal refactors that do not affect public API or user experience
- Task is a draft or work-in-progress with no shippable changes yet
- User explicitly says "skip changelog"

## Core Principles

### Three Input Modes

Use the best available source:

1. **Git log mode** — `git log --oneline [last-tag]..HEAD`
2. **PR mode** — PR titles and descriptions provided by user
3. **Handoff mode** — reads `.codex-handoff.md` Status and Files Modified sections

### Output Format

Strictly follow [Keep a Changelog](https://keepachangelog.com):

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
### Changed
### Deprecated
### Removed
### Fixed
### Security
```

Use `## [Unreleased]` when version is not yet tagged. Omit empty sections.

### Writing Rules

- User-facing language only — "Added dark mode" not "feat: add dark-mode-toggle.tsx"
- One line per change
- Group related commits into one entry if they form a single feature
- Never include internal refactors unless they affect public API or break existing behavior
- Breaking changes: prefix entry with `**BREAKING:**`

## Changelog Generation Process

Use the checklist below and track your progress:

```
Changelog progress:
- [ ] Step 1: Determine input mode
- [ ] Step 2: Collect raw change data
- [ ] Step 3: Categorize changes
- [ ] Step 4: Write user-facing entries
- [ ] Step 5: Determine version bump
- [ ] Step 6: Output CHANGELOG block
```

**Step 1: Determine input mode**

Check which input source is available: git log, PR descriptions, or `.codex-handoff.md`. Prefer the most structured source available.

**Step 2: Collect raw change data**

Extract all changes from the chosen input source. Include commit messages, PR titles, or handoff status/files modified.

**Step 3: Categorize changes**

Sort each change into one of: Added, Changed, Deprecated, Removed, Fixed, Security. If a change does not fit any category, it is likely an internal refactor — omit it unless it affects public API.

**Step 4: Write user-facing entries**

Rewrite each entry in user-facing language. Group related commits into single entries. Flag breaking changes with `**BREAKING:**` prefix.

**Step 5: Determine version bump**

Apply version bump logic:

| Condition | Bump |
|---|---|
| `**BREAKING:**` changes present | Major |
| New `Added` entries, no breaking changes | Minor |
| Only `Fixed` / `Security` entries | Patch |

Always state recommendation explicitly with reasoning.

**Step 6: Output CHANGELOG block**

Produce the formatted CHANGELOG block. If `CHANGELOG.md` exists, prepend the new block. If it does not exist, create the file.

### Low-Quality Commit Messages

When commit messages are vague or uninformative:

- Summarize by affected files and change scope
- Flag the section for human review with `<!-- TODO: verify this entry -->`
- Do not invent user-facing descriptions from ambiguous commits

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Copying commit message as entry | Rewrite in user-facing language |
| One entry per commit | Group related commits into features and fixes |
| Skipping version bump recommendation | Always state major/minor/patch with reason |
| Internal refactor in public changelog | Omit unless it changes public API |
| Missing `**BREAKING:**` prefix | Flag every breaking change explicitly |
| Changelog with empty sections | Omit sections that have no entries |

## Connected Skills

- `session-handoff` — primary input source for handoff mode
- `code-review` — run before changelog on release to catch undocumented changes
