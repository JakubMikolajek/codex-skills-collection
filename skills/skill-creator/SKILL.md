---
name: skill-creator
description: Scaffold new SKILL.md files and wire them into the routing tree. Use when adding a new skill to the system, extending an existing skill's scope, or reorganizing routing branches.
---

# Skill Creator

This skill provides a systematic process for creating new skills and integrating them into the routing tree. It enforces quality gates, prevents duplicates, and ensures every new skill is reachable from the root router (`AGENTS.md`).

> **Path convention:** In this source repo, `AGENTS.md` and `skills/` live at repo root. In bootstrapped target projects, they live inside `.codex/`. All `skills/...` paths below are relative to the directory containing `AGENTS.md`.

## When to Use

- User requests a new capability not covered by any existing skill
- An existing skill is doing too many unrelated things and needs to be split
- A new technology or framework needs dedicated skill coverage
- Routing tree has a gap (skill exists but is unreachable from `AGENTS.md`)

## When NOT to Use

- Task merely *uses* an existing skill — do not enter this skill for normal skill consumption
- Task is about editing skill content to fix a typo or update a rule — edit directly without scaffolding
- Task is about reorganizing routing files without creating new skills — edit routing files directly

## Core Principles

### Audit Before Creating

- Read all existing SKILL.md files before scaffolding anything
- Search for partial coverage — a new skill may already exist under a different name
- If overlap found: extend the existing skill, do not create a duplicate
- Check the routing tree to confirm the gap is real, not a routing misconfiguration

### Naming and Placement

- Folder name: lowercase, hyphenated, technology or action-based (e.g. `debug-trace`, `react-nextjs`)
- One skill = one folder = one SKILL.md
- Determine domain branch before writing: FRONTEND / BACKEND / INFRA / DATA / WORKFLOW
- Name by capability, not by implementation detail

### Routing Must Be Updated in the Same Task

- Never create a skill without updating the relevant routing branch file (e.g. `skills/routing/WORKFLOW.md`)
- If the skill belongs to a stack sub-branch (e.g. `skills/routing/REACT.md`), update that file too
- If no suitable sub-branch exists, evaluate whether to create one or attach directly to the domain branch
- Verify reachability from `AGENTS.md` through the routing tree after updating

## Skill Creator Process

Use the checklist below and track your progress:

```
Skill creation progress:
- [ ] Step 1: Audit existing skills for overlap
- [ ] Step 2: Determine domain branch and placement
- [ ] Step 3: Scaffold SKILL.md with required sections
- [ ] Step 4: Update routing files
- [ ] Step 5: Validate quality gates
```

**Step 1: Audit existing skills for overlap**

Read all existing `SKILL.md` files in `skills/*/` (relative to `AGENTS.md`). Search for partial coverage of the proposed capability. If an existing skill covers 50%+ of the new skill's scope, extend it instead of creating a new one.

**Step 2: Determine domain branch and placement**

Identify which domain branch the skill belongs to: FRONTEND, BACKEND, INFRA, DATA, or WORKFLOW. If a stack sub-branch exists for the skill's technology, place the skill there. Otherwise, attach directly to the domain branch.

**Step 3: Scaffold SKILL.md with required sections**

Create `skills/[skill-name]/SKILL.md` (relative to `AGENTS.md`) with all required sections. Enforce these quality gates:

- Frontmatter `name` and `description` fields present
- Minimum 3 explicit trigger conditions in `When to Use`
- Minimum 1 explicit exclusion in `When NOT to Use`
- At least one anti-pattern table
- At least one connected skill reference
- Tone and structure matches existing skills in the repo

**Step 4: Update routing files**

1. Open the target branch file in `skills/routing/` (relative to `AGENTS.md`)
2. Add new skill to the decision table with a trigger condition
3. Add exclusion condition (when NOT to route here)
4. Add combination rule if the skill is always paired with another
5. If a sub-branch file is involved, update that file too

**Step 5: Validate quality gates**

Run validation:

```
Quality gates:
- [ ] SKILL.md has correct frontmatter (name + description)
- [ ] When to Use has 3+ trigger conditions
- [ ] When NOT to Use has 1+ exclusion
- [ ] Anti-Patterns table present
- [ ] Connected Skills section present
- [ ] Routing file updated with new skill entry
- [ ] Skill is reachable from `AGENTS.md` through the routing tree
- [ ] Validator passes: `.codex/scripts/validate-routing-tree.sh`
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Creating skill without reading existing ones | Always audit first — extend before creating |
| Deferring routing update to later | Update routing in the same task, always |
| Vague `When to Use` conditions | Write conditions that are binary and testable |
| Skill that covers 3+ unrelated domains | Split into focused single-responsibility skills |
| Naming by implementation detail (`use-hooks`) | Name by capability (`react-state-management`) |
| Creating a skill folder without SKILL.md | Every folder must contain a complete SKILL.md |

## Connected Skills

- `task-analysis` — run before creating a skill to understand the capability gap
- `technical-context-discovery` — read project conventions before naming or placing a new skill
