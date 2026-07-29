# Run Log Schema

Canonical schema for the machine-readable run log an orchestrator may
persist per Codex delegation, so `session-learning` (and any summary
tooling) can consume real evidence instead of reconstructing it from memory.
This file documents the *shape and known gaps* of that evidence — it does
not itself write the log. See `../SKILL.md`'s "Run Evidence" principle for
how `session-learning` uses it.

## Where it lives

`.ai/runs/YYYY-MM.jsonl` at the project root, one JSON object per line,
append-only, git-ignored (it is local session evidence, not source).

## Why two event kinds instead of one

A single delegation produces two events, joined by `agent_id`, because no
single point in the lifecycle has all the facts:

- The orchestrator (e.g. Claude, right after launching a Codex delegation)
  knows the task, route, preloads, model, effort, and baseline commit — but
  not yet the outcome.
- The completion signal (e.g. Claude Code's `SubagentStop` hook) knows the
  agent finished and what it said — but not the original task/route/model
  context, and not timing.

Do not force these into one event at a single point; join them at read time
by `agent_id` instead.

## `start` event

Written as soon as the orchestrator has an `agent_id` for the delegation,
before the result is known.

```json
{
  "kind": "start",
  "agent_id": "af4d2434804eac0b7",
  "ts": "2026-07-18T08:45:58.643337+00:00",
  "task": "one-line task description",
  "route": ["BACKEND", "nestjs"],
  "preloads": ["project-context", "technical-context-discovery"],
  "model": "gpt-5.6-sol",
  "effort": "high",
  "baseline_sha": "25a98ace9dabb30a02796758bbd65ea1c56d019a"
}
```

## `completion` event

Written automatically when the delegation finishes, without relying on the
orchestrator remembering to do it.

```json
{
  "kind": "completion",
  "agent_id": "af4d2434804eac0b7",
  "agent_type": "codex:codex-rescue",
  "ts": "2026-07-18T08:46:40.112000+00:00",
  "stop_reason": "end_turn",
  "result_excerpt": "first ~2000 chars of the final result text"
}
```

## Known gaps — do not claim these are populated

- **No `duration_s` field.** Derive it, if needed, from the difference
  between the `completion` event's `ts` and the matching `start` event's
  `ts` — it is not written directly because the completion signal in at
  least one real implementation (Claude Code's `SubagentStop` hook) does not
  carry timing itself.
- **No `retries`, `human_corrections`, `ownership_conflict`, or `tests`
  fields populated by default.** These require richer per-task evidence
  (e.g. parsing `result_excerpt` for test output, or explicit orchestrator
  bookkeeping across `--resume` calls) that is not guaranteed to exist. A
  consumer must treat their absence as "not computed", not "zero" — silently
  defaulting them to a clean value would misrepresent the run.
- **No original task/route/model in the `completion` event.** Always join
  by `agent_id` against the `start` event; never assume a `completion` event
  is self-sufficient.
- **`stop_reason` may be `null` in practice**, not always a value like
  `"end_turn"` — observed directly in a live test of one implementation
  (Claude Code's `SubagentStop` hook) for a trivial single-turn completion.
  Treat it as best-effort metadata, not a guaranteed enum.
- **A `completion` event with no matching `start` event is still evidence.**
  It means the delegation ran and finished, even if the orchestrator failed
  to log its start (or wasn't the one that launched it). Report it as an
  unmatched/partial record rather than discarding it.

## Consuming this from `session-learning`

- Treat a matched `start`+`completion` pair as one delegation's ground
  truth for Step 1 ("list all skills loaded") and Step 2 ("assess routing
  quality") — the `route` field tells you what was actually targeted,
  removing guesswork.
- An unusually high rate of `stop_reason` values other than a clean
  completion (e.g. repeated aborts) across recent entries is itself a
  `WARN`- or `MISSING`-worthy signal, independent of any single task's
  content quality.
- This schema does not replace `references/failure-patterns.md` or
  `routing/FAILURES.md` — those remain the append-only judgment record.
  This file only grounds *what ran*.
