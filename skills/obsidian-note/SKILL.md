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

## Vault paths

VAULT_ROOT/
├── 00-inbox/ # drafts, uncategorized — clean weekly
├── 01-projects/
│ └── {project-slug}/
│ ├── _index.md # project hub (create once, update as needed)
│ └── sessions/
│ └── YYYY-MM-DD.md # daily session
├── 02-adr/
│ └── ADR-{NNNN}-{slug}.md # NNNN = 4-digit number, auto-increment
├── 03-skills/
│ ├── domains/
│ │ └── {technology}.md # e.g. rust.md, nestjs.md, swiftui.md
│ └── MOC.md # map of content — update after each new skill
└── 04-debug/
└── {YYYY-MM-DD}-{slug}.md

**VAULT_ROOT** = ~/Desktop/Obsidian/Codex/

---

## Wikilink rules [[...]]

### Always link:

- Every note links to the **project index**: `[[01-projects/{slug}/_index]]`
- ADR links to related skills: `[[03-skills/domains/rust]]`
- Session note links to ADRs from that session: `[[ADR-0012-grpc-transport]]`
- Debug trace links to project + technology: `[[FSS-IoT/_index]]` `[[03-skills/domains/redis]]`
- Knowledge note in domains/ links to projects where the technology is used

### Canonical project names (use these slugs exactly):

- `CodePath` → `01-projects/codepath/_index`
- `FSS-IoT` → `01-projects/fss-iot/_index`
- `NuvLock` → `01-projects/nuvlock/_index`
- `codex-skills` → `01-projects/codex-skills/_index`
- `thesis` → `01-projects/thesis/_index`

### Tags (#tag) — use consistently:

Technologies:  #rust #nestjs #swift #react #python #mqtt #ble #grpc #redis
Note type:     #adr #session #debug #knowledge #project-index
Domain:        #backend #ios #tvos #frontend #iot #ai #infra
ADR status:    #adr/accepted #adr/proposed #adr/superseded

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

Invoke the appropriate template from `_templates/`:

| Type          | Template                      | When                                  |
|---------------|-------------------------------|---------------------------------------|
| Session       | `_templates/session.md`       | After each work session               |
| ADR           | `_templates/adr.md`           | Architectural decision with rationale |
| Debug         | `_templates/debug.md`         | Bug required >15min of debugging      |
| Knowledge     | `_templates/knowledge.md`     | New pattern / technology              |
| Project index | `_templates/project-index.md` | New project                           |

---

## Note creation algorithm

Determine the note type
Determine the target path (see: Vault paths)
Copy the appropriate template
Fill in frontmatter (date, type, project, tags)
Fill in template sections — be specific, not generic
Add [[wikilinks]] to:

project index of the project
related ADRs
related technologies in 03-skills/domains/
previous session for this project (if one exists)

Update MOC.md if this is a new knowledge domain
Update the project's _index.md (add link to the new note)
Save the file at the correct path in the vault


---

## Note quality — principles

- **Specificity over generality**: instead of "fixed MQTT bug" → "Redis SET NX race condition with >1 NestJS instance —
  fix: prefix key with `{instanceId}:`"
- **Decisions with context**: ADR includes `## Why NOT {alternative}` — this is the most valuable part
- **Links as navigation**: the Obsidian graph is valuable — the more meaningful links, the better the graph view
- **Update, don't duplicate**: if a project note already exists, update `_index.md`, don't create a new one

---

## Minimal example — session

File: `01-projects/codepath/sessions/2025-01-15.md`

```markdown
---
date: 2025-01-15
type: session
project: CodePath
tags: [session, rust, lsp]
links:
  - "[[01-projects/codepath/_index]]"
  - "[[03-skills/domains/rust]]"
---

# CodePath — session 2025-01-15

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
