# Note Identity — Avoiding Duplicate Writes

A retried delegation, a resumed session, or a hybrid Claude session re-running the same logical
task must update the existing note, not create a second one. This requires the target path to be
**deterministic** — computed the same way every time for the same logical note — so "does it
already exist" is a reliable check, not a guess.

## Identity key per type

| Type | Deterministic path | Identity key |
|---|---|---|
| session | `01-projects/{slug}/sessions/{YYYY-MM-DD}.md` | project + calendar date (one file per project per day — always overwrite/update in place, per existing convention) |
| adr | `02-adr/ADR-{NNNN}-{kebab-slug}.md` | the ADR number itself, once assigned — never re-assign a new number to update an existing decision; add a new ADR that supersedes it instead |
| debug | `04-debug/{YYYY-MM-DD}-{kebab-slug}.md` | project + date + slug of the specific bug |
| knowledge | `03-skills/domains/{technology}.md` | technology name (one file per technology — update in place) |
| project-index | `01-projects/{slug}/_index.md` | project slug (exactly one per project) |
| concept / pattern / playbook / comparison | `03-skills/{concepts,patterns,playbooks,comparisons}/{atomic-slug}.md` | the atomic slug itself — pick a specific, stable slug up front (e.g. `nestjs-config-runtime-env-precedence`), don't rename it casually later |
| experiment | `06-experiments/{atomic-slug}.md` | atomic slug |
| system | `05-systems/{atomic-slug}.md` | atomic slug |

## The check

Before creating any file:

1. Compute the deterministic path from the table above.
2. Check whether a file already exists at that exact path.
3. If it exists: open it, and update the relevant section (append to "What was done" for a
   session note, add a new hypothesis/update the root cause for a debug trace, refine a concept
   note's content, etc.) rather than overwriting the whole file or creating a sibling file with a
   slightly different name.
4. If it does not exist: create it fresh from the template.

## Worked example — resumed delegation producing the same debug note twice

A Codex `/debug` task times out mid-run. Claude resumes it with `--resume`. The resumed run
finishes and reports the same root cause the first (aborted) attempt had already partially
written up.

- Wrong: create `04-debug/2026-07-18-mqtt-race.md` again with a `-2` suffix, or a differently
  worded slug, because "it's technically a new write."
- Right: compute the same path (`04-debug/2026-07-18-mqtt-race.md`), find it already exists from
  the first attempt, and update its "Root cause" / "Fix" sections with what the resumed run
  confirmed, instead of duplicating the file.

## Worked example — ADR that turns out to need revision

Do not "fix" `ADR-0012` in place to record a changed decision after it was already accepted and
acted on — that erases the historical record of what was actually decided at the time. Instead:
create a new ADR that sets `supersedes: ["ADR-0012-original-slug"]` in its frontmatter, and update
`ADR-0012`'s own `status` to `superseded by [[ADR-00XX-new-slug]]`. The identity rule protects
against *accidental* duplication of the same logical note — it does not mean decisions are
unrevisable.
