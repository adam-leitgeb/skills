---
paths:
  - "**/*.swift"
---

# Swift Code Style

Swift code follows [Google's Swift Style Guide](https://google.github.io/swift/),
which incorporates Apple's API Design Guidelines wholesale. This rule carries
the rules that change behavior in practice; the guide is authoritative for
anything not covered here or by a house rule below.

## House rules that take precedence

- **Doc comments**: the guide's floor (every `open`/`public` declaration) is
  adopted as-is; the house adds a ceiling the guide doesn't have — `internal`
  and below default to none. The rule lives in `code-comments`.
- **Action naming**: Swift methods follow Apple conventions, closures keep the
  `on` prefix — the rule lives in `ui-conventions`.
- **`CO` component prefix**: grandfathered exception in existing design
  libraries — see `ios-swiftui-patterns`.
- **Indentation**: Xcode's default 4 spaces, not the guide's 2.

## File basics

- One primary type per file, named after it: `MyType.swift`. An extension
  adding functionality or a conformance is `MyType+Description.swift`
  (house examples: `View+Alert.swift`, `CGFloat+Spacing.swift`).
- No file header comments — delete Xcode's `// Created by …` template block.
- No semicolons.
- Column limit 100. Exceptions: `import` lines and unbreakable text such as
  URLs in comments.

## Formatting

- K&R braces: the opening brace ends its line, the closing brace gets its own.
- Every `let`/`var` declares exactly one variable (tuple destructuring aside).
- Trailing commas are required in array/dictionary literals when each element
  is on its own line.
- One `case` per line in an enum; comma-joined cases only when none carry
  associated values or docs and all fit on one line.
- `switch` cases sit at the same column as the `switch`; case bodies indent
  one level.
- No parentheses around the top-level `if`/`guard`/`while`/`switch` condition.
- Single spaces around binary operators and after commas and colons; a single
  blank line between members.

## Comments

- Doc comments are line format only: `///`, never `/** … */`. Non-doc
  comments are `//`, never `/* … */`.
- When to write them is `code-comments`' call: required on `open`/`public`
  declarations and their public members; internal/private only where the
  signature genuinely can't carry the contract.

## Optionals & force operations

- Force-unwrap (`!`), `as!`, and `try!` are prohibited and SwiftLint-enforced
  (below). Where one is genuinely justified — a compile-time literal, test
  code — disable the rule for that line and state the *why*:

  ```swift
  // Safe: compile-time literal.
  // swiftlint:disable:next force_unwrapping
  let url = URL(string: "https://example.com")!
  ```

- Implicitly unwrapped optionals (`var x: T!`) only for lifecycle-initialized
  properties; never propagate them across layers.
- Testing for presence without using the value compares to `nil`
  (`if value != nil`), not `if let _ = value`.

## Control flow

- `guard` for early exits; keep the happy path flush left.
- A `for` loop whose entire body is one `if` on the element moves the test
  into `where`: `for item in items where item.isEnabled { … }`.
- Pattern bindings put `let`/`var` on each element — `case .foo(let x, let y)`,
  not `case let .foo(x, y)`.

## Extensions & access

- No access level on the extension declaration itself (`private extension` /
  `public extension` are forbidden); each member declares its own where it
  differs from the default.
- Nest types to express ownership — a flag enum or error type belongs inside
  the type it serves — instead of encoding the relationship in a name.
- Access control, not naming, hides things: prefer `private`/`fileprivate`
  over underscore or prefix conventions.

## Enforcement: SwiftLint

Projects enforce the force-operation ban in `.swiftlint.yml`:

```yaml
opt_in_rules:
  - force_unwrapping

force_unwrapping:
  severity: error
force_cast: error
force_try: error
```
