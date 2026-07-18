# Knowledge Distillation — Candidates, Not Automatic Promotion

Session and debug notes stay raw chronological capture — do not retroactively "clean them up."
Distillation is a separate, later pass that extracts durable knowledge out of that raw capture.

This is deliberately **not** the same track as `session-handoff`'s `Observed Patterns` /
`PROMOTE`/`WATCH`/`REJECT` section. That one is about the *skill system* — routing quality, missing
skill content, conventions worth adding to a `SKILL.md`. This one is about *reusable technical
knowledge* — a concept, pattern, playbook, comparison, or experiment worth keeping regardless of
whether any skill file changes. Keep them separate: a skill-routing failure belongs in
`session-learning`/`FAILURES.md`; a durable technical insight belongs in this pipeline. Don't let
one contaminate the other's evidence trail.

## When to run this

- At natural session end, alongside (but separate from) `session-handoff`.
- During a periodic (e.g. weekly) review pass, looking back across several sessions at once.

## The process

1. **Extract candidates.** Look back at the session(s) and identify anything that could become a
   `concept`, `pattern`, `playbook`, `comparison`, or `experiment` note (see
   `note-types.md` for what distinguishes each).
2. **Place candidates in `00-inbox/knowledge-candidates/`.** Not directly into
   `03-skills/{concepts,patterns,...}/` — candidates are unreviewed by definition.
3. **Link every candidate to its evidence** — the session note, code location, ADR, or debug trace
   it came from. A candidate with no traceable evidence is not ready to be a candidate yet.
4. **Label it** using the same semantics `session-handoff` already uses, applied to technical
   knowledge instead of skill patterns:
   - `PROMOTE` — clear, repeatable, ready for a human to move into its durable home
   - `WATCH` — plausible but needs more confirming evidence before promotion
   - `REJECT` — considered and specifically not worth keeping (record why, so it isn't re-proposed)
5. **Require human review before promotion.** An agent never moves a candidate from
   `00-inbox/knowledge-candidates/` into `03-skills/`, `05-systems/`, or `06-experiments/` on its
   own. Promotion is a human action, even when the candidate is well-evidenced.
6. **Repeated-evidence bar for anything that would also change a skill file.** If a candidate's
   pattern has repeated across at least three independent observations (not three mentions in one
   session), it's strong enough to also suggest a permanent skill update via `skill-creator` — but
   that suggestion still goes through the normal skill-system human review, not this pipeline
   directly promoting into `skills/`.

## Candidate file shape

```markdown
---
date: {{date}}
type: candidate
proposed_type: concept | pattern | playbook | comparison | experiment
status: watch | promote | reject
source: "[[evidence-note]]"
---

# {{Candidate title}}

## Observation
<!-- what was seen, precisely -->

## Evidence
- "[[session-or-debug-note]]"
- path/to/code:line

## Why {{PROMOTE|WATCH|REJECT}}
<!-- the actual reasoning a human reviewer needs -->
```

## Anti-pattern

Do not treat "the agent wrote a note" as equivalent to "the vault gained durable knowledge." A
`00-inbox/knowledge-candidates/` entry that never gets reviewed is not knowledge yet — it's a
draft. Distillation without the human review step is exactly the "automatic knowledge pollution"
this process exists to avoid.
