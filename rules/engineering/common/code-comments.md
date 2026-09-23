# Code Comments

Write no comments by default. Code must be self-explanatory through its
declarations, structure, and architecture. A comment is justified only where
the code cannot carry the meaning itself — non-obvious business logic or
genuinely atypical UI code (a workaround, a platform quirk) — and it explains
*why*, never *what* the code does.

This governs the code you are writing or changing. Renaming or restructuring
is the preferred alternative to a comment **within that change**; it is not a
license to strip comments or rename things in code you weren't asked to touch.

Doc comments (KDoc, Swift `///`) split by whether a declaration is public
*on purpose*. In Swift, where the default is `internal`, every `open` or
`public` declaration, and every open or public member of one, gets a doc
comment — that surface is consumed without reading the source (this adopts
Google's Swift Style Guide requirement; see `swift-code-style`). Kotlin is
`public` by default, so there the requirement covers only a deliberate API: a
library module's surface, built for callers outside it. App code that is
public only because Kotlin defaults to it — a shared module's ViewModels,
UseCases, repositories — is not that surface, even though iOS sees it in
Xcode Quick Help. Where a doc comment is required, say what the signature
can't — one that restates the name is noise, and fixing the name is the
better move. Everything else holds to the no-comments default: the contract
must be clear from signature and naming, and a doc comment is justified only
where it genuinely can't be.

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
