---
name: obsidian-note
description: Creating notes in Obsidian according to the vault system
---

## When to use this skill

Use this skill **always** when:

- You finish a work session on a project → create a `session note`
- You make an architectural decision → create an `ADR`
- You fix a non-trivial bug → create a `debug trace`
- You learn a new pattern/technology → create a `knowledge note` in `03-skills/domains/`
- You start a new project → create a `project index`
- You isolate one durable technical idea worth reusing later → create a `concept`, `pattern`,
  `playbook`, `comparison`, `experiment`, or `system` note (see `references/note-types.md` for
  which one fits and how it differs from a broad `knowledge` domain note)

**Do not create a note** for: trivial changes, code formatting, routine CRUD.

## Runtime mode — hybrid vs standalone

This skill's schema, templates, and rules are canonical in **both** runtime modes. Who actually
performs the write differs:

- **Standalone** (Codex running without Claude): this skill invokes the full write process below
  directly, exactly as written.
- **Hybrid** (Claude + Codex together): Codex **never** writes to the vault, `_codex-config.md`,
  the ADR counter, `MOC.md`/`MOC/`, or any project `_index.md`. Instead, it returns a compact
  `OBSIDIAN EVIDENCE` block in its result/handoff, and the orchestrating Claude session performs
  the actual write using this same schema.

Full block format and the reasoning behind the split live in `references/runtime-modes.md` — read
it before assuming which mode applies. If the mode is genuinely ambiguous, do not write and do not
guess; say so and let the human resolve it (duplicate writers are worse than one missed note).

---

## First-time setup (per developer machine)

This skill needs a vault to write into. If you don't have one yet, stop here and follow
`references/quickstart.md` — it walks through creating the vault, the folder skeleton,
`_templates/`, and `_codex-config.md` step by step, with copy-paste blocks.

Once the vault exists, there is exactly **one** thing to configure in this file: `VAULT_ROOT`
below. Everything else (project slugs, ADR counter, linking rules, filename conventions) lives
in `VAULT_ROOT/_codex-config.md` — a normal Obsidian note you edit in the app, not in this repo.

```
VAULT_ROOT = ~/Desktop/Obsidian/Codex/    <!-- EDIT THIS to your vault's absolute path -->
```

If `VAULT_ROOT/_codex-config.md` does not exist, do not guess project slugs or paths — tell the
user to run the quickstart guide first.

---

## Vault paths

```
VAULT_ROOT/
├── _codex-config.md          # source of truth: project slugs, ADR counter, linking rules
├── _templates/                # copied once from skills/obsidian-note/references/templates/
├── 00-inbox/                  # drafts, uncategorized — clean weekly
│   └── knowledge-candidates/  # distillation candidates awaiting human review/promotion
├── 01-projects/
│   └── {project-slug}/
│       ├── _index.md          # project hub (create once, update as needed)
│       ├── _context.md        # compact, preload-sized current-state summary (see references/context-file.md)
│       └── sessions/
│           └── YYYY-MM-DD.md  # daily session
├── 02-adr/
│   └── ADR-{NNNN}-{slug}.md   # NNNN = 4-digit number, read+incremented via _codex-config.md
├── 03-skills/
│   ├── domains/                 # existing broad technology notes — may remain, may become MOCs
│   │   └── {technology}.md      # e.g. rust.md, nestjs.md, swiftui.md
│   ├── concepts/{atomic-slug}.md      # one technical idea/mechanism
│   ├── patterns/{atomic-slug}.md      # reusable implementation/architecture pattern
│   ├── playbooks/{atomic-slug}.md     # executable troubleshooting/delivery procedure
│   ├── comparisons/{atomic-slug}.md   # alternatives + decision criteria
│   ├── MOC/{technology}.md            # growing map-of-content per technology, atomic-note style
│   └── MOC.md                   # legacy flat map of content — still valid, do not migrate
├── 04-debug/
│   └── {YYYY-MM-DD}-{slug}.md
├── 05-systems/
│   └── {atomic-slug}.md         # architecture map, contracts, boundaries, current state
├── 06-experiments/
│   └── {atomic-slug}.md         # benchmark/hypothesis/result
├── 07-sources/                  # raw external reference material — no fixed note type yet
└── 08-reviews/                  # review output archive — no fixed note type yet
```

