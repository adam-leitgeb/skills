---
name: state-model-preview-helpers
description: Generate preview helper factories (.previewSingle() / .previewList()) for KMP presentation State models, in a separate +Preview file, so SwiftUI and Compose previews can construct realistic sample state. Use when creating or editing a presentation State / UI-state model (e.g. *State, *Model classes consumed by Views/Screens/previews).
user-invocable: false
---

# Preview Helpers for Presentation State Models

Every presentation **State model** — the immutable `data class`es that back a SwiftUI/Compose view (`*State`, `*Model`, row/tile/header states, etc.) — gets a pair of preview helper factories so previews never have to hand-build sample state:

- `previewSingle()` → one representative instance
- `previewList()` → a `List` of varied instances (different field values, edge cases, long text, empty collections) — for list-rendered models only, see hard rule 4

These are consumed by SwiftUI `#Preview` blocks and Compose `@Preview` functions, on both platforms, from the shared module.

## Hard rules

1. **No parameters — ever.** Kotlin default arguments do **not** survive the Kotlin→Swift export, so a helper like `previewSingle(title: String = "Hi")` becomes an argument-required, awkward call from Swift. Preview helpers take **zero arguments**. If you need a variant, add another named zero-arg helper (e.g. `previewLongTitle()`, `previewEmpty()`) instead of a parameter with a default. This rule is about the helpers only — defaulted constructor parameters on the State model itself (`val title: String = FeatureStrings.title()`) are the convention and stay; don't "fix" them.

2. **Separate `+Preview` file.** Helpers never live in the same file as the State model. They go in a sibling file named after the model with a `+Preview` suffix:

   - Model:   `ResultTileState.kt`
   - Helpers: `ResultTileState+Preview.kt`

   Same package, same directory.

3. **`companion object` must exist on the model.** The helpers are extensions on the model's companion (`fun ResultTileState.Companion.previewSingle()`), so the model needs a `companion object` declared. If the model has no companion members, an empty `companion object` is enough. For a **sealed** model (a whole-screen `State` with variants), the companion goes on the **sealed base**, not on each variant — `data object` variants can't declare a companion at all — and each factory returns a concrete variant: `fun State.Companion.previewContent(): State.Content`.

4. **Create both** `previewSingle()` and `previewList()` for models the UI renders as a collection — row, tile, item states. A whole-screen ViewModel `State` is never rendered as a list: give it `previewSingle()` plus a named zero-arg variant per screen mode (`previewSending()`, `previewError()`, …) and skip `previewList()`. Add extra named variants as the UI needs them.

## File template

`{package}` below is a placeholder for the project's own root package — use the actual
one (read it from any existing source file), never a hardcoded vendor package.

`ResultTileState+Preview.kt`:

```kotlin
package {package}.features.result.presentation

import {package}.library.design.color.ThemeColors
import {package}.library.design.icon.AppIcon

/**
 * Preview helpers for [ResultTileState].
 * Used by SwiftUI / Jetpack Compose previews. No parameters — Kotlin default
 * args don't survive the Swift export, so each variant is its own zero-arg helper.
 */
fun ResultTileState.Companion.previewSingle(): ResultTileState = ResultTileState(
    title = "Correct",
    value = "25",
    icon = AppIcon.Result.CHECKMARK,
    tint = ThemeColors.green400,
)

fun ResultTileState.Companion.previewList(): List<ResultTileState> = listOf(
    ResultTileState(
        title = "Correct",
        value = "48",
        icon = AppIcon.Result.CHECKMARK,
        tint = ThemeColors.green400,
    ),
    ResultTileState(
        title = "Incorrect",
        value = "2",
        icon = AppIcon.Result.MISTAKE_X,
        tint = ThemeColors.red200,
    ),
    ResultTileState(
        title = "Skipped",
        value = "0",
        icon = AppIcon.Result.SKIPPED,
        tint = ThemeColors.textTertiary,
    ),
)
```

The model file just declares the companion:

```kotlin
data class ResultTileState(
    val title: String,
    val value: String,
    val icon: AppIcon,
    val tint: ColorId = ThemeColors.textPrimary,
) {
    companion object
}
```

## Consuming the helpers in previews

**SwiftUI** — call through `.companion`, with leading-dot inference wherever the
parameter type is known: the type name never appears, so the preview survives a
rename. Spell the type out only where inference can't reach it (as in the `ForEach`
below):

```swift
#Preview {
    ResultTile(state: .companion.previewSingle())
}

#Preview("List") {
    VStack {
        ForEach(ResultTileState.companion.previewList(), id: \.title) { state in
            ResultTile(state: state)
        }
    }
}
```

**Compose** — import the extension and call on the companion:

```kotlin
import {package}.features.result.presentation.previewSingle

@Preview(showBackground = true)
@Composable
private fun ResultTilePreview() {
    ResultTile(state = ResultTileState.previewSingle())
}
```

## Keep helpers in sync with the model

When you add, remove, or rename a property on a State model, **update its `+Preview` file in the same change** — every `previewSingle()` / `previewList()` / variant must construct the new shape or the shared module won't compile. This is the State-model counterpart to keeping the actual `#Preview` / `@Preview` blocks in sync (see `sync-previews-with-state`).

## Naming reference

| Item | Convention | Example |
|------|-----------|---------|
| Single instance | `previewSingle()` | `ResultTileState.previewSingle()` |
| Collection | `previewList()` | `ResultTileState.previewList()` |
| Extra variant | `preview{Variant}()` | `previewLongTitle()`, `previewEmpty()` |
| Helper file | `{ModelName}+Preview.kt` | `ResultTileState+Preview.kt` |

## Migrating older `mock()` helpers

Earlier code used `mock()` / `mockList()`. When you touch such a file, rename to `previewSingle()` / `previewList()`, move the helpers into a `{ModelName}+Preview.kt` file, drop any parameters, and update the SwiftUI/Compose call sites.
