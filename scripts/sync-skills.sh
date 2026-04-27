#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat << 'USAGE'
Sync Codex workflow files and skills into one or more downstream projects.

Usage:
  ./scripts/sync-skills.sh [--targets <file>] [--all] [--changed] [--repo <path-or-name>] [--dry-run] [--no-validate]

Options:
  --targets <file>  Target list file. Defaults to ./codex-targets.txt.
  --all             Sync every target from the target list. This is the default.
  --changed         Sync only targets whose .codex/skills-sync.json is behind the source commit.
                    If the source repo is dirty, every matched target is treated as changed.
  --repo <value>    Sync one target by absolute path, relative path, or basename from the target list.
  --dry-run         Print planned actions without modifying target projects.
  --no-validate     Skip routing validation after sync.
  -h, --help        Show this help message.

Target list format:
  One project path per line. Blank lines and lines starting with # are ignored.
USAGE
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BOOTSTRAP_SCRIPT="$SCRIPT_DIR/bootstrap.sh"
DEFAULT_TARGETS_FILE="$SOURCE_ROOT/codex-targets.txt"

TARGETS_FILE="$DEFAULT_TARGETS_FILE"
MODE="all"
REPO_FILTER=""
DRY_RUN=0
VALIDATE=1

while (($# > 0)); do
  case "$1" in
    --targets)
      if [[ $# -lt 2 ]]; then
        echo "[ERROR] --targets requires a file path." >&2
        exit 1
      fi
      TARGETS_FILE="$2"
      shift 2
      ;;
    --all)
      MODE="all"
      shift
      ;;
    --changed)
      MODE="changed"
      shift
      ;;
    --repo)
      if [[ $# -lt 2 ]]; then
        echo "[ERROR] --repo requires a path or repository basename." >&2
        exit 1
      fi
      MODE="repo"
      REPO_FILTER="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --no-validate)
      VALIDATE=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "[ERROR] Unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      echo "[ERROR] Unexpected argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ! -x "$BOOTSTRAP_SCRIPT" ]]; then
  echo "[ERROR] Bootstrap script not executable: $BOOTSTRAP_SCRIPT" >&2
  exit 1
fi

if [[ ! -f "$TARGETS_FILE" ]]; then
  echo "[ERROR] Target list not found: $TARGETS_FILE" >&2
  echo "Create it manually or run: ./scripts/discover-codex-projects.sh --write $TARGETS_FILE" >&2
  exit 1
fi

source_commit="$(git -C "$SOURCE_ROOT" rev-parse --short=12 HEAD 2>/dev/null || true)"
if [[ -z "$source_commit" ]]; then
  source_commit="unknown"
fi

source_dirty="false"
if [[ -n "$(git -C "$SOURCE_ROOT" status --porcelain --untracked-files=normal 2>/dev/null || true)" ]]; then
  source_dirty="true"
fi

source_version="$source_commit"
if [[ "$source_dirty" == "true" ]]; then
  source_version="$source_version-dirty"
fi

abs_path() {
  local path="$1"
  if [[ -d "$path" ]]; then
    (cd "$path" && pwd)
    return 0
  fi
  return 1
}

json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf "%s" "$value"
}

read_recorded_version() {
  local metadata_file="$1"
  if [[ ! -f "$metadata_file" ]]; then
    return 0
  fi
  sed -n 's/.*"sourceVersion"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$metadata_file" | head -1
}

write_metadata() {
  local target_dir="$1"
  local metadata_file="$target_dir/.codex/skills-sync.json"
  local synced_at
  synced_at="$(date -u "+%Y-%m-%dT%H:%M:%SZ")"

  mkdir -p "$(dirname "$metadata_file")"
  {
    printf "{\n"
    printf "  \"source\": \"%s\",\n" "$(json_escape "$SOURCE_ROOT")"
    printf "  \"sourceCommit\": \"%s\",\n" "$(json_escape "$source_commit")"
    printf "  \"sourceDirty\": %s,\n" "$source_dirty"
    printf "  \"sourceVersion\": \"%s\",\n" "$(json_escape "$source_version")"
    printf "  \"lastSyncedAt\": \"%s\"\n" "$synced_at"
    printf "}\n"
  } > "$metadata_file"
}

validate_target() {
  local target_dir="$1"
  local validator="$target_dir/.codex/scripts/validate-routing-tree.sh"

  if [[ ! -x "$validator" ]]; then
    echo "[WARN] Validator not executable or missing: $validator"
    return 0
  fi

  echo "[VALIDATE] $target_dir"
  "$validator"
}

load_targets() {
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" || "${line:0:1}" == "#" ]] && continue
    printf "%s\n" "$line"
  done < "$TARGETS_FILE"
}

target_matches_filter() {
  local raw_target="$1"
  local target_dir="$2"

  [[ "$raw_target" == "$REPO_FILTER" ]] && return 0
  [[ "$target_dir" == "$REPO_FILTER" ]] && return 0
  [[ "$(basename "$target_dir")" == "$REPO_FILTER" ]] && return 0

  if [[ -d "$REPO_FILTER" ]]; then
    local filter_dir
    filter_dir="$(abs_path "$REPO_FILTER")"
    [[ "$target_dir" == "$filter_dir" ]] && return 0
  fi

  return 1
}

sync_target() {
  local raw_target="$1"
  local target_dir
  local metadata_file
  local recorded_version

  if ! target_dir="$(abs_path "$raw_target")"; then
    echo "[WARN] Skipping missing target: $raw_target"
    skipped=$((skipped + 1))
    return 0
  fi

  if [[ "$target_dir" == "$SOURCE_ROOT" ]]; then
    echo "[SKIP] Source repository is not a downstream sync target: $target_dir"
    skipped=$((skipped + 1))
    return 0
  fi

  if [[ "$MODE" == "repo" ]] && ! target_matches_filter "$raw_target" "$target_dir"; then
    return 0
  fi

  metadata_file="$target_dir/.codex/skills-sync.json"
  recorded_version="$(read_recorded_version "$metadata_file")"

  if [[ "$MODE" == "changed" && "$source_dirty" == "false" && "$recorded_version" == "$source_version" ]]; then
    echo "[UP-TO-DATE] $target_dir ($source_version)"
    up_to_date=$((up_to_date + 1))
    matched=$((matched + 1))
    return 0
  fi

  matched=$((matched + 1))
  echo "[SYNC] $target_dir"
  echo "       source version: $source_version"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    "$BOOTSTRAP_SCRIPT" "$target_dir" --force --dry-run
    echo "[DRY-RUN] Would write $metadata_file"
    if [[ "$VALIDATE" -eq 1 ]]; then
      echo "[DRY-RUN] Would run routing validation in $target_dir"
    fi
  else
    "$BOOTSTRAP_SCRIPT" "$target_dir" --force
    write_metadata "$target_dir"
    if [[ "$VALIDATE" -eq 1 ]]; then
      validate_target "$target_dir"
    fi
  fi

  synced=$((synced + 1))
}

matched=0
synced=0
skipped=0
up_to_date=0

while IFS= read -r target; do
  sync_target "$target"
done < <(load_targets)

if [[ "$MODE" == "repo" && "$matched" -eq 0 ]]; then
  echo "[ERROR] No target matched --repo $REPO_FILTER in $TARGETS_FILE." >&2
  exit 1
fi

echo
echo "Sync summary:"
echo "- targets file: $TARGETS_FILE"
echo "- source version: $source_version"
echo "- matched: $matched"
echo "- synced: $synced"
echo "- up-to-date: $up_to_date"
echo "- skipped: $skipped"
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "- mode: dry-run"
fi
