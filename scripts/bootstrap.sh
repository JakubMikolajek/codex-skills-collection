#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat << 'USAGE'
Bootstrap Codex workflow files into another project.

Usage:
  ./scripts/bootstrap.sh <target-project-path> [--force] [--dry-run]

Options:
  --force    Overwrite existing AGENTS.md and replace existing skill folders.
  --dry-run  Print planned actions without modifying files.
  -h, --help Show this help message.
USAGE
}

FORCE=0
DRY_RUN=0
TARGET_PATH=""

while (($# > 0)); do
  case "$1" in
    --force)
      FORCE=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -* )
      echo "[ERROR] Unknown option: $1" >&2
      usage
      exit 1
      ;;
    * )
      if [[ -n "$TARGET_PATH" ]]; then
        echo "[ERROR] Multiple target paths provided." >&2
        usage
        exit 1
      fi
      TARGET_PATH="$1"
      shift
      ;;
  esac
done

if [[ -z "$TARGET_PATH" ]]; then
  echo "[ERROR] Missing target-project-path." >&2
  usage
  exit 1
fi

if [[ ! -d "$TARGET_PATH" ]]; then
  echo "[ERROR] Target path does not exist or is not a directory: $TARGET_PATH" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_AGENTS="$SOURCE_ROOT/AGENTS.md"
SOURCE_SKILLS_DIR="$SOURCE_ROOT/skills"
TARGET_DIR="$(cd "$TARGET_PATH" && pwd)"
TARGET_AGENTS="$TARGET_DIR/AGENTS.md"
TARGET_SKILLS_DIR="$TARGET_DIR/skills"

if [[ ! -f "$SOURCE_AGENTS" ]]; then
  echo "[ERROR] Source AGENTS.md not found: $SOURCE_AGENTS" >&2
  exit 1
fi

if [[ ! -d "$SOURCE_SKILLS_DIR" ]]; then
  echo "[ERROR] Source skills directory not found: $SOURCE_SKILLS_DIR" >&2
  exit 1
fi

run_cmd() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] $*"
  else
    "$@"
  fi
}

copied=0
replaced=0
skipped=0

# AGENTS.md
if [[ -e "$TARGET_AGENTS" && "$FORCE" -ne 1 ]]; then
  echo "[SKIP] $TARGET_AGENTS exists (use --force to overwrite)."
  skipped=$((skipped + 1))
else
  if [[ -e "$TARGET_AGENTS" ]]; then
    run_cmd rm -f "$TARGET_AGENTS"
    replaced=$((replaced + 1))
    echo "[REPLACE] $TARGET_AGENTS"
  else
    copied=$((copied + 1))
    echo "[COPY] $TARGET_AGENTS"
  fi
  run_cmd cp "$SOURCE_AGENTS" "$TARGET_AGENTS"
fi

# skills/
if [[ ! -d "$TARGET_SKILLS_DIR" ]]; then
  run_cmd mkdir -p "$TARGET_SKILLS_DIR"
fi

for src_skill in "$SOURCE_SKILLS_DIR"/*; do
  if [[ ! -d "$src_skill" ]]; then
    continue
  fi

  skill_name="$(basename "$src_skill")"
  dest_skill="$TARGET_SKILLS_DIR/$skill_name"

  if [[ -e "$dest_skill" && "$FORCE" -ne 1 ]]; then
    echo "[SKIP] $dest_skill exists (use --force to replace)."
    skipped=$((skipped + 1))
    continue
  fi

  if [[ -e "$dest_skill" ]]; then
    run_cmd rm -rf "$dest_skill"
    replaced=$((replaced + 1))
    echo "[REPLACE] $dest_skill"
  else
    copied=$((copied + 1))
    echo "[COPY] $dest_skill"
  fi

  run_cmd cp -R "$src_skill" "$dest_skill"
done

echo
echo "Bootstrap summary:"
echo "- copied: $copied"
echo "- replaced: $replaced"
echo "- skipped: $skipped"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "- mode: dry-run"
fi
