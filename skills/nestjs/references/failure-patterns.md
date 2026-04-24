# Failure Patterns — nestjs

This file is maintained by the `session-learning` skill.
Entries are appended automatically after /implement and /review sessions.
Human review is required before acting on any CRITICAL or WARN entry.

<!-- entries below, newest last -->

## 2026-04-24 — WARN: Historical module DI wiring drift during repository extraction

**Task context**: Consolidate failure records from older `.codex` copies before GPT-5.5 re-bootstrap.
**Observed**: `nuvlock-api` recorded that a broad repository extraction temporarily placed repository classes in module `imports` instead of `providers`, and one consuming module missed importing the module that exported `SystemsRepository`.
**Impact**: API startup failed until Nest module metadata was corrected.
**Suggested fix**: Keep the Repository Extraction DI Checklist in `nestjs/SKILL.md`: provider classes belong in owner-module `providers`, cross-module injections require importing the exporter module, and runtime/module compile checks should follow typecheck.
**Status**: fixed in working tree
