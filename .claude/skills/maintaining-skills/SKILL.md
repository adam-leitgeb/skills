---
name: maintaining-skills
description: Use when adding or renaming a skill CATEGORY (a folder under skills/) or a project TYPE in this repo. Keeps project-types.conf and README.md in sync so a new category/type isn't silently left uninstalled. Adding a skill to an existing category needs none of this.
---

# Maintaining the skills repo

This repo is the source of truth for fosh-labs Claude Code skills and the
generated Cursor rules. A skill is a folder `skills/<category>/<name>/SKILL.md`.
A **category** is a path under `skills/` that directly contains skill folders
(e.g. `engineering/kmp`, `engineering/common`, `productivity`).

`update-skills.sh` installs, per project type, every skill in that type's
categories — it globs `<category>/*/SKILL.md` and is depth-agnostic.

## When you do NOT need to touch anything

Adding, editing, or removing a skill inside an **existing** category is fully
automatic — the sync globs the category, so the new skill ships on the next
`make update_skills`. No config changes. (Just write the `SKILL.md` with `name`
+ `description` frontmatter, and `paths:` globs if it's path-scoped.)

`paths:` is what makes a convention hold on every matching edit: the sync
generates a path-scoped `.claude/rules/<name>.md` from the skill body, which Claude
Code puts in context whenever it reads a matching file. Without `paths:` the model
sees only the skill's `description` until it chooses to invoke the skill. The
mechanism is spelled out in the README.

## When you DO need to keep things in sync

- **New category** (a new folder of skills, e.g. `engineering/desktop`): map it
  in `project-types.conf` to every type that should receive it — otherwise it is
  silently never installed. Then update the Layout tree and project-types table
  in `README.md`.
- **New / renamed project type**: add it to `project-types.conf`, and update the
  README's type list and table (the type names appear in a couple of places).

## Always

Never hand-edit a generated `.cursor/rules/*.mdc` in a consuming project — edit
the `SKILL.md` here; the sync regenerates the pointers.

## Verify before committing

Sync into a throwaway dir for each affected type and confirm the installed set.
Every skill with `paths:` must appear under `rules:` too.

```sh
for t in kmp backend ios other; do
  tmp="$(mktemp -d)"
  bash scripts/update-skills.sh --type "$t" --project "$tmp" >/dev/null && {
    printf '%s\n  skills: ' "$t"; ls "$tmp/.claude/skills" | grep -v '^.managed$' | paste -sd' ' -
    printf '  rules:  '; ls "$tmp/.claude/rules" 2>/dev/null | paste -sd' ' -; echo
  }
  rm -rf "$tmp"
done
```
