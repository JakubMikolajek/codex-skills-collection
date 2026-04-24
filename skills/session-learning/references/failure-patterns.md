# Failure Patterns — session-learning

This file is maintained by the `session-learning` skill.
Entries are appended automatically after /implement and /review sessions.
Human review is required before acting on any CRITICAL or WARN entry.

<!-- entries below, newest last -->

## 2026-04-24 — WARN: Bootstrap drift hid current context-preload rules

**Task context**: Review local skills and update multi-agent TOML configs for GPT-5.5 across projects using Codex.
**Observed**: Downstream `.codex` copies had drifted from the source workflow. The Android handoff explicitly noted that the Session Context Block from `project-context` was unavailable, and the Android `.codex/AGENTS.md` was still on an older direct-skill model without the current routing/preload contract.
**Impact**: Future Android sessions could skip `project-context`, miss current routing, and produce weaker handoffs even though the source repo already had the correct rule.
**Suggested fix**: Re-bootstrap downstream `.codex` directories after workflow/skill/template changes, and keep routing validation available in every bootstrapped project.
**Status**: fixed in working tree

## 2026-04-24 — OK: Routing validator catches real reachability and quality gates

**Task context**: Review local skills and update multi-agent TOML configs for GPT-5.5 across projects using Codex.
**Observed**: `scripts/validate-routing-tree.sh` confirmed all 63 skills are reachable and have required frontmatter after the update.
**Impact**: none
**Suggested fix**: Keep validator as the release gate for skill routing changes.
**Status**: fixed in working tree

## 2026-04-24 — WARN: Historical downstream path-root drift

**Task context**: Consolidate failure records from older `.codex` copies before GPT-5.5 re-bootstrap.
**Observed**: `nuvlock-api` recorded that earlier `session-learning` guidance used `skills/...` examples while the bootstrapped repository stored skills in `.codex/skills/...`, requiring manual path translation.
**Impact**: Learning updates could be appended to the wrong path or skipped when following the skill text literally.
**Suggested fix**: Keep repository-aware `[SKILLS_ROOT]` guidance and path guardrails in `session-learning/SKILL.md`.
**Status**: fixed in working tree

## 2026-04-24 — MISSING: Historical tooling/environment signal bucket

**Task context**: Consolidate failure records from older `.codex` copies before GPT-5.5 re-bootstrap.
**Observed**: `nuvlock-api` recorded an `EMFILE: too many open files, watch` verification failure, and the old `session-learning` template had no explicit bucket for non-skill operational signals.
**Impact**: Environment failures could be incorrectly classified as skill-quality or routing failures.
**Suggested fix**: Keep the dedicated Tooling/Environment Signals section with command, key output, and scope evidence fields.
**Status**: fixed in working tree
