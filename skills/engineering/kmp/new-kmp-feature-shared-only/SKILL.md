---
name: new-kmp-feature-shared-only
description: Scaffold only the shared (commonMain) half of a new KMP feature — ViewModel, State, use cases, repository, DI, scene wiring — from screenshots of the design, plus empty but buildable iOS and Android views. Use when the UI will be built later.
argument-hint: "<feature name> + screenshots of the frames — e.g. Payment Method"
disable-model-invocation: true
---

# New KMP Feature — Shared Only

Phase one of a two-phase feature. You build **all of the shared code** — usually
derived from screenshots of the design — and stop at the platform views: iOS and
Android each get a placeholder screen that compiles, navigates, and renders nothing
but the feature name. The real UI lands later, from those same frames.

Follow **`new-kmp-feature`** for every file's location, template, and registration —
this skill does not restate them. What follows is only the delta: what to build in
full, what to leave empty, and how to prove it builds.

## 1. Inputs

Take the feature name from the invocation argument. If none was given, ask for it.

Expect **screenshots** — frames exported from Figma — alongside it. They are the
spec for the presentation layer; §2.1 covers how to read them. If none were
attached, ask whether there are any before scaffolding from prose, but don't block:
a described feature scaffolds fine, just with more `TODO`s.

Derive, per `new-kmp-feature`'s naming table:
- `{feature_name}` — snake_case directory / package segment
- `{FeatureName}` — PascalCase class prefix
- `{featureName}` — camelCase DI module and Koin property

Then ask **only these two**, and only if the request doesn't already answer them:

1. **Does the screen navigate away?** → `NavigationViewModel<State>` vs `BaseViewModel<State>`.
2. **Where does its data come from?** — an existing repository/API, a new one, or nothing yet.

Anything else you can't infer becomes a `TODO` in the scaffold, not a question.

## 2. Build the shared module in full

Do every step of `new-kmp-feature` §1 (feature directories, ViewModel + `State`,
`+Preview` factories, use cases, repository, DI module, `featureModule.kt`
registration) and §2 (scene in `AppScene.kt`, Android `mapToDestination.kt`, the
three iOS `AppScene*.swift` files, analytics key).

**How complete should the shared code be?** As complete as the request allows:

- Behavior the user described → implement it for real. A `State` shaped per
  `kmp-viewmodel-state`, use cases with real bodies, repository calls, error
  taxonomy, `onAppear()` doing the actual load.
- Behavior the user didn't describe → the `TODO`-stub templates from
  `new-kmp-feature`. Don't invent product decisions to fill them.

The point of splitting the phases is that the shared half is *finished*, not that
it's thinner. When the design arrives, phase two should be writing views against a
State that already holds everything they need.

**Strings.** Every string the `State` carries needs a key in `localization.json`
(see `localization-kmp`). With screenshots, that is most of the screen's copy —
`kmp-viewmodel-state` requires visible copy to be a *stored* field with a localized
default, so it lands in this phase, not the next one. Only copy you can't read
anywhere — a message behind an error you're stubbing — waits for phase two.

### 2.1 Reading the screenshots

The frames tell you the presentation layer. Read all of them before writing the
`State`; a second frame of the same screen is usually a second rendering, not a
second screen.

**Frames → state shape.** Apply `kmp-viewmodel-state`'s test to each frame: if the
content isn't on screen (spinner, empty, error), it's a sealed variant; if the
content is there and only affordances changed (a dimmed button, an inline spinner,
a validation message under a filled field), it's a status on the content state.
Disabled/enabled pairs of the same frame are almost always a derived property, not
a stored `isEnabled`.

**Content → fields.** Anything that could differ per user or per load — labels,
values, counts, avatars, badge text — is a `State` field. Repeated rows become
their own row state model with `previewSingle()` / `previewList()`
(`state-model-preview-helpers`). Static copy is still a field, per the rule above.

**Controls → actions.** Every tappable element is an `on{Action}()` on the
ViewModel. Name it for what it does, not for the control that triggers it
(`onConfirmPayment()`, not `onTapButton()`). A control that leaves the screen means
`NavigationViewModel` and a `navigate()` call — which answers question 1 in §1
without asking. A destination you can see in another frame gets a real
`NavigationState` case; one you can't, a `TODO`.

**Ignore the pixels.** Spacing, colors, typography, corner radii and asset names
are phase two's problem — they belong to the views, and nothing about them belongs
in shared code. Extract structure and behavior only.

