---
name: new-kmp-feature-shared-only
description: Scaffold only the shared (commonMain) half of a new KMP feature from screenshots of the design — ViewModel, State, use cases, repository, DI, scene wiring — plus empty but buildable iOS and Android views.
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

**Read the frames before asking anything** (§2.1). They usually settle the first
question below on their own — a control that leaves the screen means
`NavigationViewModel`. Then ask **only what is still open**, and at most these two:

1. **Does the screen navigate away?** → `NavigationViewModel<State>` vs
   `BaseViewModel<State>`. Ask only if there are no frames, or none of them shows a
   way off the screen and the prose doesn't say either.
2. **Where does its data come from?** — an existing repository/API, a new one, or
   nothing yet. Frames rarely answer this one.

Anything else you can't infer becomes a `TODO` in the scaffold, not a question.

## 2. Build the shared module in full

Do every step of `new-kmp-feature` §1 (feature directories, ViewModel + `State`,
`+Preview` factories, use cases, repository, DI module, `featureModule.kt`
registration) and §2 (scene in `AppScene.kt`, Android `mapToDestination.kt`, the
three iOS `AppScene*.swift` files, analytics key if the project has analytics).

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
(see `localization-kmp`). A new feature means a new namespace, so **register it in
`localizationNamespaces` in `shared/build.gradle.kts`** — without that entry the
codegen emits no `{FeatureName}Strings` and §4's build fails on unresolved
references. With screenshots, that is most of the screen's copy —
`kmp-viewmodel-state` requires visible copy to be a *stored* field with a localized
default, so it lands in this phase, not the next one. Only copy you can't read
anywhere — a message behind an error you're stubbing — waits for phase two.

### 2.1 Reading the screenshots

The frames tell you the presentation layer. Read all of them before writing the
`State`; a second frame of the same screen is usually a second rendering, not a
second screen.

