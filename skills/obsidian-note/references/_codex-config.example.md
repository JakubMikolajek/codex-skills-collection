# _codex-config

> Configuration note for the `obsidian-note` skill — this is what the agent reads, not
> `SKILL.md`. Edit it directly in Obsidian whenever you start a new project or want to change
> linking behavior. You never need to touch the repo to do this.

## Vault root

<!-- Informational only — the actual pointer lives in skills/obsidian-note/SKILL.md.
     Keep this in sync so a human reading the vault knows where it's "supposed" to live. -->
```
VAULT_ROOT = ~/Desktop/Obsidian/Codex
```

## Canonical project slugs

Add one entry per project you want notes filed under. `slug` must match the folder name under
`01-projects/`. Delete the two example entries once you've added your own.

```yaml
projects:
  example-api:
    slug: example-api
    display: "Example API"
    path: "01-projects/example-api"
    tags: [nestjs, postgres, rest]
  example-mobile-app:
    slug: example-mobile-app
    display: "Example Mobile App"
    path: "01-projects/example-mobile-app"
    tags: [swift, ios]
```

## ADR counter

```
LAST_ADR = 0000
```
<!-- The agent auto-increments this every time it creates a new ADR. Don't edit it by hand
     unless you're fixing a mismatch (e.g. after manually deleting an ADR file). -->

## Linking rules

```yaml
# Always link the project index when creating a project note
always_link_project_index: true

# Always link technology domains from 03-skills when they appear in a note
auto_link_domains: true

# Update MOC.md after every new knowledge note
update_moc: true

# Update the project's _index.md after every session
update_project_index: true
```

## Filename conventions

```
ADR:      ADR-{NNNN}-{kebab-slug}.md          # ADR-0012-grpc-transport.md
Session:  {YYYY-MM-DD}.md                      # 2026-01-15.md (inside the project folder)
Debug:    {YYYY-MM-DD}-{kebab-slug}.md         # 2026-01-15-mqtt-dedup-race.md
Knowledge: {technology}.md                     # redis.md, tonic.md
Project:  _index.md (inside the project folder)
```
