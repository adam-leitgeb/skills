---
name: maintaining-skills
description: Use when adding or renaming a skill/rule CATEGORY (a folder under skills/ or rules/) or a project TYPE in this repo. Keeps project-types.conf and README.md in sync so a new category/type isn't silently left uninstalled. Adding a skill or rule to an existing category needs none of this.
---

# Maintaining the skills repo

This repo is the source of truth for fosh-labs Claude Code skills and rules and
the generated Cursor rules. A skill (a workflow) is a folder
`skills/<category>/<name>/SKILL.md`; a rule (a convention) is a file
`rules/<category>/<name>.md`. A **category** is a path that exists under `skills/`,
`rules/`, or both (e.g. `engineering/kmp`, `engineering/common`, `productivity`).

`update-skills.sh` installs, per project type, every skill and rule in that type's
categories — it globs `skills/<category>/*/SKILL.md` and `rules/<category>/*.md`
and is depth-agnostic.

## When you do NOT need to touch anything

Adding, editing, or removing a skill or rule inside an **existing** category is
fully automatic — the sync globs the category, so it ships on the next
`make update_skills`. No config changes. A skill is a `SKILL.md` with `name` +
`description` frontmatter; a rule is a markdown file with a `paths:` list of globs,
or no frontmatter at all if it should hold in every session. Which one to write is
the README's *Skills vs rules* section — a convention written as a skill is never
read.

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

Sync into a throwaway dir for each affected type and confirm the installed set:

```sh
for t in kmp backend ios other; do
  tmp="$(mktemp -d)"
  bash scripts/update-skills.sh --type "$t" --project "$tmp" >/dev/null && {
    printf '%s\n  skills: ' "$t"; ls "$tmp/.claude/skills" | grep -v '^.managed$' | paste -sd' ' -
    printf '  rules:  '; ls "$tmp/.claude/rules" | paste -sd' ' -
  }
  rm -rf "$tmp"
done
```
