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

**Do not create a note** for: trivial changes, code formatting, routine CRUD.

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
├── 01-projects/
│   └── {project-slug}/
│       ├── _index.md          # project hub (create once, update as needed)
│       └── sessions/
│           └── YYYY-MM-DD.md  # daily session
├── 02-adr/
│   └── ADR-{NNNN}-{slug}.md   # NNNN = 4-digit number, read+incremented via _codex-config.md
├── 03-skills/
│   ├── domains/
│   │   └── {technology}.md    # e.g. rust.md, nestjs.md, swiftui.md
│   └── MOC.md                 # map of content — update after each new skill
└── 04-debug/
    └── {YYYY-MM-DD}-{slug}.md
```

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
type: session | adr | debug | knowledge | project-index
project: { canonical-slug }   # omit for knowledge notes
tags: [ tag1, tag2 ]
links: # explicit backlinks (supplement to [[wikilinks]])
  - "[[related-note]]"
---
```

---

## Templates — invoke

Invoke the appropriate template from `VAULT_ROOT/_templates/` (copied once from this skill's
`references/templates/` during setup — see quickstart):

| Type          | Template                      | When                                  |
|---------------|-------------------------------|---------------------------------------|
| Session       | `_templates/session.md`       | After each work session               |
| ADR           | `_templates/adr.md`           | Architectural decision with rationale |
| Debug         | `_templates/debug.md`         | Bug required >15min of debugging      |
| Knowledge     | `_templates/knowledge.md`     | New pattern / technology              |
| Project index | `_templates/project-index.md` | New project                           |

---

## Note creation algorithm

1. Read `VAULT_ROOT/_codex-config.md`. Stop and point to `references/quickstart.md` if it's missing.
2. Determine the note type
3. Resolve the project slug/path/tags from the `projects:` map in `_codex-config.md` (or add a
   new entry first, per the resolution rules above)
4. Determine the target path (see: Vault paths)
5. Copy the appropriate template from `VAULT_ROOT/_templates/`
6. Fill in frontmatter (date, type, project, tags)
7. Fill in template sections — be specific, not generic
8. Add `[[wikilinks]]` to:
   - project index of the project
   - related ADRs
   - related technologies in `03-skills/domains/`
   - previous session for this project (if one exists)
9. If this is an ADR, increment `LAST_ADR` in `_codex-config.md` in the same pass
10. Update `MOC.md` if this is a new knowledge domain
11. Update the project's `_index.md` (add link to the new note)
12. Save the file at the correct path in the vault

---

## Note quality — principles

- **Specificity over generality**: instead of "fixed MQTT bug" → "Redis SET NX race condition with >1 NestJS instance —
  fix: prefix key with `{instanceId}:`"
- **Decisions with context**: ADR includes `## Why NOT {alternative}` — this is the most valuable part
- **Links as navigation**: the Obsidian graph is valuable — the more meaningful links, the better the graph view
- **Update, don't duplicate**: if a project note already exists, update `_index.md`, don't create a new one

---

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
