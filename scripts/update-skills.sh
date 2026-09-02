#!/usr/bin/env bash
#
# update-skills.sh — sync centralized skills + Cursor rules into a project.
#
# Run from a project directory (the Makefile does this after cloning the repo):
#   scripts/update-skills.sh [--type kmp|backend|ios|other] [--project DIR]
#
# Behavior:
#   * Asks the project type (unless --type given) and resolves its categories
#     from project-types.conf.
#   * Installs every skill in those categories into <project>/.claude/skills/,
#     and generates a matching thin-pointer rule in <project>/.cursor/rules/.
#   * For a skill with `paths:` globs, also generates a path-scoped rule in
#     <project>/.claude/rules/ carrying the skill body, so Claude Code has the
#     rule in context whenever it reads a matching file.
#   * Removes ONLY what a previous run installed (tracked in a manifest), so
#     project-specific skills and hand-written rules are preserved.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_ROOT="$REPO_DIR/skills"
TYPES_CONF="$REPO_DIR/project-types.conf"

PROJECT_DIR="$PWD"
TYPE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)    TYPE="$2"; shift 2 ;;
    --project) PROJECT_DIR="$(cd "$2" && pwd)"; shift 2 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -f "$TYPES_CONF" ]] || { echo "missing $TYPES_CONF" >&2; exit 1; }
if [[ "$PROJECT_DIR" == "$REPO_DIR" ]]; then
  echo "refusing to install into the skills repo itself" >&2; exit 1
fi

available_types() { grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$TYPES_CONF" | sed -E 's/:.*//' | tr -d ' '; }
categories_for()  { grep -E "^[[:space:]]*$1[[:space:]]*:" "$TYPES_CONF" | sed -E 's/^[^:]*:[[:space:]]*//'; }

# --- pick type ------------------------------------------------------------
if [[ -z "$TYPE" ]]; then
  echo "Project: $PROJECT_DIR"
  echo "Available types: $(available_types | paste -sd' ' -)"
  printf "Project type? " > /dev/tty
  read -r TYPE < /dev/tty
fi
CATEGORIES="$(categories_for "$TYPE")"
[[ -n "$CATEGORIES" ]] || { echo "unknown type '$TYPE' (have: $(available_types | paste -sd', ' -))" >&2; exit 1; }
echo "Type '$TYPE' -> categories: $CATEGORIES"

CLAUDE_SKILLS="$PROJECT_DIR/.claude/skills"
CLAUDE_RULES="$PROJECT_DIR/.claude/rules"
CURSOR_RULES="$PROJECT_DIR/.cursor/rules"
MANIFEST="$CLAUDE_SKILLS/.managed"
META_RULE="claude-skills-source-of-truth.mdc"

# --- remove what a previous run installed --------------------------------
if [[ -f "$MANIFEST" ]]; then
  while IFS= read -r line; do
    case "$line" in
      skill:*)       rm -rf "$CLAUDE_SKILLS/${line#skill:}" ;;
      rule:*)        rm -f  "$CURSOR_RULES/${line#rule:}" ;;
      claude-rule:*) rm -f  "$CLAUDE_RULES/${line#claude-rule:}" ;;
    esac
  done < "$MANIFEST"
  rm -f "$MANIFEST"
fi

mkdir -p "$CLAUDE_SKILLS" "$CURSOR_RULES"

# --- frontmatter helpers --------------------------------------------------
get_desc() { sed -n 's/^description:[[:space:]]*//p' "$1" | head -1; }

# The `paths:` block (header + list items) from the first frontmatter block, verbatim.
# Empty when the skill has no `paths:`. Blank and comment lines inside the list are dropped.
get_paths_block() {
  awk '
    NR==1 && /^---[[:space:]]*$/ { fm=1; next }
    fm && /^---[[:space:]]*$/    { exit }
    fm && /^paths:[[:space:]]*$/ { inp=1; print; next }
    inp && /^[[:space:]]+-/      { print; next }
    inp && /^[^[:space:]]/       { exit }
  ' "$1"
}

