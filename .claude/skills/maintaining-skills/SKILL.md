---
name: maintaining-skills
description: Use when adding, removing, renaming, or moving any skill under skills/** in this repo, or when changing a category or project-type mapping. Keeps project-types.conf, README.md, and scripts/seed-from-existing.sh in sync so nothing goes stale.
---

# Maintaining the skills repo

This repo is the source of truth for fosh-labs Claude Code skills and the
generated Cursor rules. A skill is a folder `skills/<category>/<name>/SKILL.md`.
A **category** is a path under `skills/` that directly contains skill folders
(e.g. `engineering/kmp`, `engineering/common`, `productivity`).

Whenever you **add, remove, rename, or move** a skill — or add/rename a category
or project type — update ALL of the following in the same change. Forgetting one
leaves it stale (we already shipped a broken `seed-from-existing.sh` once this
way):

1. **The skill** — `skills/<category>/<name>/SKILL.md` with `name` +
   `description` frontmatter (add `paths:` globs if it's path-scoped). Edit the
   SKILL.md here; never hand-edit a generated `.cursor/rules/*.mdc` in a
   consuming project — the sync regenerates those pointers.
2. **`project-types.conf`** — ensure the skill's category is mapped to every
   project type that should receive it. Categories are written as paths
   (`engineering/kmp`, not `kmp`). The sync globs `<category>/*/SKILL.md` and is
   depth-agnostic.
3. **`scripts/seed-from-existing.sh`** — add / remove / re-path the matching
   `seed` line so a re-seed reproduces the current tree. It copies the full
   SKILL.md from each sibling project's `.claude/skills/` (those are synced from
   here). Skills authored only in this repo — `productivity/*` — have no
   external source and are deliberately NOT seeded; note them in the comment.
4. **`README.md`** — update the Layout tree and the project-types table.

## Verify before committing

Run both checks:

- **Sync** installs the right set per type:
  ```sh
  for t in kmp backend ios other; do
    tmp="$(mktemp -d)"
    bash scripts/update-skills.sh --type "$t" --project "$tmp" >/dev/null \
      && { printf '%s: ' "$t"; ls "$tmp/.claude/skills" | grep -v '^.managed$' | paste -sd' ' -; }
    rm -rf "$tmp"
  done
  ```
- **Seed is current** — re-running it must leave the tree unchanged:
  ```sh
  bash scripts/seed-from-existing.sh && git status --porcelain skills/
  ```
  Non-empty output means `seed-from-existing.sh` drifted from the actual skills
  (or a source project drifted) — reconcile before committing.
