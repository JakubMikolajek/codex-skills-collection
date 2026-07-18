#!/bin/bash
# Workflow Facts
# Prints current, live workflow facts derived from disk: skill count and
# per-role model/effort policy. This is the single deterministic source for
# both numbers — no downstream document (Claude's contract included) should
# hardcode either one; it should point here instead.
#
# Auto-detects AGENTS.md location, same contract as validate-routing-tree.sh:
#   1. .codex/AGENTS.md -> resolve from .codex/
#   2. AGENTS.md at repo root -> resolve from repo root
#
# Run from repository root: ./scripts/workflow-facts.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ -f "$REPO_ROOT/.codex/AGENTS.md" ]; then
  AGENTS_DIR="$REPO_ROOT/.codex"
elif [ -f "$REPO_ROOT/AGENTS.md" ]; then
  AGENTS_DIR="$REPO_ROOT"
else
  echo "[ERROR] AGENTS.md not found at repo root or .codex/" >&2
  exit 1
fi

SKILLS_DIR="$AGENTS_DIR/skills"
ROUTING_DIR="$SKILLS_DIR/routing"

AGENT_TOML_DIR="$AGENTS_DIR/agents"
if [ ! -d "$AGENT_TOML_DIR" ]; then
  AGENT_TOML_DIR="$REPO_ROOT/templates/codex/agents"
fi

echo "=== Workflow Facts (derived from: $AGENTS_DIR) ==="
echo

skill_count=$(find "$SKILLS_DIR" -name "SKILL.md" -not -path "*/routing/*" | wc -l | tr -d ' ')
referenced_count=$(grep -rohE 'skills/[a-z0-9-]+/SKILL\.md' "$ROUTING_DIR"/ | sort -u | wc -l | tr -d ' ')
echo "Skill count: $skill_count on disk, $referenced_count referenced in routing"
echo "(Do not hardcode this number anywhere else - re-run this script instead.)"
echo

echo "Model/effort per agent role (from $AGENT_TOML_DIR):"
if [ -d "$AGENT_TOML_DIR" ]; then
  for toml in "$AGENT_TOML_DIR"/*.toml; do
    [ -f "$toml" ] || continue
    role=$(basename "$toml" .toml)
    model=$(grep -m1 '^model *=' "$toml" | sed -E 's/^model *= *"([^"]*)".*/\1/')
    effort=$(grep -m1 '^model_reasoning_effort *=' "$toml" | sed -E 's/^model_reasoning_effort *= *"([^"]*)".*/\1/')
    printf "  %-18s model=%-16s effort=%s\n" "$role" "${model:-?}" "${effort:-?}"
  done
else
  echo "  [WARN] no agent TOML directory found at $AGENT_TOML_DIR"
fi
echo

echo "Other canonical references (read these files directly - values are not duplicated here):"
echo "  ADR numbering:                    skills/obsidian-note/SKILL.md (LAST_ADR in _codex-config.md)"
echo "  Debug note threshold:             skills/debug-trace/SKILL.md"
echo "  Obsidian note language/templates: skills/obsidian-note/references/templates/"