# Cursor `globs:` value: the paths list joined with commas.
get_globs() {
  get_paths_block "$1" | awk '
    /^[[:space:]]+-/ {
      v=$0; sub(/^[[:space:]]*-[[:space:]]*/,"",v); gsub(/"/,"",v); gsub(/[[:space:]]+$/,"",v)
      g = g (g==""?"":",") v
    }
    END { print g }
  '
}

# Everything after the first frontmatter block.
get_body() {
  awk '
    NR==1 && /^---[[:space:]]*$/ { fm=1; next }
    fm && /^---[[:space:]]*$/    { fm=0; body=1; next }
    body { print }
  ' "$1"
}

# --- install selected skills ---------------------------------------------
declare -a INSTALLED_SKILLS=()
declare -a INSTALLED_RULES=()
declare -a INSTALLED_CLAUDE_RULES=()

for cat in $CATEGORIES; do
  cat_dir="$SKILLS_ROOT/$cat"
  [[ -d "$cat_dir" ]] || { echo "  (no such category: $cat — skipping)"; continue; }
  for skill_md in "$cat_dir"/*/SKILL.md; do
    [[ -e "$skill_md" ]] || continue
    name="$(basename "$(dirname "$skill_md")")"

    # skill
    mkdir -p "$CLAUDE_SKILLS/$name"
    cp "$skill_md" "$CLAUDE_SKILLS/$name/SKILL.md"
    INSTALLED_SKILLS+=("$name")

    desc="$(get_desc "$skill_md")"
    paths_block="$(get_paths_block "$skill_md")"
    globs="$(get_globs "$skill_md")"
    body="$(get_body "$skill_md")"

    if grep -q '^paths:' "$skill_md" && [[ -z "$globs" || -z "$body" ]]; then
      echo "  warning: $name — paths: must be a YAML list inside a closed frontmatter block; no Claude rule generated" >&2
    fi

    # generated path-scoped Claude Code rule: the skill body, in context whenever
    # Claude reads a matching file (a skill alone only shows its description).
    if [[ -n "$globs" && -n "$body" ]]; then
      mkdir -p "$CLAUDE_RULES"
      {
        echo "---"
        echo "$paths_block"
        echo "---"
        echo "<!-- Generated from .claude/skills/$name/SKILL.md by fosh-labs/skills. Edit the skill, not this file. -->"
        echo "$body"
      } > "$CLAUDE_RULES/$name.md"
      INSTALLED_CLAUDE_RULES+=("$name.md")
    fi

    # generated thin-pointer cursor rule
    rule_file="$CURSOR_RULES/$name.mdc"
    {
      echo "---"
      echo "description: ${desc:-See .claude/skills/$name/SKILL.md}"
      [[ -n "$globs" ]] && echo "globs: $globs"
      echo "alwaysApply: false"
      echo "---"
      echo ""
      echo "# $name"
      echo ""
      echo "This convention is authored as a Claude Code skill (the source of truth):"
      echo "\`.claude/skills/$name/SKILL.md\`."
      echo ""
      echo "**Read that file and follow it fully.** Do not duplicate its content here;"
      echo "edit the skill, not this rule. Generated by fosh-labs/skills."
    } > "$rule_file"
    INSTALLED_RULES+=("$name.mdc")
  done
done

# --- meta rule: skills are source of truth -------------------------------
{
  echo "---"
  echo "description: Claude Code skills in .claude/skills/ are the canonical project conventions"
  echo "alwaysApply: true"
  echo "---"
  echo ""
  echo "# Claude Code skills (source of truth)"
  echo ""
  echo "Project conventions are authored for Claude Code in \`.claude/skills/*/SKILL.md\`."
  echo "The Cursor rules here only point to those files — never duplicate their content."
  echo ""
  echo "| Skill | File |"
  echo "|-------|------|"
  for name in "${INSTALLED_SKILLS[@]}"; do
    echo "| $name | \`.claude/skills/$name/SKILL.md\` |"
  done
  echo ""
  echo "When a task matches a skill, read that SKILL.md first and follow it fully."
  echo "Edit conventions in \`.claude/skills/\` only. Managed by fosh-labs/skills —"
  echo "skills/rules not in \`.claude/skills/.managed\` are project-specific and preserved."
} > "$CURSOR_RULES/$META_RULE"
INSTALLED_RULES+=("$META_RULE")

# --- write manifest -------------------------------------------------------
{
  echo "# Managed by fosh-labs/skills — do not edit by hand."
  echo "# Skills/rules NOT listed here are project-specific and preserved across syncs."
  echo "type=$TYPE"
  for name in "${INSTALLED_SKILLS[@]}"; do echo "skill:$name"; done
  for rule in "${INSTALLED_RULES[@]}"; do echo "rule:$rule"; done
  for rule in "${INSTALLED_CLAUDE_RULES[@]+"${INSTALLED_CLAUDE_RULES[@]}"}"; do echo "claude-rule:$rule"; done
} > "$MANIFEST"

echo "Installed ${#INSTALLED_SKILLS[@]} skills + ${#INSTALLED_CLAUDE_RULES[@]} Claude rules + ${#INSTALLED_RULES[@]} Cursor rules into $PROJECT_DIR"
echo "Manifest: $MANIFEST"
