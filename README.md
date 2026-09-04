# skills

My personal Claude Code **skills** and **rules** — the workflow helpers and coding
conventions I reuse across my projects, both personal and under **fosh-labs** (my
one-person studio). The files here are the single source of truth; the Cursor rules
a project gets are generated thin pointers to them.

## Layout

```
skills/                # workflows you invoke, grouped by category (Mat Pocock style)
  engineering/         #   dev workflows, grouped by domain:
    common/            #     universal (git-commit) — every type
    kmp/               #     Kotlin Multiplatform: shared / Android / cross-platform
    ios/               #     SwiftUI / iOS / watchOS (shared by kmp + ios types)
    ios-only/          #     iOS-only (e.g. .xcstrings localization) — ios type only
    backend/           #     Go services
  productivity/        #   platform-agnostic helpers (grilling, handoff) — every type
rules/                 # conventions that apply on their own, same categories
  engineering/
    common/            #     code-comments (every session), ui-conventions
    kmp/               #     kotlin-multiplatform-architecture, kmp-viewmodel-state
    ios/               #     ios-swiftui-patterns
    backend/           #     go-naming, tailwind-plus-ui
project-types.conf     # project type -> categories mapping
scripts/
  update-skills.sh     # the sync worker (clone-free; run against a project)
Makefile.template      # the `update_skills` target projects copy in
```

## Skills vs rules

A **skill** is a workflow the model or you invoke: a folder with a `SKILL.md`
(`name` + `description` frontmatter). Claude Code shows the model only the
description and loads the body when the skill is invoked. Right for multi-step
procedures — scaffolding a feature, a hand-off, a commit.

A **rule** is a convention that must hold without anyone asking: one markdown file,
with an optional `paths:` list of globs in its frontmatter. Claude Code puts a rule
with `paths:` into context the moment it reads a matching file (in subagents too);
a rule without `paths:` is in context in every session. Rules trigger on reads, not
writes, which is why `code-comments` has no `paths:`: it is short, and it must also
cover a brand-new file written before anything was read. Long rules stay
path-scoped.

A convention authored as a skill does not work: the model sees its description in a
list and never reads the text. That is what this split fixes.

Both are written in exactly the format Claude Code reads and installed verbatim. To
add or change one, edit the file here — never a generated `.cursor/rules/*.mdc`.

Cursor gets the same conventions: every skill and rule becomes a `.cursor/rules/*.mdc`
pointer to its file, with a rule's `paths:` as the pointer's `globs:` and
`alwaysApply: true` for a rule that has none.

## Using it in a project

Copy the `update_skills` target from `Makefile.template` into the project's
Makefile (once), then:

```sh
make update_skills            # asks: kmp / backend / ios / other
make update_skills TYPE=kmp   # non-interactive
```

This clones the repo to a temp dir, installs the chosen type's skills into
`.claude/skills/` and its rules into `.claude/rules/` (plus a
`fosh-labs-conventions.md` index the skills can point at), generates a
`.cursor/rules/*.mdc` pointer for each plus the `claude-skills-source-of-truth.mdc`
meta-rule, and cleans up after itself.

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

Category names above are shorthand for their paths under `skills/` and `rules/` —
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
