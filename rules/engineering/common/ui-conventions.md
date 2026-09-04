---
paths:
  - "**/*.swift"
  - "**/*.kt"
---

# UI Conventions

The naming and organization rules that apply to both platforms — one home,
pointed at from the platform skills.

## View & Screen Naming

- **iOS (SwiftUI)**: only top-level screen views carry the "View" suffix
  (`LearnView`, `HomeView`). Sub-views and components do not (`TipsSection`,
  `PracticeSection`).
- **Android (Compose)**: only top-level screen composables carry the "Screen"
  suffix (`LearnScreen`, `HomeScreen`). Sub-composables and components do not
  (`TipsSection`, `PracticeSection`).

## Action Naming

Actions take only what the UI knows (`id: String`, not `row: RowState`) on
both platforms. The names split by platform:

- **Kotlin** (shared ViewModels, Compose callbacks): `onActionName()` —
  `onTapContinue()`, `onSelectCountry()`.
- **Swift methods** follow Apple's API design guidelines (adopted via
  `swift-code-style`): no `on` prefix on methods. A UI-event handler is
  `didTapContinue()`; a method named for its effect is an imperative verb
  phrase (`submitEmail()`, `dismissError()`).
- **Closure properties and parameters** keep the `on` prefix on both
  platforms — `state.onSendTap`, `onAction:` — matching SwiftUI/Compose
  idiom (`onDelete`, `onClick`).

Swift code calling a shared Kotlin ViewModel uses the Kotlin names as-is
(`viewModel.onTapContinue()`); the Swift rule governs methods declared in
Swift.

## MARK Sections

`// MARK: -` sections are **topical, not a fixed set** — use the conventional
set for the file's kind and split further when the file earns it:

- **SwiftUI screen views**: `Properties`, `Body`, `Private Views`, `Actions`,
  `Previews`.
- **ViewModels**: `Properties`, `Initialization`, `Actions`, `Helpers` are the
  common ones; add `State builders`, `Loading`, `Observers`, `Analytics` when
  earned.
- **Repositories**: `Properties`, `Methods`.
- **Compose screens ported from iOS**: mirror the iOS file's sections
  (`android-implementation-from-ios`).
