---
name: android-implementation-from-ios
description: Port a finished iOS SwiftUI screen to Android Jetpack Compose, matching its structure and behavior. Use when implementing the Android side of a feature whose shared code and iOS UI already exist.
user-invocable: false
---

# Android Implementation from iOS

**iOS is the source of truth.** The shared ViewModel and the SwiftUI screen already
exist; your job is to produce the Compose screen that mirrors the iOS one — same
structure, same state, same behavior. Read the whole iOS view first, then translate.

> **Design system assumption.** This targets a project with a shared design system:
> `Spacing` constants, `AppTypography`, `ThemeColors`, `AppIcon`, and `CO*` components
> (`COScaffold`, `COPrimaryButton`, `COTextField`, …). If a project doesn't have one
> yet, map these to Material 3 directly with shared design *tokens* — the structural
> guidance below still applies.

## Workflow

1. **Read the iOS view** — `iosApp/iosApp/Features/{FeatureName}/{FeatureName}View.swift`.
   Note the `Content` struct's layout, the state fields it reads, and the callbacks.
2. **Create the screen** — `composeApp/src/androidMain/.../features/{feature_name}/{FeatureName}Screen.kt`.
3. **Mirror the structure** using the template and translation tables below.
4. **Register navigation** (see [Navigation](#navigation)).
5. Build; the shared ViewModel and its `State` compile-check most mismatches.

## Screen structure

Split exactly like iOS's `FeatureView` (lifecycle) / `Content` (UI):

```kotlin
@Composable
fun {FeatureName}Screen(navController: NavController) {
    val viewModel: {FeatureName}ViewModel = koinViewModel()
    val state by viewModel.states.collectAsStateWithLifecycle()

    HandleNavigation(viewModel, navController)   // NavigationViewModel only — drop for a plain BaseViewModel (mirrors iOS .handleNavigation)

    LaunchedEffect(Unit) {                       // mirrors iOS .onAppear(perform:)
        viewModel.onAppear()
    }

    Content(
        state = state,
        onAction1 = { viewModel.onAction1() },
        onAction2 = { viewModel.onAction2(it) },
    )
}

@Composable
private fun Content(
    state: {FeatureName}ViewModel.State,
    onAction1: () -> Unit,
    onAction2: (String) -> Unit,
) {
    COScaffold(title = {FeatureName}Strings.title(), showBackButton = /* iOS .navigationBarHidden(false) */ true) { padding ->
        // UI matching the iOS Content struct, using `padding`
    }
}
```

Rules:
- Top-level `Screen`: ViewModel injection + lifecycle **only**. No `COScaffold` here.
- `Content`: holds `COScaffold` and the UI; receives `state` + callbacks as params.
- Call `onAppear()` from `LaunchedEffect(Unit)`, and collect with
  `collectAsStateWithLifecycle()` rather than `collectAsState()`.
- `HandleNavigation` mirrors iOS `.handleNavigation`: present iff the ViewModel is
  a `NavigationViewModel` (`new-kmp-feature` Tip 4).

> **A note on `LaunchedEffect(Unit)`.** It fires when the screen enters composition
> and re-fires when the screen re-enters after back navigation — the same moments
> SwiftUI fires `.onAppear`. Both are parity with iOS, so don't add delays or
> one-shot guards to "match" it. If a screen ever genuinely needs fully-visible,
> post-animation timing, add a shared lifecycle helper for it; don't hand-roll one
> in a single feature.

## Translation tables

### Layout & components

| iOS (SwiftUI) | Android (Compose) |
|---|---|
| `VStack` / `HStack` | `Column` / `Row` |
| `LazyVStack` / `LazyHStack` | `LazyColumn` / `LazyRow` |
| `ScrollView` | `Column` + `verticalScroll(rememberScrollState())`, or `LazyColumn` |
| `ForEach` | `items(list, key = { it.id })` in a lazy list |
| `Spacer()` | `Spacer(Modifier.weight(1f))` |
| `.padding(.horizontal)` | `.padding(horizontal = Spacing.XXS)` |
| `.safeAreaInset(edge: .bottom)` | `Box` child aligned `Alignment.BottomCenter` |

### Design tokens

| iOS | Android |
|---|---|
| `.spacingBasicXXS` … | `Spacing.XXS` … (same scale: XXXXXS=2dp, XXXS=8, XXS=16, XS=20, S=24, M=32, L=40, XL=48, XXL=64) |
| `.coTextTitle1()` … `.coTextBodyM()` … | `AppTypography.title1` … `AppTypography.bodyM` … |
| `ThemeColors.shared.textPrimary.color` | `ThemeColors.textPrimary.toComposeColor()` |
| `Image(systemName:)` / custom image | `rememberAppIconPainter(AppIcon.…)` |

### Shared components

Design-system components (`CO*`) and common views exist on both platforms with
matching names — e.g. `COPrimaryButton`, `COScaffold`, `COAlertDialog`, `CODivider`,
`SelectableRow`, `RaisedButton`. The exact set varies per project, so **check what
exists** (grep `library/design/views` and `common/views`) before building new UI.

## Key API differences

- **Callbacks:** iOS `action:` / closures → Compose `onClick:` / lambdas.
- **Strings:** iOS `FeatureStrings.PrimaryButton().confirm()` → Compose
  `FeatureStrings.PrimaryButton.confirm()` (direct object, no `.shared`/`()`).
- **Uppercasing:** iOS `.uppercased()` → Compose `.uppercase()`.
- **`PaddingValues`:** cannot mix `horizontal`/`vertical` with a single edge. Use
  explicit edges when you need a different bottom: `PaddingValues(start = …, top = …, end = …, bottom = 80.dp)`.
- **Lazy lists:** always pass `key = { it.id }` to `items(...)`.

### Bottom button (iOS `safeAreaInset`)

```kotlin
Box(Modifier.fillMaxSize()) {
    LazyColumn(contentPadding = PaddingValues(start = Spacing.XXS, top = Spacing.M, end = Spacing.XXS, bottom = 80.dp)) {
        items(state.items, key = { it.id }) { ItemRow(it) }
    }
    Box(Modifier.align(Alignment.BottomCenter).fillMaxWidth().padding(horizontal = Spacing.XXS).padding(bottom = Spacing.S)) {
        COPrimaryButton(title = Strings.PrimaryButton.confirm(), onClick = onConfirm)
    }
}
```

## Decomposition

Match iOS's view breakdown. Extract a `private @Composable` when a block exceeds
~50–100 lines, repeats (list items), or is a distinct section. Keep them all `private`.

- Sections → `{Name}Section` (e.g. `HeaderSection`)
- Rows/items → `{Name}Row` (e.g. `MistakeRow`)
- Helpers → descriptive (e.g. `VerticalDivider`)
- Group with `// MARK: -` comments, matching the iOS file's organization. No other
  comments — `code-comments` applies, judged against the Kotlin code (don't mirror
  iOS comments that don't meet it).

## Navigation

Register the screen in `composeApp/src/androidMain/.../app/App.kt`:

```kotlin
composable<{FeatureName}Scene> { {FeatureName}Screen(navController = navController) }
```

The `{FeatureName}Scene` route object is declared in
`.../library/navigation/mapToDestination.kt` and should already exist from the iOS
side (`new-kmp-feature` §2.2 explains the mapping and the `Scene` suffix).

## Verification checklist

- [ ] `Screen` holds only ViewModel + lifecycle; `Content` holds `COScaffold` + UI.
- [ ] `onAppear()` called via `LaunchedEffect(Unit)`; `HandleNavigation` present iff the ViewModel is a `NavigationViewModel`.
- [ ] Layout, spacing, typography, colors, icons use the shared tokens (no hardcoded values).
- [ ] Component props translated (`onClick` not `action`; direct string access).
- [ ] Lazy `items(...)` have `key`; bottom buttons use `Alignment.BottomCenter` with matching content padding.
- [ ] Screen registered in `App.kt`; back button shown iff iOS shows one.
- [ ] Complex UI decomposed into `private` composables, matching the iOS breakdown.

## Reference files

- iOS: `iosApp/iosApp/Features/{FeatureName}/{FeatureName}View.swift`
- Android: `composeApp/src/androidMain/.../features/{feature_name}/{FeatureName}Screen.kt`
- Shared: `shared/src/commonMain/.../features/{feature_name}/presentation/` (ViewModel; strings come from the generated `{FeatureName}Strings` facade — see `localization-kmp`)

Look at an already-ported screen (e.g. `LearnScreen.kt`) for the decomposition style.