`05-systems/`, `06-experiments/`, `07-sources/`, `08-reviews/`, `00-inbox/knowledge-candidates/`,
and `03-skills/{concepts,patterns,playbooks,comparisons,MOC}/` are additive. Existing notes outside
them stay exactly where they are — this is not a migration.

---

## Configuration — `_codex-config.md`

Read this file at the start of every `/obsidian` invocation. Never hardcode project slugs, the
ADR counter, or linking rules in this SKILL.md — they belong to the vault, not the repo, and
change independently per developer.

Expected shape (see `references/_codex-config.example.md` for a full copy-paste starting point):

```yaml
projects:
  {slug}:
    slug: {slug}
    display: "{Display Name}"
    path: "01-projects/{slug}"
    tags: [tag1, tag2]
```

```
LAST_ADR = 0000
```

Resolution rules:
- To find a project's slug/path/tags, look it up in the `projects:` map — do not invent a slug
  from the repo folder name if it isn't listed.
- If the current project isn't in the map yet, ask the user for a slug and add a new entry to
  `_codex-config.md` under `projects:` before writing any note for it.
- For a new ADR, read `LAST_ADR`, use `LAST_ADR + 1` zero-padded to 4 digits as `{{NNNN}}`, then
  write the incremented value back to `_codex-config.md` in the same pass that creates the note.

---

## Wikilink rules [[...]]

### Always link:

- Every note links to the **project index**: `[[01-projects/{slug}/_index]]`
- ADR links to related skills: `[[03-skills/domains/{technology}]]`
- Session note links to ADRs from that session: `[[ADR-0012-{slug}]]`
- Debug trace links to project + technology: `[[01-projects/{slug}/_index]]` `[[03-skills/domains/{technology}]]`
- Knowledge note in domains/ links to projects where the technology is used

### Tags (#tag) — use consistently:

Note type:     #adr #session #debug #knowledge #project-index
ADR status:    #adr/accepted #adr/proposed #adr/superseded
Technology/domain tags come from the `tags:` list on each project entry in `_codex-config.md` —
reuse those exact tags rather than inventing new ones per note.

---

## Frontmatter — required

Every note MUST have frontmatter:

```yaml
---
date: YYYY-MM-DD
type: session | adr | debug | knowledge | project-index | concept | pattern | playbook | comparison | experiment | system
project: { canonical-slug }   # omit for knowledge / concept / pattern / comparison notes with scope: global
tags: [ tag1, tag2 ]
links: # explicit backlinks (supplement to [[wikilinks]])
  - "[[related-note]]"
---
```

The six new durable types (`concept`, `pattern`, `playbook`, `comparison`, `experiment`, `system`)
carry this additional frontmatter — compatible extension, does not replace the fields above:

```yaml
status: seed | verified | stable | stale
scope: global | { project-slug }
confidence: low | medium | high
source: code | docs | experiment | conversation
last_verified: YYYY-MM-DD
technologies: []
agent_priority: normal | high
supersedes: []   # [[older-note]] this one replaces, if any
```

- `status` starts at `seed` for a freshly-distilled candidate; only promote to `verified`/`stable`
  after the human review step in `references/knowledge-distillation.md`.
- `agent_priority: high` marks a note worth surfacing even under a tight retrieval budget (see
  `knowledge-retrieval` skill) — use sparingly, it only means something if most notes are `normal`.
- Never silently overwrite `status`, `confidence`, or `last_verified` downward without a reason —
  a `stable` note becoming `stale` is itself a fact worth a one-line note of why.

---

## Templates — invoke

Invoke the appropriate template from `VAULT_ROOT/_templates/` (copied once from this skill's
`references/templates/` during setup — see quickstart):

| Type          | Template                      | When                                  |
|---------------|-------------------------------|---------------------------------------|
| Session       | `_templates/session.md`       | After each work session               |
| ADR           | `_templates/adr.md`           | Architectural decision with rationale |
| Debug         | `_templates/debug.md`         | Bug required >15min of debugging      |
| Knowledge     | `_templates/knowledge.md`     | New pattern / technology (broad domain note) |
| Project index | `_templates/project-index.md` | New project                           |
| Concept       | `_templates/concept.md`       | One technical idea/mechanism, atomic  |
| Pattern       | `_templates/pattern.md`       | Reusable implementation/architecture pattern |
| Playbook      | `_templates/playbook.md`      | Executable troubleshooting/delivery procedure |
| Comparison    | `_templates/comparison.md`    | Alternatives + decision criteria      |
| Experiment    | `_templates/experiment.md`    | Benchmark/hypothesis/result           |
| System        | `_templates/system.md`        | Architecture map, contracts, boundaries |

