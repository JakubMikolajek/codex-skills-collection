#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SYNC_SCRIPT="$SOURCE_ROOT/scripts/sync-skills.sh"

TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/codex-sync-test.XXXXXX")"
TARGETS_FILE="$TEST_ROOT/codex-targets.txt"
PROJECT_DIR="$TEST_ROOT/nuvlock-mobile"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

mkdir -p "$PROJECT_DIR/android" "$PROJECT_DIR/ios" "$TEST_ROOT/other"

cat > "$TARGETS_FILE" <<TARGETS
$PROJECT_DIR
$PROJECT_DIR/android
$PROJECT_DIR/ios
$TEST_ROOT/other
TARGETS

output="$("$SYNC_SCRIPT" --targets "$TARGETS_FILE" --repo nuvlock-mobile --dry-run --no-validate)"

matched_count="$(printf "%s\n" "$output" | sed -n 's/^- matched: //p')"
if [[ "$matched_count" != "3" ]]; then
  echo "[FAIL] expected --repo nuvlock-mobile to match 3 targets, got $matched_count" >&2
  printf "%s\n" "$output" >&2
  exit 1
fi

if printf "%s\n" "$output" | grep -q "\[SYNC\] $TEST_ROOT/other"; then
  echo "[FAIL] unrelated target was matched" >&2
  printf "%s\n" "$output" >&2
  exit 1
fi

echo "[OK] --repo filter includes nested targets under the selected repo"
