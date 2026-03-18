#!/bin/bash
# Routing Tree Validator
# Validates that all skills are reachable and routing references resolve.
#
# Auto-detects AGENTS.md location:
#   1. If .codex/AGENTS.md exists → resolve from .codex/
#   2. Else if AGENTS.md exists at repo root → resolve from repo root
#
# Run from repository root: ./scripts/validate-routing-tree.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Auto-detect AGENTS.md location
if [ -f "$REPO_ROOT/.codex/AGENTS.md" ]; then
  AGENTS_DIR="$REPO_ROOT/.codex"
  echo "Detected .codex/ layout: resolving from $AGENTS_DIR"
elif [ -f "$REPO_ROOT/AGENTS.md" ]; then
  AGENTS_DIR="$REPO_ROOT"
  echo "Detected root layout: resolving from $AGENTS_DIR"
else
  echo "❌ AGENTS.md not found at repo root or .codex/" >&2
  exit 1
fi

AGENTS_FILE="$AGENTS_DIR/AGENTS.md"
ROUTING_DIR="$AGENTS_DIR/skills/routing"
SKILLS_DIR="$AGENTS_DIR/skills"

errors=0
warnings=0

echo "=== Routing Tree Validator ==="
echo "AGENTS.md: $AGENTS_FILE"
echo "Skills dir: $SKILLS_DIR"
echo ""

# --- Check 1: All routing files referenced from AGENTS.md exist ---
echo "--- Check 1: AGENTS.md routing references resolve ---"
while IFS= read -r ref; do
  full_path="$AGENTS_DIR/$ref"
  if [ ! -f "$full_path" ]; then
    echo "  ❌ AGENTS.md references '$ref' but $full_path does not exist"
    errors=$((errors + 1))
  else
    echo "  ✅ $ref"
  fi
done < <(grep -oE 'skills/routing/[A-Z_]+\.md' "$AGENTS_FILE" | sort -u)
echo ""

# --- Check 1b: Every routing file is reachable from AGENTS.md or another routing file ---
echo "--- Check 1b: Routing files are reachable ---"
while IFS= read -r routing_file; do
  rel_path="skills/routing/$(basename "$routing_file")"

  if grep -q "$rel_path" "$AGENTS_FILE"; then
    continue
  fi

  parent_ref=$(grep -rl "$rel_path" "$ROUTING_DIR"/ 2>/dev/null | grep -v "^$routing_file$" | head -1 || true)
  if [ -z "$parent_ref" ]; then
    echo "  ❌ ORPHAN ROUTING FILE: $rel_path is not referenced from AGENTS.md or any routing branch"
    errors=$((errors + 1))
  fi
done < <(find "$ROUTING_DIR" -maxdepth 1 -name "*.md" | sort)
echo "  Done."
echo ""

# --- Check 2: All leaf skill paths in routing files exist ---
echo "--- Check 2: Routing files → leaf skill paths resolve ---"
check2_errors=0
while IFS= read -r ref; do
  full_path="$AGENTS_DIR/$ref"
  if [ ! -f "$full_path" ]; then
    echo "  ❌ Referenced '$ref' but $full_path does not exist"
    errors=$((errors + 1))
    check2_errors=$((check2_errors + 1))
  fi
done < <(grep -rohE 'skills/[a-z0-9-]+/SKILL\.md' "$ROUTING_DIR"/ | sort -u)
ref_count=$(grep -rohE 'skills/[a-z0-9-]+/SKILL\.md' "$ROUTING_DIR"/ | sort -u | wc -l | tr -d ' ')
if [ "$check2_errors" -eq 0 ]; then
  echo "  ✅ Found $ref_count leaf references, all resolved."
else
  echo "  ❌ Found $check2_errors unresolved leaf reference(s) out of $ref_count."
fi
echo ""

