# Global Failure Pattern Rollup

Maintained by `session-learning`. Entries link to per-skill detail files.  
Human review cadence: before each minor version bump.

## How to Read This File

- Each entry is produced automatically by the `session-learning` skill after `/implement` or `/review`
- Severity levels: `CRITICAL` | `WARN` | `ROUTING` | `MISSING` | `OK`
- Before acting on any entry, read the linked per-skill file for full context
- Before a minor release, triage all `CRITICAL` and `WARN` entries and decide: fix, defer, or close

## How to Act on Entries

| Severity | Action |
|---|---|
| `CRITICAL` | Fix the skill before next session on this codebase. Use `skill-creator` or direct edit. |
| `WARN` | Review and fix within the current sprint. |
| `ROUTING` | Fix `AGENTS.md` or the relevant routing branch file. Not the leaf skill. |
| `MISSING` | Evaluate: new skill via `/new-skill`, or add section to existing skill. |
| `OK` | No action. Record for stability confirmation. |

---

## Entries

| Date | Severity | Skill | Summary |
|---|---|---|---|
<!-- session-learning appends rows here -->
