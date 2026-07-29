# Runtime Modes — Hybrid vs Standalone

This vault must have exactly one writer per session/task. Two modes decide who that is; picking
the wrong one (or leaving it ambiguous) produces duplicate session notes, divergent ADR numbers,
and competing edits to `MOC.md`/project indexes. This file is the canonical definition both modes
must follow — do not restate or fork these rules elsewhere.

## Standalone mode — Codex without Claude

Codex runs `obsidian-note` directly and owns the complete write process exactly as `SKILL.md`
describes: reads `_codex-config.md`, resolves the project, checks for an existing note (see
`note-identity.md`), writes/updates the file, updates counters/indexes in the same pass.

The existing `/handoff` → `/obsidian session` automatic chain remains available in this mode.

## Hybrid mode — Claude + Codex together

Claude is the single Obsidian writer and orchestration owner. Concretely:

- Claude detects session/ADR/debug/knowledge/routing-gap/durable-note triggers using this same
  canonical schema and thresholds — it does not maintain a separate copy of them.
- **Codex never edits the vault, `_codex-config.md`, the ADR counter, `MOC.md`/`MOC/`, or any
  project `_index.md` or `_context.md` in this mode.** Not even to "help" — a second writer
  defeats the single-writer guarantee even when its intentions are good.
- Instead, Codex returns a compact `OBSIDIAN EVIDENCE` block (format below) in its result or
  handoff whenever durable knowledge may have been produced.
- Claude combines that evidence with the human collaborator's parallel work and conversation-level decisions,
  removes duplication, then creates or updates the correct note itself, following this skill's
  algorithm and the identity rule in `note-identity.md`.
- Claude announces the final note exactly once. A Codex delegation completing must not produce a
  second announcement of the same note.

### The `OBSIDIAN EVIDENCE` block

Codex includes this in its result/handoff text whenever the task plausibly produced durable
knowledge (a real decision, a non-trivial fix, a new pattern) — not on every task:

```
OBSIDIAN EVIDENCE

Confirmed facts:
- <fact 1, directly observed this task>

Decisions made:
- <decision> — rationale: <why>

Rejected alternatives:
- <alternative> — why not: <reason>

Root cause (if a debug task):
- <one line>

Files / evidence:
- path/to/file.ts:42 — <what changed and why it matters>

Unresolved questions:
- <anything left open>

Suggested note type: session | adr | debug | concept | pattern | playbook | comparison | experiment | system
```

Rules for Codex producing this block:
- Only the "Confirmed facts" and "Files / evidence" sections are close to mandatory when the block
  is included at all — the rest are optional per task, but never fabricate content to fill a
  section that has nothing real to report.
- "Suggested note type" is a suggestion, not a write — Claude makes the final call, since it also
  sees the human collaborator's parallel work and the rest of the conversation.
- Do not include this block for trivial tasks with no durable-knowledge signal; an empty or
  boilerplate block is noise, not evidence.

## Determining which mode is active

- If this session was launched by a Claude Code orchestrator delegating to Codex, it is hybrid —
  Codex must not write.
- If Codex is running standalone (CLI, no Claude orchestrator in the loop), it is standalone —
  Codex writes directly.
- If genuinely unable to tell, do not guess and do not write. Report the ambiguity instead of
  risking a duplicate writer — a missed note is recoverable, a duplicate/conflicting one is not.