# --- Check 3: All SKILL.md files on disk are reachable from routing ---
echo "--- Check 3: Coverage — every SKILL.md is reachable ---"
while IFS= read -r skill_path; do
  skill_name=$(echo "$skill_path" | sed "s|$AGENTS_DIR/skills/||;s|/SKILL.md||")
  found=$(grep -rl "skills/$skill_name/SKILL.md" "$ROUTING_DIR"/ 2>/dev/null | head -1 || true)
  if [ -z "$found" ]; then
    echo "  ❌ ORPHAN: $skill_name exists on disk but is not referenced in any routing file"
    errors=$((errors + 1))
  fi
done < <(find "$SKILLS_DIR" -name "SKILL.md" -not -path "*/routing/*" | sort)
skill_count=$(find "$SKILLS_DIR" -name "SKILL.md" -not -path "*/routing/*" | wc -l | tr -d ' ')
referenced_count=$(grep -rohE 'skills/[a-z0-9-]+/SKILL\.md' "$ROUTING_DIR"/ | sort -u | wc -l | tr -d ' ')
echo "  Skills on disk: $skill_count | Referenced in routing: $referenced_count"
echo ""

# --- Check 4: No skill referenced in 2+ different branch files (overlap) ---
echo "--- Check 4: No duplicate ownership across branches ---"
while IFS= read -r skill_path; do
  skill_name=$(echo "$skill_path" | sed "s|$AGENTS_DIR/skills/||;s|/SKILL.md||")
  owner_files=$(grep -rl "skills/$skill_name/SKILL.md" "$ROUTING_DIR"/ 2>/dev/null || true)
  count=$(printf "%s\n" "$owner_files" | sed '/^$/d' | wc -l | tr -d ' ')
  if [ "$count" -gt 1 ]; then
    owners=$(printf "%s\n" "$owner_files" | sed '/^$/d' | sed "s|$ROUTING_DIR/||" | tr '\n' ', ' | sed 's/,$//')
    echo "  ⚠️  $skill_name appears in $count files: $owners"
    warnings=$((warnings + 1))
  fi
done < <(find "$SKILLS_DIR" -name "SKILL.md" -not -path "*/routing/*" | sort)
echo "  Done."
echo ""

# --- Check 5: All routing sibling references resolve ---
echo "--- Check 5: Cross-references between routing files resolve ---"
while IFS= read -r routing_file; do
  while IFS= read -r ref; do
    full_path="$AGENTS_DIR/$ref"
    if [ ! -f "$full_path" ]; then
      echo "  ❌ $(basename "$routing_file") references '$ref' but $full_path does not exist"
      errors=$((errors + 1))
    fi
  done < <(grep -oE 'skills/routing/[A-Z_]+\.md' "$routing_file" 2>/dev/null || true)
done < <(find "$ROUTING_DIR" -name "*.md" | sort)
echo "  Done."
echo ""

# --- Check 6: Every skill has required frontmatter ---
echo "--- Check 6: Skill quality gates ---"
while IFS= read -r skill_file; do
  skill_name=$(echo "$skill_file" | sed "s|$AGENTS_DIR/skills/||;s|/SKILL.md||")
  has_name=$(grep -c "^name:" "$skill_file" 2>/dev/null || echo 0)
  has_desc=$(grep -c "^description:" "$skill_file" 2>/dev/null || echo 0)
  if [ "$has_name" -eq 0 ] || [ "$has_desc" -eq 0 ]; then
    echo "  ⚠️  $skill_name: missing frontmatter (name=$has_name, description=$has_desc)"
    warnings=$((warnings + 1))
  fi
done < <(find "$SKILLS_DIR" -name "SKILL.md" -not -path "*/routing/*" | sort)
echo "  Done."
echo ""

# --- Summary ---
echo "=== Summary ==="
echo "Layout: $(basename "$AGENTS_DIR") (AGENTS.md at: $AGENTS_FILE)"
echo "Skills: $skill_count on disk, $referenced_count in routing"
if [ "$errors" -eq 0 ] && [ "$warnings" -eq 0 ]; then
  echo "✅ All checks passed. Routing tree is valid."
elif [ "$errors" -eq 0 ]; then
  echo "⚠️  $warnings warning(s), 0 errors. Tree is valid but review warnings."
else
  echo "❌ $errors error(s), $warnings warning(s). Tree has issues that must be fixed."
  exit 1
fi
