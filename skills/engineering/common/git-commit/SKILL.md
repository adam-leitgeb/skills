---
name: git-commit
description: Write git commit messages using conventional commits with a fixed type set and scoped subject lines. Use when creating commits, drafting commit messages, amending commits, or when the user asks about commit message format or git flow.
user-invocable: false
---

# Git Commit Conventions

All commit subject lines **must** follow:

```
<type>(<scope>): <short description>
```

## Allowed types

Only these types are permitted:

| Type | Use for |
|------|---------|
| `feat` | New user-facing capability or behavior |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, whitespace, CSS — no logic change |
| `refactor` | Code change that is neither a fix nor a feature |
| `perf` | Performance improvement |
| `test` | Adding or updating tests |
| `chore` | Maintenance — deps, tooling, migrations, CI config |

Do **not** use other types (`ci`, `build`, `revert`, etc.). Map them to the closest allowed type (e.g. CI changes → `chore(ci)`).

## Scope

- Required — every commit must include a scope in parentheses.
- Use a short, lowercase identifier for the affected area: `admin`, `events`, `auth`, `worker`, `ci`, `migrations`, etc.
- One primary scope per commit; pick the most meaningful area changed.

## Subject line rules

- Imperative mood: "add handler" not "added handler"
- Lowercase after the colon (unless a proper noun requires caps)
- No trailing period
- Keep under ~72 characters when possible
- Describe **what** changed at a glance; use the body for **why** when needed

## Commit workflow

When the user asks to commit:

1. Run `git status`, `git diff`, and `git log -5 --oneline` to understand changes and recent style.
2. Pick the single best `type` from the allowed set.
3. Pick a `scope` that matches the primary area touched.
4. Write the subject: `<type>(<scope>): <short description>`
5. Add an optional body (blank line after subject) when the why or trade-offs are not obvious.
6. Pass the message via HEREDOC:

```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <short description>

<optional body>
EOF
)"
```

## Examples

```
feat(admin): add offset pagination to events list
fix(events): defer superseded_by FK so supersession commits
docs(readme): document tailwind build contract
style(admin): refine severity badge sizing and opacity
refactor(worker): extract retry schedule into injectable dependency
perf(events): batch-load templates in dispatch worker
test(events): cover render and dispatch retry paths
chore(migrations): consolidate initial schema into single migration
```

## Validation checklist

Before committing, verify:

- [ ] Subject matches `<type>(<scope>): <short description>`
- [ ] `type` is one of: feat, fix, docs, style, refactor, perf, test, chore
- [ ] `scope` is present and describes the primary area
- [ ] Subject is imperative and concise