State what you inferred in the hand-off (§5) so a misread frame is easy to spot and
correct. When a frame is genuinely ambiguous — is that empty list a variant or just
a screenshot of no data? — pick the reading `kmp-viewmodel-state` implies, note it,
and move on rather than stopping to ask.

## 3. Leave the views empty

Both platform views exist so the app builds and the scene routes. They render a
single placeholder and nothing else — no layout, no design tokens, no components.

### iOS — `iosApp/iosApp/Features/{FeatureName}/{FeatureName}View.swift`

Use `new-kmp-feature` §3.1's template verbatim (`@StateViewModel`, `.onAppear`,
`.handleNavigation`, private `Content`, `#Preview`), keeping its placeholder body:

```swift
private struct Content: View {
    let state: {FeatureName}ViewModel.State

    var body: some View {
        VStack {
            Text("{FeatureName}")
                .font(.title)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

If `State` is sealed, the `#Preview` uses a `+Preview` factory
(`{FeatureName}ViewModel.State.Content.companion.previewSingle()`), not a bare
initializer — that keeps the preview compiling as the state grows.

Register the ViewModel in `KoinDependencies.kt` (§3.2) — without it the view can't
resolve and iOS won't build.

### Android — `composeApp/src/androidMain/.../features/{feature_name}/{FeatureName}Screen.kt`

Same split as `android-implementation-from-ios` (`Screen` = injection + lifecycle,
`Content` = UI), with a placeholder `Content`:

```kotlin
@Composable
fun {FeatureName}Screen(navController: NavController) {
    val viewModel: {FeatureName}ViewModel = koinViewModel()
    val state by viewModel.states.collectAsState()

    HandleNavigation(viewModel, navController)   // only if NavigationViewModel
    OnLifecycleStart { viewModel.onAppear() }

    Content(state = state)
}

@Composable
private fun Content(state: {FeatureName}ViewModel.State) {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Text(text = "{FeatureName}")
    }
}
```

Register the route in `App.kt`: `composable<{FeatureName}> { {FeatureName}Screen(navController = navController) }`.

**Do not** wire the state into either placeholder beyond passing it in. Reading
fields now means rewriting them in phase two.

## 4. Verify it builds

Compiling is the deliverable — a scaffold that doesn't build is worse than none.
Run the project's own wrapper; task names vary, so check `settings.gradle.kts` for
the real module names before assuming `:shared` / `:composeApp`:

```bash
./gradlew :shared:build :composeApp:assembleDebug
```

For iOS, the ViewModel has to survive the Swift export — link the framework:

```bash
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64
```

then build the Xcode project if the project has a scheme for it. Report what you
actually ran and what passed; if a build fails for a reason outside the feature
(missing SDK, unrelated breakage), say so rather than declaring success.

Watch for the export traps that only surface here: default arguments and nested
sealed types don't cross into Swift cleanly — see `state-model-preview-helpers` and
`kmp-viewmodel-state`.

## 5. Hand off

Close with a short summary, not a wall of text:

- **Read from the frames** — the renderings, status and actions you inferred, one
  line each, plus any ambiguity you resolved by choosing. This is the part worth
  checking; everything below it is mechanical.
- **Created** — the shared files, grouped by layer.
- **Registered** — `featureModule.kt`, `AppScene` (all three), `KoinDependencies`,
  `App.kt`, analytics.
- **Left open** — every `TODO` you planted, and the copy still missing from
  `localization.json`.
- **Next** — the two placeholder views to replace, by path.

Phase two is `ios-swiftui-patterns` for the iOS screen, then
`android-implementation-from-ios` to mirror it.

## Checklist

- [ ] Every supplied frame accounted for — as a rendering, a status, or a deliberate skip
- [ ] Each visible control has an `on{Action}()`; each varying element has a field
- [ ] Visible copy stored on `State` with keys in `localization.json`
- [ ] No spacing/color/typography leaked into shared code
- [ ] Shared feature complete per `new-kmp-feature` §1 — nothing stubbed that the request specified
- [ ] `State` shaped per `kmp-viewmodel-state`; `+Preview` factories exist
- [ ] Scene registered in shared, Android, and all three iOS files; analytics key added
- [ ] ViewModel in `KoinDependencies`; module in `featureModule.kt`
- [ ] iOS view: template modifiers present, `Content` still a placeholder
- [ ] Android screen: registered in `App.kt`, `Content` still a placeholder
- [ ] Neither placeholder reads `state` fields
- [ ] Gradle + iOS link verified, results reported honestly