**Frames → state shape.** Classify each frame with `kmp-viewmodel-state`'s boxed
test — *"While this is true, can the user still see and use the content?"* — a
spinner or error frame fails it (sealed variant), a dimmed button or inline
spinner passes it (status on the content state). Disabled/enabled pairs of the
same frame are a derived property, not a stored `isEnabled` (same skill, "Store
input, derive presentation").

**Content → fields.** Anything that could differ per user or per load — labels,
values, counts, avatars, badge text — is a `State` field. Repeated rows become
their own row state model with `previewSingle()` / `previewList()`
(`state-model-preview-helpers`). Static copy is still a field, per the rule above.

**Controls → actions.** Every tappable element is an `on{Action}()` on the
ViewModel. Name it for what it does, not for the control that triggers it
(`onConfirmPayment()`, not `onTapButton()`). A control that leaves the screen means
`NavigationViewModel` and a `navigate()` call — this is what settles §1's first
question. A destination you can see in another frame gets a real `NavigationState`
case; one you can't, a `TODO`.

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

Use `new-kmp-feature` §3.1's template verbatim — its placeholder `Content` body is
already exactly the placeholder this phase wants, so add nothing to it. Drop
`.handleNavigation` if the ViewModel is a plain `BaseViewModel` (`new-kmp-feature`
Tip 4), same as `HandleNavigation` on Android below.

The template's `#Preview` builds state with `.companion.previewSingle()` — the
factory §2 already created. Don't swap it for a bare `State(...)` initializer: a
sealed `State` has no callable constructor, and a growing one breaks the preview
on every added field. Call conventions live in `state-model-preview-helpers`.

Register the ViewModel in `KoinDependencies.kt` (§3.2) — without it the view can't
resolve and iOS won't build.

### Android — `composeApp/src/androidMain/.../features/{feature_name}/{FeatureName}Screen.kt`

Use the `Screen` half of `android-implementation-from-ios`'s screen-structure
template as is, with two phase-one adjustments: drop `HandleNavigation` if the
ViewModel is a plain `BaseViewModel`, and call this placeholder `Content` with
only the state — drop the `onAction*` arguments the template's `Screen` wires:

```kotlin
@Composable
private fun Content(state: {FeatureName}ViewModel.State) {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Text(text = "{FeatureName}")
    }
}
```

Register the route in `app/App.kt` against the `{FeatureName}Scene` object that
`mapToDestination.kt` declares (`new-kmp-feature` §2.2 explains the mapping):

```kotlin
composable<{FeatureName}Scene> {
    {FeatureName}Screen(navController = navController)
}
```

**Do not** wire the state into either placeholder beyond passing it in. Reading
fields now means rewriting them in phase two.

## 4. Verify it builds

Compiling is the deliverable — a scaffold that doesn't build is worse than none.
Android first: `assembleDebug` compiles the shared module's common and Android
halves transitively.

```bash
./gradlew :composeApp:assembleDebug
```

Then iOS. **If the project has an Xcode scheme, build the app in Xcode** — that is
the only step that compiles the Swift this skill had you write (the three
`AppScene*.swift` cases and the placeholder view), and it links the framework
itself, so the standalone Gradle link task adds nothing on top of it. Run the link
task on its own **only** when you can't build in Xcode (no scheme, not on macOS);
it still runs the Kotlin→Swift export the ViewModel has to survive, but it checks
no Swift:

```bash
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64
```

Don't reach for `:shared:build` in either case — it also links release frameworks
for every iOS target and runs the full test suite, minutes of work that verify
nothing about a scaffold. If a task name doesn't resolve, check
`settings.gradle.kts` for the real module names and `shared/build.gradle.kts` for
the target that declares `binaries.framework` — a CocoaPods or XCFramework setup
names the link task differently.

Report what you actually ran and what passed, and say which iOS path you took; if
a build fails for a reason outside the feature (missing SDK, unrelated breakage),
say so rather than declaring success.

Two export rules to re-check at this step:

- **Status types belong at top level** — nested inside `State` or the ViewModel
  they flatten into a concatenated name in Swift; top level they stay
  `SubmitStatus.Failed`. The mechanism — and why `{FeatureName}ViewModel.State`
  itself is fine — is `kmp-viewmodel-state`, "Status".
- **Preview helpers take no parameters** — and the deliberate flip side: defaulted
  constructor params on `State` itself are the convention and stay. Both halves
  are `state-model-preview-helpers`, hard rule 1.

## 5. Hand off

Close with a short summary, not a wall of text:

- **Read from the frames** — the renderings, status and actions you inferred, one
  line each, plus any ambiguity you resolved by choosing. This is the part worth
  checking; everything below it is mechanical.
- **Created** — the shared files, grouped by layer.
- **Registered** — every registration site from `new-kmp-feature` (§1.7, §2, §3.2,
  and the `App.kt` route from §4.1), confirmed by name.
- **Left open** — every `TODO` you planted, and the copy still missing from
  `localization.json`.
- **Next** — the two placeholder views to replace, by path.

Phase two is `ios-swiftui-patterns` for the iOS screen, then
`android-implementation-from-ios` to mirror it.

## Checklist

- [ ] Every supplied frame accounted for — as a rendering, a status, or a deliberate skip
- [ ] Each visible control has an `on{Action}()`; each varying element has a field
- [ ] Visible copy stored on `State` with keys in `localization.json`, namespace registered in `localizationNamespaces`
- [ ] `State` (or its sealed base) declares `companion object`; Swift previews call `.companion.previewX()`
- [ ] No spacing/color/typography leaked into shared code
- [ ] Shared feature complete per `new-kmp-feature` §1, `State` shaped per `kmp-viewmodel-state` — nothing stubbed that the request specified
- [ ] Every registration done — `new-kmp-feature`'s §5 verification checklist passes
- [ ] iOS view: lifecycle modifiers present (`.handleNavigation` iff `NavigationViewModel`), `Content` still a placeholder
- [ ] Android screen: registered in `App.kt`, `Content` still a placeholder
- [ ] Neither placeholder reads `state` fields
- [ ] `:composeApp:assembleDebug` passed, plus the iOS side — Xcode build, or the link task alone where Xcode isn't available — and which path you took is reported
