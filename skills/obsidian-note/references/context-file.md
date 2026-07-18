# `_context.md` — Compact Per-Project State

`01-projects/{slug}/_context.md` is a short, preload-sized summary of a project's *current* state
— distinct from `_index.md` (the durable hub linking to everything) and from session notes (raw
chronological capture). It exists so an orchestrator (or the `knowledge-retrieval` skill) can load
one small file and get oriented, instead of reading the whole project history.

## What belongs in it (and nothing else)

- Current state in one short paragraph.
- Active constraints (things that limit what's possible right now — a deprecation deadline, a
  frozen contract, a resource limit).
- Key contracts (links to the ADRs/system notes that define them, not the contracts themselves).
- Accepted decisions (links to ADRs — one line each, not the rationale).
- Known traps (things that have bitten someone before — link to the debug trace or playbook).
- Active threads (what's actually being worked on right now).

Detailed evidence stays in the linked notes. If a section is growing past a few lines, that's a
sign the detail belongs in a linked note instead, not in `_context.md` itself.

## Template

Note content is Polish, per the vault's language policy — see
`skills/obsidian-note/references/templates/_context.md` for the canonical copy-paste template.
Structure (English gloss, for this reference doc only):

```markdown
---
date: {{date}}
updated: {{date}}
type: context
project: {{project-slug}}
---

# {{Project name}} — current context

## State (Stan)
<!-- one short paragraph -->

## Active constraints (Aktywne ograniczenia)
-

## Key contracts (Kluczowe kontrakty)
- "[[ADR-NNNN-slug]]" / "[[05-systems/slug]]"

## Accepted decisions (Zaakceptowane decyzje)
- "[[ADR-NNNN-slug]]" — one line

## Known traps (Znane pułapki)
- "[[04-debug/slug]]" / "[[03-skills/playbooks/slug]]"

## Active threads (Aktywne wątki)
-
```

## Who maintains it

Whoever writes the vault in the current runtime mode (Claude in hybrid mode, Codex in standalone
mode, per `runtime-modes.md`) updates `_context.md` as part of the normal session-note write —
not as a separate task. Treat stale entries the same way as a stale `system` note: mark or remove
what no longer applies rather than letting it silently drift from reality.

## Relationship to retrieval

The `knowledge-retrieval` skill reads `_context.md` first, before pulling any additional atomic
notes — it is the cheapest, highest-value thing to load for orientation. See that skill's
`SKILL.md` for how it's combined with the rest of a context pack.
