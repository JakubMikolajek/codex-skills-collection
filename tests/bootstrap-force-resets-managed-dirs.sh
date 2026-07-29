#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BOOTSTRAP_SCRIPT="$SOURCE_ROOT/scripts/bootstrap.sh"

TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/codex-bootstrap-test.XXXXXX")"
TARGET_DIR="$TEST_ROOT/target"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

mkdir -p \
  "$TARGET_DIR/.codex/skills/gemini-delegate" \
  "$TARGET_DIR/.codex/agents/stale-agent" \
  "$TARGET_DIR/.codex/scripts"

cat > "$TARGET_DIR/.codex/skills/gemini-delegate/SKILL.md" <<'SKILL'
---
name: gemini-delegate
description: Stale skill left behind by an older bootstrap sync.
---

# Stale Skill
SKILL

touch "$TARGET_DIR/.codex/agents/stale-agent/config.toml"
touch "$TARGET_DIR/.codex/scripts/stale-script.sh"

"$BOOTSTRAP_SCRIPT" "$TARGET_DIR" --force >/dev/null

for stale_path in \
  "$TARGET_DIR/.codex/skills/gemini-delegate" \
  "$TARGET_DIR/.codex/agents/stale-agent" \
  "$TARGET_DIR/.codex/scripts/stale-script.sh"; do
  if [[ -e "$stale_path" ]]; then
    echo "[FAIL] stale managed path survived force bootstrap: $stale_path" >&2
    exit 1
  fi
done

"$TARGET_DIR/.codex/scripts/validate-routing-tree.sh" >/dev/null

echo "[OK] force bootstrap resets managed .codex directories"
