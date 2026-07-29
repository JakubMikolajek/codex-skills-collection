# The Six Durable Note Types — When Each One Fits

All six are **atomic**: one idea, one file. None of them should become a growing dumping ground
the way a broad `03-skills/domains/{technology}.md` file can. If you notice yourself writing
"also, unrelated to the above..." inside one of these, that is a second note, not a section.

| Type | Answers | Example slug |
|---|---|---|
| `concept` | What is this one mechanism/idea, precisely? | `nestjs-config-runtime-env-precedence` |
| `pattern` | What reusable shape solves this recurring problem? | `vue-offline-cache-dexie-tanstack-query` |
| `playbook` | What exact steps do I run when this situation happens again? | `mediamtx-two-stream-bidirectional-audio` |
| `comparison` | Given these options, which one and why? | `nestjs-orm-typeorm-vs-prisma` |
| `experiment` | What did I measure, under what hypothesis, with what result? | `swiftui-webrtc-track-lifecycle-benchmark` |
| `system` | What does this architecture actually look like right now? | `desktop-app-tauri-ipc-boundary` |

## Concept vs. broad `knowledge` domain note

`03-skills/domains/{technology}.md` (the existing `knowledge` type) is allowed to stay broad and
cover a whole technology. A `concept` note is the atomic alternative: one precise mechanism inside
that technology. Prefer creating atomic `concept`/`pattern` notes going forward, and let existing
broad domain notes gradually turn into MOCs that link out to the atomic ones — do not force an
immediate rewrite of `nestjs.md`, `rust.md`, or `webrtc.md`.

## Pattern vs. playbook

A `pattern` is a reusable *shape* (how to structure the code/architecture). A `playbook` is a
reusable *procedure* (the ordered steps a human or agent runs when a specific situation recurs,
e.g. "MediaMTX loses the return audio stream after a reconnect — do X, then Y, then Z"). If the
note is mostly an ordered checklist you'd want to hand to whoever's on call, it's a playbook.

## Comparison vs. ADR

An ADR records a decision *for a specific project*, with project-scoped consequences. A
`comparison` is broader and reusable: the same alternatives/decision-criteria table is useful
across multiple projects, even ones that ended up choosing differently. When a project-specific
decision is really an instance of a comparison that already exists (or should exist), the ADR
should link to the comparison note rather than re-deriving the trade-off table from scratch.

## Experiment

Only for something actually measured or tested against a stated hypothesis — a benchmark, a load
test, an A/B of two implementations. Not a general note about "trying something out" with no
result recorded.

## System

A `system` note is the closest thing to living architecture documentation: contracts, boundaries,
current state of one system or one cross-cutting concern (e.g. "how auth tokens flow between the
desktop app and the backend API right now"). Update it in place as the system evolves — it is one
of the few note types expected to change status from `stable` to `stale` and back as reality
shifts, rather than being written once and left alone.

## Confidence and status — use them honestly

- `status: seed` — first pass, likely incomplete, came out of `00-inbox/knowledge-candidates/`
  and hasn't been human-reviewed yet.
- `status: verified` — a human has reviewed it and confirmed it's accurate as written.
- `status: stable` — verified and unlikely to change soon; safe to treat as settled.
- `status: stale` — known or suspected to no longer match reality; do not delete, mark and link
  the replacement if one exists (`supersedes`).
- `confidence` is about how sure you are the content is *correct*, independent of `status` (a
  `seed` note can still have `confidence: high` if the observation itself is solid, just not yet
  reviewed for placement/wording).
