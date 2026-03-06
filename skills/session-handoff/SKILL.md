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
- [ ] Step 7: Write .codex-handoff.md
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

**Step 7: Write .codex-handoff.md**

Assemble all sections into `.codex-handoff.md` in the repo root. Overwrite any existing handoff file.

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| "Fixed the bug" | "Fixed null pointer in `auth/session.ts:142` when token expires" |
| Omitting files from Files Modified | List every file touched, including config changes |
| Marking task complete with failing tests | Move to In Progress with test failure noted |
| Vague Next Steps ("continue the work") | Specific Next Steps ("implement `POST /sessions` endpoint per plan section 3") |
| Skipping handoff on "small" sessions | Always produce handoff if any file was modified |
| Appending to existing handoff file | Always overwrite — each handoff is a clean snapshot |

## Connected Skills

- `project-context` — include Session Context Block in handoff when available
- `multi-repo` — multi-repo tasks must always trigger session-handoff
- `changelog-generator` — run after handoff on release sessions
