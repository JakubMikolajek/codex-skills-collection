---
name: session-handoff
description: Produce a structured handoff document at session end so the next session or teammate can resume without context loss. Use when wrapping up any implementation, review, or multi-step task.
---

# Session Handoff

This skill provides a structured process for producing a handoff document at the end of a session. It ensures the next session or teammate can resume without re-discovering what was done, what remains, and what decisions were made.

## When to Use

- User says "done for now", "wrap up", "handoff", "pause", or "end session"
- Session reaches a natural completion point (PR ready, task deployed, review delivered)
- Multi-repo task completes (mandatory — always run handoff)
- Before switching to a different task in the same session

## When NOT to Use

- Session consisted only of answering a question with no file modifications
- User explicitly says "no handoff needed" or "skip handoff"
- Task was a single-response answer that did not modify any files

## Core Principles

### Output File

Output file: `.codex-handoff.md` in repo root — always overwrite, never append.

### Handoff Document Structure

```markdown
## Handoff — [date]

### Status
[What was fully completed this session. Past tense. Specific.]

### In Progress
[Tasks started but not finished. Include exact stopping point and file/line if relevant.]

### Blocked
[What cannot proceed and why. Always include reason — never just "blocked".]

### Decisions Made
[Architectural or implementation decisions taken this session, with brief rationale.]

### Files Modified
[Every file touched. Format: `path/to/file.ts` — one-line description of change.]

### Next Steps
[Ordered list. Specific enough to act on without reading session history.]

### Open Questions
[Unresolved questions requiring human input or further research.]

### Observed Patterns
[NEW — see pattern extraction section below]
```

### Writing Rules

- Use file paths, not folder names
- Use line numbers when describing exact stopping points
- Next Steps must be actionable by someone who was not in the session
- Do not mark anything complete if tests are failing or review is pending
- Include the Session Context Block from `project-context` when available

## Session Handoff Process

Use the checklist below and track your progress:

```
Handoff progress:
- [ ] Step 1: Collect list of files modified
- [ ] Step 2: Summarize completed work
- [ ] Step 3: Document in-progress and blocked items
- [ ] Step 4: Record decisions made with rationale
- [ ] Step 5: Write actionable next steps
- [ ] Step 6: List open questions
- [ ] Step 7: Extract observed patterns (see below)
- [ ] Step 8: Write .codex-handoff.md
```

**Step 1: Collect list of files modified**

Gather every file touched during the session. Include config changes, test files, and documentation.

**Step 2: Summarize completed work**

Write past-tense, specific descriptions of what was fully completed. Avoid vague statements.

**Step 3: Document in-progress and blocked items**

For in-progress items, include the exact stopping point (file, line, function). For blocked items, always include the reason.

**Step 4: Record decisions made with rationale**

List architectural or implementation decisions taken during the session. Include brief rationale for each.

**Step 5: Write actionable next steps**

Write an ordered list of next steps. Each step must be specific enough that someone who was not in the session can act on it.

**Step 6: List open questions**

Document any unresolved questions that require human input or further research.

**Step 7: Extract observed patterns**

This is the pattern extraction step for the self-improving workflow. Its output feeds the skill system over time — human-reviewed before being promoted to a permanent skill.

Look back at the work done this session and extract patterns that were either:
- **Discovered**: conventions, idioms, or structures already in the codebase that are not yet in any skill
- **Established**: new conventions created during this session that future work should follow
- **Violated**: existing patterns that were deliberately not followed, with reason

For each observed pattern, assess its **promotion signal**: how strongly does this pattern deserve to be in a skill file?

| Signal Level | Criteria |
|---|---|
| `promote` | Pattern appears 3+ times in codebase, is consistent, and is clearly intentional |
| `watch` | Pattern appeared this session, looks like a convention but needs 1-2 more data points |
| `reject` | Observed but should not be followed — legacy code, workaround, or accidental |

**Only extract patterns you observed directly** — do not infer patterns from code you did not read.

Format each observed pattern as:

```
- [PROMOTE/WATCH/REJECT] [pattern name]: [description of the pattern]
  Source: [file or module where observed]
  Candidate skill: [which skill file this belongs in, if promoted]
```

**Step 8: Write .codex-handoff.md**

Assemble all sections into `.codex-handoff.md` in the repo root. Overwrite any existing handoff file.

## Observed Patterns Section Template

```markdown
### Observed Patterns
<!-- 
  Extracted by agent for human review. Promoted patterns feed back into skill files.
  Review and promote/reject before next skill update cycle.
-->

#### [PROMOTE] [Pattern Name]
Description: [What the pattern is and when it applies]
Source: [path/to/file.py or module name]
Candidate skill: [skill-name/SKILL.md — section: [section name]]
Evidence: [Why this deserves promotion — frequency, consistency, intentionality]

#### [WATCH] [Pattern Name]
Description: [What was observed]
Source: [where]
Candidate skill: [target skill if promoted]
Note: [What additional evidence would confirm this pattern]

#### [REJECT] [Pattern Name]
Description: [What was observed]
Source: [where]
Reason: [Why this should not be followed]
```

## Pattern Promotion Workflow

This is the **human-in-the-loop** part of the self-improving workflow. Agent extracts → human reviews → skill gets updated.

1. After session ends, review the `Observed Patterns` section in `.codex-handoff.md`
2. For each `PROMOTE` candidate: decide if it belongs in an existing skill or needs a new one
3. Use `skill-creator` to scaffold a new skill, or edit an existing `SKILL.md` directly
4. For each `WATCH` candidate: note it for the next session; do not promote yet
5. For each `REJECT` candidate: document the anti-pattern in the relevant skill's anti-patterns table
6. After promoting, clear the pattern from the handoff file to avoid re-processing

This workflow ensures that the agent's pattern recognition feeds the skill system incrementally, without risk of contaminating skill quality with poorly-observed or incorrect patterns.

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| "Fixed the bug" | "Fixed null pointer in `auth/session.ts:142` when token expires" |
| Omitting files from Files Modified | List every file touched, including config changes |
| Marking task complete with failing tests | Move to In Progress with test failure noted |
| Vague Next Steps ("continue the work") | Specific Next Steps ("implement `POST /sessions` endpoint per plan section 3") |
| Skipping handoff on "small" sessions | Always produce handoff if any file was modified |
| Appending to existing handoff file | Always overwrite — each handoff is a clean snapshot |
| Extracting patterns from code not read this session | Only report patterns directly observed |
| Promoting patterns after a single occurrence | Mark as `watch`; promote after 3+ occurrences |
| Human skipping pattern review | Pattern extraction only has value if reviewed and actioned |

## Connected Skills

- `project-context` — include Session Context Block in handoff when available
- `multi-repo` — multi-repo tasks must always trigger session-handoff
- `changelog-generator` — run after handoff on release sessions
- `skill-creator` — use to promote `PROMOTE`-level observed patterns into skill files
