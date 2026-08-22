---
name: resolving-merge-conflicts
description: Resolve an in-progress git merge or rebase conflict hunk by hunk by tracing each side's intent to its primary source, then finish the operation.
---

# Resolving Merge Conflicts

This skill resolves active merge and rebase conflicts without blindly choosing a side or losing either change's intent.

## When to Use

- `git status` shows an in-progress merge or rebase with `Unmerged paths`
- The working tree contains conflict markers from an active merge or rebase
- User asks to resolve, continue, or finish a conflicted merge or rebase

## When NOT to Use

- No merge or rebase is in progress — this skill resolves an existing operation; it does not start one
- A trivial conflict is already fully understood and intent tracing would be pure overhead — still run a quick sanity check

## Core Principle

### Intent-Traced Resolution

- For each conflicting hunk, find the primary source for each side's change: commit message, PR or issue description, linked ticket
- Understand why each change was made before choosing a resolution
- Never pick `ours` or `theirs` blindly

## Resolution Process

Use the checklist below and track your progress:

```
Merge conflict resolution progress:
- [ ] Step 1: Assess operation state and list conflicted files
- [ ] Step 2: Read each conflicted hunk and trace both sides' intent
- [ ] Step 3: Resolve each hunk without inventing behavior
- [ ] Step 4: Run relevant automated checks after each file is resolved
- [ ] Step 5: Stage resolved files and continue the operation
```

**Step 1 — Assess current state**

1. Run `git status`
2. List conflicted files: `git diff --name-only --diff-filter=U`
3. Confirm whether the active operation is a merge or rebase

**Step 2 — Trace intent hunk by hunk**

1. Read both sides of every conflicting hunk
2. Find each side's primary source: commit message, PR or issue description, linked ticket
3. Record why each side changed the code before resolving the hunk

**Step 3 — Resolve deliberately**

1. Preserve both intents where possible
2. Where intents are genuinely incompatible, choose the one matching the merge's stated goal
3. Explicitly note the trade-off in a code comment or merge commit message
4. Never silently discard the other side's work
5. Do not invent behavior beyond what either side already expressed

**Step 4 — Verify resolved files**

1. After all hunks in a file are resolved, discover relevant checks through `technical-context-discovery`
2. Run the applicable typecheck, tests, and formatting checks; do not guess commands

**Step 5 — Complete the operation**

1. Stage resolved files
2. Run `git merge --continue` or `git rebase --continue`, matching the active operation
3. Never run `git merge --abort` or `git rebase --abort`
4. If genuinely stuck, stop and ask the user rather than aborting

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Picking `ours` or `theirs` without checking intent | Trace both sides to their primary sources first |
| Running `--abort` to escape a hard conflict | Stop and ask the user when resolution cannot proceed |
| Resolving conflicts without running checks | Run the relevant project checks after each resolved file |
| Silently discarding one side's work | Preserve both intents or explicitly note the trade-off |
| Inventing behavior neither side expressed | Resolve only from behavior already present on either side |

## Connected Skills

- `technical-context-discovery` — discover the correct project checks before running them
- `code-review` — review non-trivial conflict resolutions after the operation finishes
