---
name: product-intent
description: Establish and verify product intent before and after implementation. Translates business requirements into measurable acceptance criteria, validates that implementation actually realizes the intended user value, and flags divergence between what was built and what was needed. Use before task-analysis or architecture-design when the feature's purpose is ambiguous, and after implementation to verify the user-facing outcome — not just technical correctness.
---

# Product Intent

This skill bridges business requirements and technical implementation. It ensures the team is building the right thing before building it well, and verifies the right thing was actually delivered after.

## When to Use

- User describes a feature without stating a clear user goal or success condition
- Task involves a new user-facing flow, screen, or interaction
- Implementation plan exists but no one has asked "why does this matter to the user?"
- After implementation to verify the shipped code actually satisfies the stated user need
- When `implementation-gap-analysis` signals technical completeness but the feature still feels wrong
- Before `task-analysis` or `architecture-design` when the feature scope is ambiguous
- When a stakeholder or ticket describes *what* to build but not *for whom* or *why*

## When NOT to Use

- Task is purely infrastructure, refactoring, or developer tooling with no end-user surface
- Product intent is already clearly documented and agreed upon in a PRD or ticket — skip directly to `task-analysis`
- Task is a bug fix with a clear reproduction — bug fixes restore existing intent, not establish new intent
- User explicitly says "I know what I want, help me build it"

## Core Principles

### Intent Before Architecture

Do not let technical decisions precede intent clarity. A perfectly architected system that solves the wrong problem is a failure. Run this skill before `architecture-design` and `task-analysis` when the user goal is not explicit.

### Measurable Success Criteria

Vague acceptance criteria ("user can see their data") are useless for verification. Every success criterion must be concrete enough to pass or fail a manual or automated test.

Bad: "User can manage their documents"
Good: "User can upload a document ≤10MB, see it listed within 2 seconds, and delete it — with the deletion reflected immediately in the list"

### Anti-Goals Are First-Class

Stating what a feature explicitly does NOT do is as valuable as stating what it does. Anti-goals prevent scope creep, keep the implementation focused, and give agents a basis for declining out-of-scope requests.

### Risk of Misimplementation

Every feature has a canonical way it can be technically correct but user-value incorrect. Making this explicit upfront prevents building the wrong thing well.

## Product Intent Process

Use the checklist below and track progress:

```
Product Intent progress:
- [ ] Step 1: Extract or clarify the user story
- [ ] Step 2: Define measurable success criteria
- [ ] Step 3: State explicit anti-goals
- [ ] Step 4: Identify risk of misimplementation
- [ ] Step 5: Produce product-intent.md output
- [ ] Step 6: Verify intent against shipped implementation (post-implementation only)
```

**Step 1: Extract or clarify the user story**

Identify:
- **Who** is the user (role, context, technical level)?
- **What** do they want to accomplish?
- **Why** does this matter to them — what problem does it solve?

If the task description does not answer all three, surface the gaps explicitly before proceeding. Do not assume intent.

Format: `As a [user], I want to [action] so that [outcome].`

**Step 2: Define measurable success criteria**

Write 3–6 concrete, binary success criteria. Each criterion must be verifiable without subjective judgment.

Ask: "Could a QA engineer or automated test check this without asking for clarification?"

Criteria categories to cover:
- Functional: the core action works end-to-end
- Performance: the action completes within an acceptable time threshold
- Error handling: failure states are surfaced clearly to the user
- Persistence: data survives refresh/re-entry where expected
- Access: the feature is accessible to the target user only (auth, permissions)

**Step 3: State explicit anti-goals**

List 2–4 things this feature explicitly does NOT do in this iteration. Anti-goals:
- Prevent scope creep during implementation
- Give agents a clear basis for declining tangential requests
- Communicate deferred work without losing it

**Step 4: Identify risk of misimplementation**

State the most likely way this feature could be technically complete but user-value incomplete. Common failure modes:
- "We built the happy path only — edge cases destroy the UX"
- "The data is correct but the latency makes the feature unusable"
- "Feature works for the agent's mental model of the user, not the actual user's mental model"
- "We optimized for engineer convenience instead of user flow"

**Step 5: Produce product-intent.md output**

Write `.codex/product-intent.md` in the repo. Use the template below.

**Step 6: Verify intent against shipped implementation (post-implementation only)**

After implementation is complete, run a verification pass:
- Check each success criterion: pass or fail?
- Check anti-goals: were any violated or implicitly built?
- Check risk of misimplementation: did it materialize?
- If criteria fail: document gaps and add to `session-handoff` as Open Questions

## Output Template

```markdown
## Product Intent — [Feature Name] — [date]

### User Story
As a [user], I want to [action] so that [outcome].

### Context
[1–2 sentences about user context, technical level, or domain if relevant]

### Success Criteria
- [ ] [Criterion 1 — specific and binary]
- [ ] [Criterion 2]
- [ ] [Criterion 3]
- [ ] [Criterion 4]

### Anti-Goals
- Does NOT [explicit out-of-scope item 1]
- Does NOT [explicit out-of-scope item 2]

### Risk of Misimplementation
[The most likely way this can be technically correct but user-value incorrect]

### Verification Status
[Not verified / Verified [date] / Partially verified — gaps: ...]
```

## Post-Implementation Verification Checklist

Run this after any feature implementation where product-intent.md exists:

```
Verification:
- [ ] All success criteria pass (manual or automated)
- [ ] No anti-goals were implicitly implemented
- [ ] Risk of misimplementation was mitigated or explicitly accepted
- [ ] Edge cases covered: empty state, error state, permission denied
- [ ] Feature works for the user described in the story, not just the developer's mental model
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Writing acceptance criteria after implementation | Write criteria before implementation starts |
| "User can do X" as a success criterion | "User sees Y within Z seconds after doing X" |
| No anti-goals defined | Explicitly state what is deferred |
| Skipping intent verification after shipping | Run Step 6 before marking task complete |
| Letting implementation complexity reshape the user story | Escalate scope vs. constraint tension explicitly |
| Treating technical correctness as user-value correctness | Verify against the user story, not just the spec |

## Connected Skills

- `task-analysis` — run after product-intent to decompose the verified user story into implementation tasks
- `architecture-design` — product-intent output is the input to architecture decisions
- `implementation-gap-analysis` — verifies technical completeness; product-intent verifies value completeness
- `session-handoff` — include product-intent verification status in handoff
- `technical-context-discovery` — discover existing patterns before implementing verified intent
