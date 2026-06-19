#!/usr/bin/env bash
#
# One-time seed: migrate existing skills and .cursor rules from the sibling
# fosh-labs projects into this repo's categorized skills/ tree.
#
# Idempotent: safe to re-run to re-canonicalize from the source projects.
# Run from anywhere; paths are resolved relative to this repo.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECTS_DIR="$(cd "$REPO_DIR/.." && pwd)"   # /Users/adam/Developer/fosh labs
SKILLS_ROOT="$REPO_DIR/skills"

# Strip a leading YAML frontmatter block (--- ... ---) and print the body.
strip_frontmatter() {
  awk 'BEGIN{n=0}
       /^---[[:space:]]*$/ { n++; next }
       n>=2 { print }' "$1"
}

# Build a SKILL.md from a .cursor/.mdc rule body.
# args: <src.mdc> <category> <name> <description> [glob]
skill_from_rule() {
  local src="$1" cat="$2" name="$3" desc="$4" glob="${5:-}"
  local dir="$SKILLS_ROOT/$cat/$name"
  mkdir -p "$dir"
  {
    echo "---"
    echo "name: $name"
    echo "description: $desc"
    if [[ -n "$glob" ]]; then
      echo "paths:"
      echo "  - \"$glob\""
    fi
    echo "user-invocable: false"
    echo "---"
    echo ""
    strip_frontmatter "$src"
  } > "$dir/SKILL.md"
  echo "  seeded $cat/$name"
}

# Copy an existing SKILL.md verbatim into a category.
# args: <src/SKILL.md> <category> <name>
skill_copy() {
  local src="$1" cat="$2" name="$3"
  local dir="$SKILLS_ROOT/$cat/$name"
  mkdir -p "$dir"
  cp "$src" "$dir/SKILL.md"
  echo "  copied $cat/$name"
}

echo "Seeding skills into $SKILLS_ROOT"

# --- engineering (universal) ---------------------------------------------
skill_copy "$PROJECTS_DIR/guardian/guardian-cloud/.claude/skills/git-commit/SKILL.md" \
  engineering git-commit

# --- backend (Go) ---------------------------------------------------------
skill_copy "$PROJECTS_DIR/guardian/guardian-cloud/.claude/skills/go-naming/SKILL.md" \
  backend go-naming
skill_copy "$PROJECTS_DIR/guardian/guardian-cloud/.claude/skills/tailwind-plus-ui/SKILL.md" \
  backend tailwind-plus-ui

# --- kmp (shared / Android / cross-platform) -----------------------------
# Canonical source = fosh-labs-kmp-template (matches guardian-kmp; the other
# copies have drifted and will be overwritten on their next sync).
KMP="$PROJECTS_DIR/fosh-labs-kmp-template/.cursor/rules"
skill_from_rule "$KMP/kotlin-multiplatform-ruleset.mdc" kmp kotlin-multiplatform-architecture \
  "Kotlin Multiplatform Clean Architecture conventions — module/layer structure, MVVM, Koin DI, naming. Use when writing or editing Kotlin (.kt/.kts) in a KMP project." \
  "**/*.kt"
skill_from_rule "$KMP/feature-creation-checklist.mdc" kmp feature-creation-checklist \
  "Step-by-step checklist for adding a new feature module to a KMP project (shared ViewModel, Android Compose, iOS SwiftUI). Use when creating a new feature or screen." \
  ""
skill_from_rule "$KMP/android-implementation-from-ios.mdc" kmp android-implementation-from-ios \
  "Port an existing iOS SwiftUI screen to Android Jetpack Compose, matching structure and behavior. Use when implementing the Android side of a feature that already exists on iOS." \
  ""
skill_from_rule "$KMP/android-unittest-structure.mdc" kmp android-unittest-structure \
  "Structure and conventions for Android/Kotlin unit tests in a KMP project. Use when writing or editing unit tests." \
  ""

# --- ios (SwiftUI / iOS / watchOS) ---------------------------------------
skill_from_rule "$KMP/ios-swiftui-patterns.mdc" ios ios-swiftui-patterns \
  "SwiftUI patterns for the iOS app in a KMP project — view structure, view models, KMP interop. Use when writing or editing SwiftUI." \
  "**/*.swift"
skill_from_rule "$PROJECTS_DIR/guardian/.cursor/rules/sync-previews-with-state.mdc" ios sync-previews-with-state \
  "Keep SwiftUI and Compose previews in sync when ViewModel State changes. Use when editing ViewModel state, Views, Screens, or Previews." \
  ""
skill_from_rule "$PROJECTS_DIR/tally-counter-ios/.cursor/rules/localization.mdc" ios localization \
  "Cross-platform localization approach for a KMP app with iOS. Use when adding or editing localized strings." \
  ""
skill_from_rule "$PROJECTS_DIR/tally-counter-ios/.cursor/rules/watch-os-support-kmp.mdc" ios watch-os-support-kmp \
  "Adding watchOS support to a Kotlin Multiplatform iOS app where the watch app depends on shared code. Use when configuring a watchOS target." \
  ""

echo "Done."
