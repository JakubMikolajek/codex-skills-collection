---
name: debug-trace
description: Enforce structured root cause analysis before writing any fix. Use for any bug, error, crash, or unexpected behavior — prevents surface-level patches on deeper problems.
---

# Debug Trace

This skill enforces structured root cause analysis before any fix is written. It prevents surface-level patches by requiring a complete Debug Report before code changes. No fix without a trace.

## When to Use

- Task contains: "bug", "error", "fix", "broken", "not working", "failing", "crash", "exception", "wrong output"
- A test is failing and the cause is not immediately obvious
- A previous fix did not resolve the issue (regression or misdiagnosis)
- Behavior differs between environments (local vs CI, iOS vs Android, dev vs prod)

## When NOT to Use

- Task is planned feature implementation with no existing bug
- Task is a refactor where the current behavior is correct but the code needs restructuring
- User explicitly provides the root cause and only needs help writing the fix

## Core Principles

### No Fix Without a Debug Report

This is non-negotiable. Writing code before completing analysis produces patches, not fixes. The Debug Report must be completed before any fix code is written.

### Mandatory Pre-Fix Analysis

Follow these steps in order. Do not skip steps.

**Step 1 — Reproduce**

Confirm the exact condition that triggers the bug: input, state, environment, user action sequence. If it cannot be reproduced, do not proceed to Step 2 — see "Cannot Reproduce" below.

**Step 2 — Isolate**

Identify the smallest code unit responsible: function, component, query, middleware. Narrow by removing surrounding code mentally or via test.

**Step 3 — Trace**

Follow the execution path from trigger to failure. List each step. Identify where behavior diverges from expected.

**Step 4 — Hypothesize**

State 2–3 candidate root causes ranked by likelihood. Include reasoning for each ranking.

**Step 5 — Verify**

Confirm which hypothesis is correct before writing any fix. Use existing tests, add a failing test, or add temporary logging.

## Debug Report Format

Output this report before any fix:

```
## Debug Report
Reproduce condition: [exact input/state/environment]
Isolated unit: [file:line or function name]
Trace summary: [step-by-step from trigger to failure]
Hypotheses: [ranked list with reasoning]
Confirmed root cause: [hypothesis verified by evidence]
```

## Debug Trace Process

Use the checklist below and track your progress:

```
Debug trace progress:
- [ ] Step 1: Reproduce the bug
- [ ] Step 2: Isolate the smallest responsible unit
- [ ] Step 3: Trace execution path from trigger to failure
- [ ] Step 4: Generate 2-3 ranked hypotheses
- [ ] Step 5: Verify the correct hypothesis
- [ ] Step 6: Output Debug Report
- [ ] Step 7: Write fix addressing confirmed root cause
- [ ] Step 8: Write regression test
```

## After Debug Report — Fix Rules

- Fix must address confirmed root cause, not the symptom
- If fix touches more than 3 files: flag as potential architectural issue, recommend `architecture-design`
- Write a regression test for the confirmed root cause alongside the fix
- Re-run all related tests after the fix to confirm no secondary regressions

## Cannot Reproduce

When the bug cannot be reproduced:

- Document all known conditions and what was tried
- Add defensive logging at the suspected failure point
- Do not guess — present options to the user and ask for more context
- Never write a speculative fix for an unreproducible bug

## External Dependency Bugs

When the root cause is in an external dependency:

- Isolate to the dependency call (do not patch around it)
- Check dependency changelog and open issues
- Document the dependency as the root cause before considering a workaround
- If a workaround is needed, document it as a temporary measure with a removal plan

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Writing fix before completing trace | Always complete Debug Report first |
| Fixing the symptom ("just add null check") | Trace to why null reaches that point |
| One hypothesis, no alternatives | Always generate 2–3 ranked hypotheses |
| Fix without regression test | Every fix ships with a test that would have caught it |
| "I think it might be X" without verification | Verify before writing fix code |
| Patching around external dependency | Isolate and document, then decide on workaround |
| Speculative fix for unreproducible bug | Document conditions and ask for more context |

## Connected Skills

- `technical-context-discovery` — understand project structure before tracing
- `code-review` — review fix after debug-trace to catch secondary issues
- `architecture-design` — escalate when fix scope exceeds 3 files
