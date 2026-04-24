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
| 2026-04-24 | WARN | session-learning | Downstream `.codex` bootstrap drift left Android on an older workflow without current context-preload rules. Detail: `[SKILLS_ROOT]/session-learning/references/failure-patterns.md` |
| 2026-04-24 | OK | session-learning | Routing validator confirmed all 63 skills reachable after the GPT-5.5 template update. Detail: `[SKILLS_ROOT]/session-learning/references/failure-patterns.md` |
| 2026-04-24 | WARN | session-learning | Historical downstream path-root drift (`skills/...` vs `.codex/skills/...`) is covered by `[SKILLS_ROOT]` guidance. Detail: `[SKILLS_ROOT]/session-learning/references/failure-patterns.md` |
| 2026-04-24 | MISSING | session-learning | Historical `EMFILE` tooling/environment signal bucket is covered by dedicated operational signal guidance. Detail: `[SKILLS_ROOT]/session-learning/references/failure-patterns.md` |
| 2026-04-24 | WARN | nestjs | Historical Nest repository extraction DI drift is covered by the Module DI Wiring checklist. Detail: `[SKILLS_ROOT]/nestjs/references/failure-patterns.md` |