The debug threshold above (>15min) is the single canonical value — do not restate a different
number anywhere else; point back to this line instead.

---

## Note creation algorithm

1. Read `VAULT_ROOT/_codex-config.md`. Stop and point to `references/quickstart.md` if it's missing.
2. Determine the note type
3. Resolve the project slug/path/tags from the `projects:` map in `_codex-config.md` (or add a
   new entry first, per the resolution rules above)
4. Determine the target path (see: Vault paths) — this must be the same deterministic path every
   time for the same logical note (e.g. the same session note for the same project+date, the same
   ADR number once assigned). Compute it, don't improvise a slug ad hoc.
5. **Check whether that exact file already exists.** If it does, this is a retry/resume/re-entry
   for the same note, not a new one — open it and update the relevant section instead of creating
   a duplicate. See `references/note-identity.md` for the per-type identity rule and worked
   examples. Only proceed to create a new file when it genuinely does not exist yet.
6. Copy the appropriate template from `VAULT_ROOT/_templates/` (new file only)
7. Fill in frontmatter (date, type, project, tags, and the extended fields for the six durable
   types — see Frontmatter above)
8. Fill in template sections — be specific, not generic
9. Add `[[wikilinks]]` to:
   - project index of the project
   - related ADRs
   - related technologies in `03-skills/domains/` (or the new atomic note types, where relevant)
   - previous session for this project (if one exists)
10. If this is an ADR, increment `LAST_ADR` in `_codex-config.md` in the same pass — this is the
    only ADR-numbering mechanism; nothing else in this vault assigns ADR numbers
11. Update `MOC.md` or the relevant `03-skills/MOC/{technology}.md` if this is a new knowledge
    domain or atomic note
12. Update the project's `_index.md` (add link to the new note)
13. Save the file at the correct path in the vault

---

## Note quality — principles

- **Specificity over generality**: instead of "fixed MQTT bug" → "Redis SET NX race condition with >1 NestJS instance —
  fix: prefix key with `{instanceId}:`"
- **Decisions with context**: ADR includes `## Why NOT {alternative}` — this is the most valuable part
- **Links as navigation**: the Obsidian graph is valuable — the more meaningful links, the better the graph view
- **Update, don't duplicate**: if a project note already exists, update `_index.md`, don't create a new one

---

## Knowledge distillation — candidates, not automatic promotion

Session/debug notes stay raw capture. Turning them into durable `concept`/`pattern`/`playbook`/
`comparison`/`experiment` notes is a separate, later pass through `00-inbox/knowledge-candidates/`
with mandatory human review before promotion — see `references/knowledge-distillation.md` for the
full process, and how it differs from `session-handoff`'s own `PROMOTE`/`WATCH`/`REJECT` pattern
track (that one is about the skill system; this one is about reusable technical knowledge — don't
mix the two evidence trails).

## Further reading in this skill

- `references/runtime-modes.md` — hybrid vs standalone writer ownership, `OBSIDIAN EVIDENCE` block
- `references/note-identity.md` — deterministic paths + duplicate-write prevention
- `references/note-types.md` — how to pick between the six durable note types
- `references/knowledge-distillation.md` — candidate → human review → promotion pipeline
- `references/context-file.md` — the compact `_context.md` per project
- `references/quickstart.md` — first-time vault setup
- `references/_codex-config.example.md` — copy-paste starting config

## Minimal example — session

File: `01-projects/{slug}/sessions/2026-01-15.md`

```markdown
---
date: 2026-01-15
type: session
project: {slug}
tags: [session, rust, lsp]
links:
  - "[[01-projects/{slug}/_index]]"
  - "[[03-skills/domains/rust]]"
---

# {Project} — session 2026-01-15

## What was done

- Implemented PSI node visitor for Rust LSP
- Fixed lifetime issue in `SemanticRuntime::resolve()`

## Decisions

- Chose `Arc<RwLock<T>>` over `Mutex` for read-heavy cache → see [[ADR-0015-lsp-concurrency]]

## Blockers

- `tonic` streaming does not natively support graceful shutdown — needs investigation

## Next session

- [ ] Graceful shutdown in tonic
- [ ] Integration tests for visitor pattern
```
