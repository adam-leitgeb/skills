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

Action methods and callbacks are `onActionName()` — `onTapContinue()`,
`onSelectCountry()` — and take only what the UI knows
(`onSelectRow(id: String)`, not `onSelectRow(row: RowState)`).

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
