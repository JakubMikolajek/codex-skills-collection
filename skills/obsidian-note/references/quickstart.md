# Obsidian Second-Brain Quick Start

This is the only document you need to get the `obsidian-note` skill working. Follow it top to
bottom, in order. Every step is copy-paste — you don't need to understand Codex internals, and
you don't need to write any prompts to set this up.

**What you're building**: a folder on your computer, opened as an Obsidian vault, where Codex
automatically writes a note every time you finish a session, make an architectural decision,
fix a hard bug, or learn something new. Over time these notes link to each other and become a
searchable, browsable history of every project you touch — that's the "second brain."

You do not need to keep Obsidian open for this to work. Obsidian is just a nice way to *view*
the notes (backlinks, graph view, search). The notes themselves are plain `.md` files that
Codex reads and writes directly on disk.

---

## Step 0 — Install Obsidian (2 minutes)

1. Download it from obsidian.md and install it.
2. Don't create a vault from inside the app yet — you'll point it at a folder you create in
   Step 1.

If you never open Obsidian at all, everything below still works — the files are just regular
Markdown. Obsidian only adds the graph view and clickable `[[links]]`.

---

## Step 1 — Create the vault folder (1 minute)

Pick anywhere on your machine. Example:

```bash
mkdir -p ~/Desktop/Obsidian/Codex
```

Now create the folder skeleton inside it:

```bash
cd ~/Desktop/Obsidian/Codex
mkdir -p 00-inbox 01-projects 02-adr "03-skills/domains" 04-debug _templates
```

You should now have:

```
~/Desktop/Obsidian/Codex/
├── 00-inbox/
├── 01-projects/
├── 02-adr/
├── 03-skills/
│   └── domains/
├── 04-debug/
└── _templates/
```

---

## Step 2 — Copy the note templates (1 minute)

This repo already ships the 5 templates the skill invokes. Copy them into your new vault:

```bash
cp skills/obsidian-note/references/templates/*.md ~/Desktop/Obsidian/Codex/_templates/
```

(Run that from the root of this repo. Adjust `~/Desktop/Obsidian/Codex` if you used a different path in
Step 1.)

---

## Step 3 — Copy and fill in your config note (2 minutes)

This is the file you edit whenever you start a new project — not any file in this repo.

```bash
cp skills/obsidian-note/references/_codex-config.example.md ~/Desktop/Obsidian/Codex/_codex-config.md
```

Open `~/Desktop/Obsidian/Codex/_codex-config.md` and:

1. Delete the two example projects (`example-api`, `example-mobile-app`).
2. Add one entry per real project you want notes for. Minimum you need per project:

```yaml
projects:
  my-project:
    slug: my-project
    display: "My Project"
    path: "01-projects/my-project"
    tags: [rust, backend]
```

`slug` is the folder name Codex will create under `01-projects/`. Keep it short, lowercase,
hyphenated — that's it, no other rules.

Leave `LAST_ADR = 0000` as-is — Codex updates that number automatically.

---

## Step 4 — Point the skill at your vault (30 seconds)

This is the **only** edit you ever make inside this repo for Obsidian setup.

Open `skills/obsidian-note/SKILL.md`, find this line near the top:

```
VAULT_ROOT = ~/Desktop/Obsidian/Codex/    <!-- EDIT THIS to your vault's absolute path -->
```

Change the path if yours is different. Save. Done — this is a one-time, one-line edit per
machine. You never touch `SKILL.md` again after this.

---

## Step 5 — Try it

Ask Codex to do something small and finish the session normally, e.g.:

```
/handoff
```

or just:

```
Create an Obsidian session note for what we just did.
```

Check that a file appeared at:

```
~/Desktop/Obsidian/Codex/01-projects/my-project/sessions/2026-01-15.md
```

with frontmatter, a filled-in "What was done" section, and a link back to
`01-projects/my-project/_index.md`. If `_index.md` didn't exist yet, Codex should have created
it from the `project-index` template.

Open the vault in Obsidian (`Open folder as vault` → pick `~/Desktop/Obsidian/Codex`) to see it
rendered with clickable links, or just read the raw `.md` file in any editor — both work.

---

## When notes get created automatically

You don't need to remember to ask for these — they happen as a side effect of normal work:

| Trigger | Note type | Folder |
|---|---|---|
| End of a work session / `/handoff` | session | `01-projects/{slug}/sessions/` |
| An architectural decision was made | adr | `02-adr/` |
| A bug took >15 min to fix | debug | `04-debug/` |
| You learned a new pattern/technology | knowledge | `03-skills/domains/` |
| A brand-new project starts | project-index | `01-projects/{slug}/_index.md` |

You can also ask for one explicitly any time: `/obsidian session`, `/obsidian adr`,
`/obsidian debug`, `/obsidian knowledge`.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Codex says it can't find `_codex-config.md` | `VAULT_ROOT` in `SKILL.md` doesn't match the real folder, or you skipped Step 3 | Re-check the exact path in Step 4 — no typos, and use your real home directory, not `~` literally inside the file if your editor doesn't expand it |
| Note was created in the wrong project folder | The project isn't in `_codex-config.md`, or the slug doesn't match | Add/fix the entry under `projects:` in `_codex-config.md` — slug must equal the folder name under `01-projects/` |
| ADR numbers look wrong or reused | `LAST_ADR` in `_codex-config.md` got out of sync (e.g. you deleted an ADR file by hand) | Manually set `LAST_ADR` to the highest number currently in `02-adr/` |
| Links `[[like-this]]` show as plain text, not clickable | You're viewing the raw file instead of opening the folder as an Obsidian vault | Open Obsidian → `Open folder as vault` → select your `VAULT_ROOT` |
| Nothing gets created at all | You never did Step 4 (SKILL.md still points at the placeholder path) | Go back to Step 4 |

---

## FAQ

**Do I need to write a special prompt to make this happen?**
No. Once setup is done, note creation is automatic at the end of sessions, debugging, and
architecture decisions. You only need a special prompt (`/obsidian <type>`) if you want one
created on demand, outside those triggers.

**Do I need Obsidian open while I work?**
No. Files are written directly to disk whether or not the app is running.

**What if I already have an existing Obsidian vault I use for other things?**
Point `VAULT_ROOT` at a subfolder of it (e.g. `~/Obsidian/MyVault/Codex/`) rather than the vault
root, so the `00-inbox` / `01-projects` / etc. skeleton doesn't collide with your existing notes.

**What if two developers on the team both use this?**
Each person has their own vault on their own machine (`VAULT_ROOT` is per-machine, set in their
own local copy of `SKILL.md`, and personal notes are not committed to this repo). Nothing here
is shared or synced between developers automatically.
