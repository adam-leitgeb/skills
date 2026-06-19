# fosh-labs skills

Centralized Claude Code **skills** and Cursor **rules** for all fosh-labs projects.
Skills are the single source of truth; Cursor rules are generated thin pointers to them.

## Layout

```
skills/                # the skills, grouped by category (Mat Pocock style)
  engineering/         #   universal (git-commit)
  kmp/                 #   Kotlin Multiplatform: shared / Android / cross-platform
  ios/                 #   SwiftUI / iOS / watchOS
  backend/             #   Go services
project-types.conf     # project type -> categories mapping
scripts/
  update-skills.sh     # the sync worker (clone-free; run against a project)
  seed-from-existing.sh# one-time migration from the old per-project rules
Makefile.template      # the `update_skills` target projects copy in
```

Each skill is a folder with a `SKILL.md` (`name` + `description` frontmatter,
optional `paths:` globs). To add or change a convention, **edit the SKILL.md** —
never the generated `.cursor/rules/*.mdc`.

## Using it in a project

Copy the `update_skills` target from `Makefile.template` into the project's
Makefile (once), then:

```sh
make update_skills            # asks: kmp / backend / ios / other
make update_skills TYPE=kmp   # non-interactive
```

This clones the repo to a temp dir, installs the skills for the chosen type into
`.claude/skills/`, generates matching `.cursor/rules/*.mdc` pointers plus a
`claude-skills-source-of-truth.mdc` meta-rule, and cleans up after itself.

Set `SKILLS_REPO` once you push this repo to GitHub
(`SKILLS_REPO=git@github.com:foshlabs/skills.git`), or point it at a local clone
for testing.

## Project types

Defined in `project-types.conf` — a type maps to a list of categories:

| Type | Categories | Notes |
|------|------------|-------|
| `kmp` | engineering + kmp + ios | KMP spans both platforms → everything except backend |
| `backend` | engineering + backend | Go services → no mobile rules |
| `ios` | engineering + ios | iOS / watchOS-only app |
| `other` | engineering | universal only |

Edit that file to add a type or remix the mapping; the next sync picks it up.

## Project-specific skills are preserved

The sync tracks exactly what it installed in `.claude/skills/.managed`. On each
run it removes only those entries before reinstalling. **Anything not in the
manifest** — a hand-written `.claude/skills/<x>/` or a local `.cursor/rules/*.mdc`
— is never touched. So a project can keep its own skills alongside the shared
ones (e.g. Guardian's `ticket-spec`, which stays local because it's hardwired to
Guardian's Notion).

## Re-seeding from existing projects

`scripts/seed-from-existing.sh` regenerates the `skills/` tree from the canonical
source projects (KMP rules come from `fosh-labs-kmp-template`, which is treated as
canonical where copies have drifted). Run it to re-import after editing a rule in
a project, or just edit the SKILL.md here directly.
