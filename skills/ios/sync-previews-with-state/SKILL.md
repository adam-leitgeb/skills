---
name: sync-previews-with-state
description: Keep SwiftUI and Compose previews in sync when ViewModel State changes. Use when editing ViewModel state, Views, Screens, or Previews.
user-invocable: false
---


# Sync Previews When ViewModel State Changes

Whenever you add, remove, or rename a property on a `ViewModel.State` data class, **immediately update every preview that constructs that State**.

## SwiftUI (`#Preview` / `_Preview`)

```swift
// ✅ After adding `pages` and `currentPageId` to State:
#Preview {
    Content(
        state: OnboardingViewModel.State(
            primaryButtonTitle: "Get Started",
            pages: [],          // new field — include it
            currentPageId: ""   // new field — include it
        ),
        onSwipePage: { _ in },
        onTapGetStarted: {}
    )
}
```

## Compose (`@Preview`)

```kotlin
// ✅ After adding a field to State:
@Preview
@Composable
fun OnboardingScreenPreview() {
    OnboardingScreen(
        state = OnboardingViewModel.State(
            primaryButtonTitle = "Get Started",
            pages = emptyList(),      // new field
            currentPageId = "",       // new field
        ),
        onSwipePage = {},
        onTapGetStarted = {},
    )
}
```

## Preview helpers (`+Preview` files) count too

Presentation **State models** have companion preview factories — `previewSingle()` / `previewList()` — living in a sibling `{ModelName}+Preview.kt` file (see `state-model-preview-helpers`). When you change a State model's fields, you must update **both**:

1. The inline `#Preview` / `@Preview` blocks that construct the State (above).
2. Every `previewSingle()` / `previewList()` / variant in the model's `+Preview` file — they construct the model directly and will fail to compile if a field is added, removed, or renamed.

Treat the `+Preview` file as part of the same edit, never a follow-up.

## Rules

- Named arguments in previews must stay in sync with the `State` data class signature.
- If a new field has no sensible default, supply a representative stub value in the preview.
- Never leave a preview with a stale / missing field — it will fail to compile.
- The same applies to `{ModelName}+Preview.kt` helper files — update them in lockstep with the State model.
