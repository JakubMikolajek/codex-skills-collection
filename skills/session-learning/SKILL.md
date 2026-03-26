---
name: session-learning
description: Produce a structured learning record after any /implement or /review session. Captures which skills were loaded, what worked, what routing was ambiguous, and what failure patterns were observed. Output feeds both per-skill references/failure-patterns.md and the global skills/routing/FAILURES.md. Run automatically at the end of every /implement and /review task — no user prompt required.
---

# Session Learning

This skill closes the feedback loop on the skill system itself. After every implementation or review session, it records what the agent observed about skill quality, routing accuracy, and failure patterns — so the system improves from real usage rather than speculation.

## When to Use

- Automatically at the end of every `/implement` or `/review` task
- After `/debug` when a root cause reveals a missing or incorrect skill section
- After `/multi-repo` when cross-repo routing decisions were made
- When the agent notices mid-session that a loaded skill was wrong, incomplete, or ambiguous

## When NOT to Use

- Session consisted only of answering a question with no file modifications
- Task was a single-response clarification with no skill loading involved
- User explicitly says "skip learning" or "no learning record needed"

## Core Principles

### Observation Over Inference

Only record patterns directly observed this session. Do not infer failure patterns from code not read, or routing quality from paths not taken.

### Two Destinations, One Pass

Every session-learning run produces output in two places:
1. **Per-skill**: `skills/<skill-name>/references/failure-patterns.md` — appended, never overwritten
2. **Global rollup**: `skills/routing/FAILURES.md` — appended with session date and skill reference

Both are updated in the same pass. Never defer one to a later session.

### Severity Levels

Each recorded failure or signal carries a severity:

| Level | Meaning |
|---|---|
| `CRITICAL` | Skill loaded but produced wrong output — caused a real implementation mistake |
| `WARN` | Skill loaded, output was partially wrong or incomplete — required manual correction |
| `ROUTING` | Wrong branch or skill was loaded first — agent had to backtrack |
| `MISSING` | Task required knowledge not present in any skill — agent had to improvise |
| `OK` | Skill loaded and used correctly — positive signal worth recording |

Record `OK` entries too — they confirm what is working and prevent unnecessary refactoring of healthy skills.

### Routing Quality vs Skill Quality

These are separate dimensions:
- **Routing quality**: Did the agent reach the right skill via the routing tree, or did it take wrong turns?
- **Skill quality**: Once the right skill was loaded, was its content accurate, complete, and actionable?

Always distinguish between them in the learning record. A routing problem is fixed in `AGENTS.md` or a routing branch file. A skill quality problem is fixed in the skill's `SKILL.md`.

---

## Session Learning Process

```
Session Learning progress:
- [ ] Step 1: List all skills loaded this session
- [ ] Step 2: Assess routing quality per skill
- [ ] Step 3: Assess skill content quality per skill
- [ ] Step 4: Identify failure patterns
- [ ] Step 5: Identify missing skills or sections
- [ ] Step 6: Append to per-skill failure-patterns.md
- [ ] Step 7: Append to global FAILURES.md
```

**Step 1: List all skills loaded this session**

Enumerate every skill file that was read during the session. Include routing branch files (e.g. `FRONTEND.md`, `WORKFLOW.md`). Format:

```
Skills loaded this session:
- skills/routing/WORKFLOW.md (routing branch)
- skills/debug-trace/SKILL.md (leaf skill)
- skills/nestjs/SKILL.md (leaf skill)
```

**Step 2: Assess routing quality per skill**

For each skill loaded, assess whether the routing path to reach it was correct and efficient:

- Did the right branch file point to this skill?
- Were any wrong branches visited before the correct one?
- Was the routing decision table ambiguous for this task type?
- Did the agent load this skill directly instead of via the tree (override)?

**Step 3: Assess skill content quality per skill**

For each leaf skill loaded, assess the content:

- Were the instructions complete enough to execute the task without improvising?
- Were any sections missing that this task required?
- Were any sections present that gave wrong or outdated guidance?
- Was the "When to Use" trigger accurate for this task?
- Were the anti-patterns table entries relevant to what was actually encountered?

**Step 4: Identify failure patterns**

A failure pattern is any situation where the skill system (routing + content) produced a worse outcome than it should have. This includes:

- Agent loaded wrong skill first and had to backtrack
- Agent had to improvise because skill content was incomplete
- Agent followed skill instructions that produced incorrect output
- Agent skipped a combination rule and the task suffered for it
- Two skills gave conflicting guidance on the same decision

**Step 5: Identify missing skills or sections**

Record any task requirements that no skill covered:

- Was there a technical pattern used that belongs in an existing skill but is absent?
- Was there a workflow scenario not handled by any routing branch?
- Was there a combination of skills that should be a documented recipe but isn't?

**Step 6: Append to per-skill failure-patterns.md**

For each skill that has a non-OK entry, append to `skills/<skill-name>/references/failure-patterns.md`.

Create the file if it does not exist. Always append — never overwrite.

Format:

```markdown
## [YYYY-MM-DD] — [severity]: [short title]

**Task context**: [one-line description of the task where this was observed]
**Observed**: [what the skill did or failed to do]
**Impact**: [what went wrong as a result, or "none" if caught early]
**Suggested fix**: [specific section, wording, or rule to add/change/remove]
**Status**: [open | fixed in vX.Y.Z]
```

**Step 7: Append to global FAILURES.md**

Append a compact entry to `skills/routing/FAILURES.md`.

Create the file if it does not exist. Always append — never overwrite.

Format:

```markdown
## [YYYY-MM-DD] — [severity] — [skill-name]

[One-line summary of the failure or signal]
Detail: skills/[skill-name]/references/failure-patterns.md
```

---

## Output Templates

### Per-Skill failure-patterns.md (create if missing)

```markdown
# Failure Patterns — [skill-name]

This file is maintained by the `session-learning` skill.
Entries are appended automatically after /implement and /review sessions.
Human review is required before acting on any CRITICAL or WARN entry.

<!-- entries below, newest last -->
```

### Global FAILURES.md (create if missing)

```markdown
# Global Failure Pattern Rollup

Maintained by `session-learning`. Entries link to per-skill detail files.
Human review cadence: before each minor version bump.

| Date | Severity | Skill | Summary |
|---|---|---|---|
<!-- entries appended below -->
```

---

## Combination Rules

- Run AFTER `session-handoff` when both are triggered in the same session — handoff captures what was built, learning captures how the skill system performed
- Run BEFORE `skill-creator` when a `MISSING` entry suggests a new skill is needed — the learning record is the input to the skill scaffold
- `CRITICAL` entries should trigger a `/new-skill` or direct skill edit before the next session on the same codebase
- `ROUTING` entries require a change to `AGENTS.md` or a routing branch file — not the leaf skill

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Overwriting failure-patterns.md | Always append — history must not be lost |
| Recording only failures | Record OK entries too — confirms healthy skills |
| Deferring FAILURES.md update to later | Update both files in the same session-learning pass |
| Blaming skill quality for a routing problem | Distinguish routing vs content issues explicitly |
| Promoting a fix to a skill without human review | Mark as `open` — human reviews before applying |
| Writing vague failure descriptions | Be specific: which section, which instruction, what it caused |
| Inferring failures from tasks not performed | Only record what was directly observed this session |

## Connected Skills

- `session-handoff` — run handoff first; session-learning is the second step of session close
- `skill-creator` — use to act on MISSING entries that deserve a new skill
- `project-context` — if session-learning reveals a context gap, update project-context conventions
- `changelog-generator` — include skill system changes in release CHANGELOG entries
