#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat << 'USAGE'
Bootstrap Codex workflow, skills, and multi-agent templates into another project.

Usage:
  ./scripts/bootstrap.sh <target-project-path> [--force] [--dry-run]

Options:
  --force    Overwrite existing .codex files and replace existing skill or agent folders.
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
SOURCE_AGENTS_FILE="$SOURCE_ROOT/AGENTS.md"
SOURCE_SKILLS_DIR="$SOURCE_ROOT/skills"
SOURCE_SCRIPTS_DIR="$SOURCE_ROOT/scripts"
SOURCE_CODEX_TEMPLATE_DIR="$SOURCE_ROOT/templates/codex"
SOURCE_CODEX_CONFIG_FILE="$SOURCE_CODEX_TEMPLATE_DIR/config.toml"
SOURCE_AGENT_TEMPLATES_DIR="$SOURCE_CODEX_TEMPLATE_DIR/agents"
TARGET_DIR="$(cd "$TARGET_PATH" && pwd)"
TARGET_CODEX_DIR="$TARGET_DIR/.codex"
TARGET_AGENTS_FILE="$TARGET_CODEX_DIR/AGENTS.md"
TARGET_SKILLS_DIR="$TARGET_CODEX_DIR/skills"
TARGET_SCRIPTS_DIR="$TARGET_CODEX_DIR/scripts"
TARGET_CODEX_CONFIG_FILE="$TARGET_CODEX_DIR/config.toml"
TARGET_AGENT_CONFIGS_DIR="$TARGET_CODEX_DIR/agents"

if [[ ! -f "$SOURCE_AGENTS_FILE" ]]; then
  echo "[ERROR] Source AGENTS.md not found: $SOURCE_AGENTS_FILE" >&2
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
LAST_ACTION=""

ensure_dir() {
  local dir_path="$1"

  if [[ ! -d "$dir_path" ]]; then
    run_cmd mkdir -p "$dir_path"
  fi
}

copy_file_with_policy() {
  local src_path="$1"
  local dest_path="$2"

  LAST_ACTION="none"

  if [[ ! -f "$src_path" ]]; then
    return 0
  fi

  ensure_dir "$(dirname "$dest_path")"

  if [[ -e "$dest_path" && "$FORCE" -ne 1 ]]; then
    echo "[SKIP] $dest_path exists (use --force to overwrite)."
    skipped=$((skipped + 1))
    LAST_ACTION="skipped"
    return 0
  fi

  if [[ -e "$dest_path" ]]; then
    run_cmd rm -f "$dest_path"
    replaced=$((replaced + 1))
    echo "[REPLACE] $dest_path"
    LAST_ACTION="replaced"
  else
    copied=$((copied + 1))
    echo "[COPY] $dest_path"
    LAST_ACTION="copied"
  fi

  run_cmd cp "$src_path" "$dest_path"
}

copy_dir_with_policy() {
  local src_path="$1"
  local dest_path="$2"

  LAST_ACTION="none"

  if [[ ! -d "$src_path" ]]; then
    return 0
  fi

  ensure_dir "$(dirname "$dest_path")"

  if [[ -e "$dest_path" && "$FORCE" -ne 1 ]]; then
    echo "[SKIP] $dest_path exists (use --force to replace)."
    skipped=$((skipped + 1))
    LAST_ACTION="skipped"
    return 0
  fi

  if [[ -e "$dest_path" ]]; then
    run_cmd rm -rf "$dest_path"
    replaced=$((replaced + 1))
    echo "[REPLACE] $dest_path"
    LAST_ACTION="replaced"
  else
    copied=$((copied + 1))
    echo "[COPY] $dest_path"
    LAST_ACTION="copied"
  fi

  run_cmd cp -R "$src_path" "$dest_path"
}

ensure_dir "$TARGET_CODEX_DIR"
copy_file_with_policy "$SOURCE_AGENTS_FILE" "$TARGET_AGENTS_FILE"
copy_file_with_policy "$SOURCE_CODEX_CONFIG_FILE" "$TARGET_CODEX_CONFIG_FILE"

ensure_dir "$TARGET_SKILLS_DIR"

for src_skill in "$SOURCE_SKILLS_DIR"/*; do
  if [[ ! -d "$src_skill" ]]; then
    continue
  fi

  skill_name="$(basename "$src_skill")"
  dest_skill="$TARGET_SKILLS_DIR/$skill_name"
  copy_dir_with_policy "$src_skill" "$dest_skill"
done

if [[ -d "$SOURCE_AGENT_TEMPLATES_DIR" ]]; then
  ensure_dir "$TARGET_AGENT_CONFIGS_DIR"

  for src_agent in "$SOURCE_AGENT_TEMPLATES_DIR"/*; do
    if [[ -d "$src_agent" ]]; then
      dest_agent_dir="$TARGET_AGENT_CONFIGS_DIR/$(basename "$src_agent")"
      copy_dir_with_policy "$src_agent" "$dest_agent_dir"
      continue
    fi

    if [[ ! -f "$src_agent" ]]; then
      continue
    fi

    dest_agent_file="$TARGET_AGENT_CONFIGS_DIR/$(basename "$src_agent")"
    copy_file_with_policy "$src_agent" "$dest_agent_file"
  done
fi

if [[ -d "$SOURCE_SCRIPTS_DIR" ]]; then
  ensure_dir "$TARGET_SCRIPTS_DIR"

  for src_script in "$SOURCE_SCRIPTS_DIR"/*; do
    [[ "$(basename "$src_script")" == "bootstrap.sh" ]] && continue
    [[ ! -f "$src_script" ]] && continue

    script_name="$(basename "$src_script")"
    dest_script="$TARGET_SCRIPTS_DIR/$script_name"

    copy_file_with_policy "$src_script" "$dest_script"

    if [[ "$LAST_ACTION" == "copied" || "$LAST_ACTION" == "replaced" ]]; then
      run_cmd chmod +x "$dest_script"
    fi
  done
fi

echo
echo "Bootstrap summary:"
echo "- copied: $copied"
echo "- replaced: $replaced"
echo "- skipped: $skipped"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "- mode: dry-run"
fi
