# skills

My personal Claude Code **skills** and Cursor **rules** — the coding conventions and
workflow helpers I reuse across my projects, both personal and under **fosh-labs** (my
one-person studio). Skills are the single source of truth; Cursor rules are generated
thin pointers to them.

## Layout

```
skills/                # the skills, grouped by category (Mat Pocock style)
  engineering/         #   all dev skills, grouped by domain:
    common/            #     universal (git-commit) — every type
    kmp/               #     Kotlin Multiplatform: shared / Android / cross-platform
    ios/               #     SwiftUI / iOS / watchOS (shared by kmp + ios types)
    ios-only/          #     iOS-only conventions (e.g. .xcstrings localization) — ios type only
    backend/           #     Go services
  productivity/        #   platform-agnostic workflow helpers (grilling, handoff) — every type
project-types.conf     # project type -> categories mapping
scripts/
  update-skills.sh     # the sync worker (clone-free; run against a project)
Makefile.template      # the `update_skills` target projects copy in
```

Each skill is a folder with a `SKILL.md` (`name` + `description` frontmatter,
optional `paths:` globs). To add or change a convention, **edit the SKILL.md** —
never a generated file (`.cursor/rules/*.mdc`, `.claude/rules/*.md`).

### `paths:` — conventions that must hold on every matching edit

A skill's body reaches the model only when the skill is invoked; until then the
model sees its one-line `description`. `paths:` on a skill makes it a *conditional*
skill — Claude Code lists it only after a matching file has been read — but that
still only lists it. So for a skill with `paths:`, the sync also generates a
**path-scoped rule**, `.claude/rules/<name>.md`: the same globs, the same body.
Claude Code puts a path-scoped rule into context the moment it reads a matching
file, in subagents too, so the rule text itself — not just its description — is in
front of the model whenever it works on a `.kt` or `.swift` file. Rules trigger on
reads, not writes: a brand-new file written without reading a sibling first does not
fire one.

`paths:` is a real Claude Code frontmatter field, so the installed `SKILL.md` keeps
it verbatim; the same globs become the Cursor rule's `globs:`.

## Using it in a project

Copy the `update_skills` target from `Makefile.template` into the project's
Makefile (once), then:

```sh
make update_skills            # asks: kmp / backend / ios / other
make update_skills TYPE=kmp   # non-interactive
```

This clones the repo to a temp dir, installs the skills for the chosen type into
`.claude/skills/`, generates a path-scoped `.claude/rules/<name>.md` for each skill
with `paths:`, generates matching `.cursor/rules/*.mdc` pointers plus a
`claude-skills-source-of-truth.mdc` meta-rule, and cleans up after itself.

Point `SKILLS_REPO` at this repo
(`SKILLS_REPO=git@github.com:adam-leitgeb/skills.git`), or at a local clone for testing.

## Project types

Defined in `project-types.conf` — a type maps to a list of categories:

| Type | Categories | Notes |
|------|------------|-------|
| `kmp` | common + productivity + kmp + ios | KMP spans both platforms → everything except backend. Localizes via `localization-kmp` (in `engineering/kmp`); excludes `ios-only` |
| `backend` | common + productivity + backend | Go services → no mobile rules |
| `ios` | common + productivity + ios + ios-only | iOS / watchOS-only app; `ios-only` carries the `.xcstrings` localization skill |
| `other` | common + productivity | universal only |

Category names above are shorthand for their paths under `skills/` —
`common` is `engineering/common`, `kmp` is `engineering/kmp`, etc.
`engineering/common` and `productivity` are included in every type.

Edit that file to add a type or remix the mapping; the next sync picks it up.

## Project-specific skills are preserved

The sync tracks exactly what it installed in `.claude/skills/.managed`. On each
run it removes only those entries before reinstalling. **Anything not in the
manifest** — a hand-written `.claude/skills/<x>/`, a local `.claude/rules/*.md`, or
a local `.cursor/rules/*.mdc` — is never touched. So a project can keep its own skills alongside the shared
ones (e.g. Guardian's `ticket-spec`, which stays local because it's hardwired to
Guardian's Notion).
