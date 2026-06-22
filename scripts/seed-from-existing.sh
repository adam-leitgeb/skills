#!/usr/bin/env bash
#
# seed-from-existing.sh — re-canonicalize this repo's skills/ tree from the
# sibling fosh-labs projects.
#
# History: this began as a one-time migration from the projects' .cursor/rules.
# Those rules are now GENERATED thin pointers (the sync writes them), so the real
# content lives in each project's .claude/skills/<name>/SKILL.md — which is itself
# synced from THIS repo. This script now copies those SKILL.md files back, so it
# serves as a round-trip / drift check: against a clean tree, a re-run should
# leave `git status` empty.
#
# Productivity skills (skills/productivity/*) are authored directly in this repo
# and have NO external source — they are intentionally not seeded here.
#
# Idempotent: safe to re-run. Run from anywhere; paths resolve relative to repo.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECTS_DIR="$(cd "$REPO_DIR/.." && pwd)"   # /Users/adam/Developer/fosh labs
SKILLS_ROOT="$REPO_DIR/skills"

# Canonical source projects — each carries a synced .claude/skills/ tree.
CLOUD="$PROJECTS_DIR/guardian/guardian-cloud/.claude/skills"   # common + backend
KMP="$PROJECTS_DIR/guardian/guardian-kmp/.claude/skills"       # kmp + shared ios
IOS_ONLY="$PROJECTS_DIR/tally-counter-ios/.claude/skills"      # iOS-only app

# Copy an existing SKILL.md verbatim into a category.
# args: <src-skills-root> <name> <category-path-under-skills/>
seed() {
  local src_root="$1" name="$2" cat="$3"
  local src="$src_root/$name/SKILL.md"
  local dir="$SKILLS_ROOT/$cat/$name"
  [[ -f "$src" ]] || { echo "  MISSING source: $src" >&2; return 1; }
  mkdir -p "$dir"
  cp "$src" "$dir/SKILL.md"
  echo "  seeded $cat/$name"
}

echo "Seeding skills into $SKILLS_ROOT"

# --- engineering/common (universal) --------------------------------------
seed "$CLOUD"    git-commit                        engineering/common

# --- engineering/backend (Go) --------------------------------------------
seed "$CLOUD"    go-naming                          engineering/backend
seed "$CLOUD"    tailwind-plus-ui                   engineering/backend

# --- engineering/kmp (shared / Android / cross-platform) -----------------
seed "$KMP"      kotlin-multiplatform-architecture  engineering/kmp
seed "$KMP"      feature-creation-checklist         engineering/kmp
seed "$KMP"      android-implementation-from-ios    engineering/kmp
seed "$KMP"      android-unittest-structure         engineering/kmp
seed "$KMP"      localization-kmp                   engineering/kmp
seed "$KMP"      state-model-preview-helpers        engineering/kmp

# --- engineering/ios (SwiftUI / iOS / watchOS, shared by kmp + ios) ------
seed "$KMP"      ios-swiftui-patterns               engineering/ios
seed "$KMP"      sync-previews-with-state           engineering/ios
seed "$KMP"      watch-os-support-kmp               engineering/ios

# --- engineering/ios-only (iOS-only conventions, e.g. .xcstrings) --------
seed "$IOS_ONLY" localization                       engineering/ios-only

# --- productivity --------------------------------------------------------
# Authored directly in this repo (grill-me, grilling, handoff) — no external
# source, intentionally not seeded. Edit skills/productivity/*/SKILL.md here.

echo "Done."
