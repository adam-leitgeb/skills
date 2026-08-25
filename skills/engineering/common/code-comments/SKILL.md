---
name: code-comments
description: When to write code comments — none by default; code carries its own meaning. Use when writing or editing Kotlin or Swift.
paths:
  - "**/*.kt"
  - "**/*.kts"
  - "**/*.swift"
user-invocable: false
---

# Code Comments

Write no comments by default. Code must be self-explanatory through its
declarations, structure, and architecture. A comment is justified only where
the code cannot carry the meaning itself — non-obvious business logic or
genuinely atypical UI code (a workaround, a platform quirk) — and it explains
*why*, never *what* the code does.

This governs the code you are writing or changing. Renaming or restructuring
is the preferred alternative to a comment **within that change**; it is not a
license to strip comments or rename things in code you weren't asked to touch.

Doc comments (KDoc, Swift `///`) have their own bar: only where a public API's
contract isn't clear from its signature and naming. Shared-module KDoc is what
iOS callers see in Xcode Quick Help, so a genuinely unclear contract is worth
documenting — a restatement of the name is not.

Outside this rule's scope — keep writing these where other skills call for them:

- `// MARK: -` section markers — organization, not commentary.
- `TODO` markers a scaffolding workflow plants deliberately (`new-kmp-feature`,
  `new-kmp-feature-shared-only`) — work-tracking, resolved before hand-off.
- Machine-directive and provenance comments: generated-file headers
  (`// GENERATED — do not edit`), lint suppressions, license headers.
- A rationale another skill explicitly requires, e.g. the test-placement doc
  comment in `android-unittest-structure`.

Code snippets inside these skills annotate for teaching. Don't copy their
comments into real code unless they mark a justified *why*.
