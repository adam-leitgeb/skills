---
paths:
  - "**/*ViewModel.kt"
  - "**/*State.kt"
---

# ViewModel State

How a screen's state is shaped, so it stays predictable as the screen grows.
Structure, naming and layering live in `kotlin-multiplatform-architecture`;
scaffolding a new feature lives in `new-kmp-feature`.

Type names below are placeholders — `{FeatureName}`, `SubmitStatus`, `ButtonState`.
Use the project's own equivalents.

## The two axes

Sealed state and a status field answer different questions. Most non-trivial
screens need both.

Apply this test to whatever condition you are modelling:

> **While this is true, can the user still see and use the content?**

- **No** → a **sealed `State` variant**. Fields that don't exist yet shouldn't be
  declared yet.
- **Yes** → a **status field on the content state**. The content stays on screen;
  only affordances change.

| Condition | Content visible? | Shape |
|---|---|---|
| Data loading | no | sealed variant |
| Load failed | no | sealed variant |
| Nothing to show | no | sealed variant (`Empty`) |
| Submit / send in flight | yes | status field |
| Submit failed, form still shown | yes | status field |

Second phrasing, useful on an existing state class: *would some fields be
meaningless in this condition?* If yes it's a rendering; if every field still makes
sense and only affordances change, it's a status.

### Sealed — exclusive renderings

```kotlin
sealed class State : ViewModelState {
    data object Loading : State()
    data class Error(val model: ErrorStateModel) : State()
    data class Empty(val model: EmptyStateModel) : State()
    data class Content(
        val title: String = FeatureStrings.title(),
        val rows: List<RowState> = emptyList(),
    ) : State()
}
```

Guard actions by narrowing, and return when the screen has moved on:

```kotlin
fun onSelectRow(id: String) {
    val content = state as? State.Content ?: return
    state = content.copy(selectedId = id)
}
```

### Status — an operation over visible content

```kotlin
sealed class SubmitStatus {
    data object Idle : SubmitStatus()
    data object Submitting : SubmitStatus()
    data object Submitted : SubmitStatus()
    data class Failed(val message: String, val isInputInvalid: Boolean) : SubmitStatus()
}
```

Declare it **top level** in the presentation package, not nested in `State` or the
ViewModel. Top level it stays `SubmitStatus.Failed` in Swift; nested inside `State`
it reaches Swift as a flattened concatenation
(`{FeatureName}ViewModelStateSubmitStatusFailed`).

> **Why.** The Obj-C export preserves **one level** of class nesting —
> `{FeatureName}ViewModel.State` keeps its dotted path, which is what the SwiftUI
> `Content` struct declares — and flattens anything deeper (a status inside `State`
> or the ViewModel puts its members at depth two). Members of a *sealed interface*
> flatten at any depth: an interface exports as an Obj-C protocol, which cannot
> nest types, so `TemplateAppScene.Initial` arrives as `TemplateAppSceneInitial` —
> which is why `AppScene+Convertible.swift` matches on `case is TemplateAppSceneInitial`.

### Both together

The normal end state for a screen that loads *and* submits:

```kotlin
data class Content(
    val rows: List<RowState> = emptyList(),
    val submit: SubmitStatus = SubmitStatus.Idle,
) : State()
```

## One status, never a set of booleans

The failure mode this skill exists to prevent: one lifecycle tracked in several
places at once, kept consistent by hand.

```kotlin
// ✗ four representations of "where is this request"
private var isSubmitting = false
data class State(
    val isLoading: Boolean = false,
    val isSubmitted: Boolean = false,
    val submitButton: ButtonState,   // carries its own isLoading / isEnabled
)
```

Every action has to update all of them, a `finally` ends up reading state back to
decide whether to undo its own write, and they drift apart. Replace with one status
and derive the rest.

**You picked the wrong axis when:**

- *Sealed where a status belonged* — the sealed base grows `open val`s, or two
  variants declare nearly the same fields. The concern was orthogonal to the
  variants, so it leaked upward.
- *Status where sealed belonged* — the state fills with nullables that are only
  non-null after a load, and the UI writes `if (x != null)` to decide what to draw.
  A failed load then leaves a half-rendered screen with live controls.

## Store input, derive presentation

State stores what the user typed or chose, plus the status. Everything the UI
renders is a computed `val`.

```kotlin
data class State(
    val input: String = "",
    val status: SubmitStatus = SubmitStatus.Idle,
    val onSubmitTap: () -> Unit = {},
) : ViewModelState {

    val submitButton: ButtonState
        get() = ButtonState(
            title = FeatureStrings.submit(),
            isLoading = status is SubmitStatus.Submitting,
            isEnabled = status !is SubmitStatus.Submitting && status !is SubmitStatus.Submitted,
            onTap = onSubmitTap,
        )
}
```

Derived values cannot drift from the status, and actions collapse to one
assignment:

```kotlin
fun onInputChanged(input: String) {
    state = state.copy(input = input, status = statusAfterInput())
}
```

Callbacks are ordinary state fields, wired once in `init` and passed into the
derived sub-states.

**Don't derive copy.** Screen-level strings stay stored fields with localized
defaults:

```kotlin
val title: String = FeatureStrings.title(),
```

The localization facade returns the key itself when the string map isn't loaded, and
it is never loaded in a preview — so text resolved inside a computed getter renders as
a raw key in every Compose/SwiftUI preview. Stored fields let `+Preview` helpers pass
literals (see `state-model-preview-helpers`).

This applies to **derived sub-states too**: a string resolved inside the
`phoneNumberRow`-style getter above is just as unreachable by a preview factory. Store
the copy on `State` and pass it into the derived value:

```kotlin
data class State(
    val submitTitle: String = FeatureStrings.submit(),   // preview can override
    val status: SubmitStatus = SubmitStatus.Idle,        // preview can vary
) : ViewModelState {
    val submitButton: ButtonState
        get() = ButtonState(title = submitTitle, isLoading = status is SubmitStatus.Submitting, …)
}
```

A computed getter resolving copy is correct only for fields no preview renders — see
`localization-kmp` for the load-ordering side of the same rule.

**Avoid rebuild helpers with defaulted parameters.** A
`private fun row(errorMessage: String? = null)` that re-creates a sub-state silently
clears whatever the caller forgot to re-pass. Derive from the status instead.

## Writing the status

- **Set it synchronously in the action**, before launching, so the guard is the
  status itself and no extra in-flight flag is needed:

  ```kotlin
  fun onSubmit() {
      if (!state.submitButton.isEnabled) return
      state = state.copy(status = SubmitStatus.Submitting)
      viewModelScope.launch { submit() }
  }
  ```

- **One assignment per outcome.** No re-reading state to decide whether to undo a
  write.
- **`finally` only resets what never resolved:**

  ```kotlin
  } finally {
      // Still Submitting means no outcome was written — a stale result, or cancellation.
      if (state.status is SubmitStatus.Submitting) {
          state = state.copy(status = SubmitStatus.Idle)
      }
  }
  ```

- **Cancellation: return, never write.** Catch `CancellationException` before any
  broad `catch`, and `return@launch` — the ViewModel is going away.
- **Stale results.** When input can change mid-flight, compare the response against
  current input before applying it, and decide deliberately what "stale" means per
  outcome. A *failure* about input the user already replaced is noise and can be
  dropped. A *side effect that already happened* — a message sent, a payment taken —
  must still be recorded, or the user is left holding something the app has no record
  of and free to trigger it again.

## Errors

**Failure modes are a sealed taxonomy in the feature's domain layer** — not
booleans, not raw strings. Each case carries the *data* a caller needs to react,
never copy:

```kotlin
sealed class SubmitError {
    data object InvalidInput : SubmitError()
    data class RateLimited(val retryAfterSeconds: Int?) : SubmitError()
    data object Unavailable : SubmitError()
    data object Unknown : SubmitError()
}
```

**Copy lives in presentation.** Map the error to a message in a named extension in
the feature's presentation package — not as a private method inside the ViewModel —
so a second screen on the same use case reuses one mapping and it can be tested on
its own:

```kotlin
// presentation/SubmitError+Message.kt
fun SubmitError.toMessage(): String = when (this) {
    is SubmitError.RateLimited -> FeatureStrings.errorRateLimited(retryAfterSeconds ?: DEFAULT_RETRY)
    is SubmitError.InvalidInput -> FeatureStrings.errorInvalidInput()
    …
}
```

A domain type must never import from `presentation` — that inverts the
`presentation → domain → data` direction. Errors that reach for copy from inside
domain end up with hardcoded literals, because there is no localization machinery
there to use.

**New use cases return the failure rather than throwing it.** Kotlin has no checked
exceptions, so a thrown taxonomy is invisible at the call site and the catch list
can't be verified. Returning puts failure in the signature, collapses the ViewModel
to one expression, and leaves cancellation untouched:

```kotlin
sealed class DomainResult<out T, out E> {
    data class Success<out T>(val data: T) : DomainResult<T, Nothing>()
    data class Failure<out E>(val error: E) : DomainResult<Nothing, E>()
}

state = state.copy(
    status = when (val result = submit(input)) {
        is DomainResult.Success -> SubmitStatus.Submitted
        is DomainResult.Failure -> SubmitStatus.Failed(result.error.toMessage(), …)
    },
)
```

Existing throwing use cases are fine; migrate only with a reason.

## Conventions

- `State` is nested in the ViewModel and implements `ViewModelState`; sealed status
  types are top level in the same presentation package.
- Update with `state = state.copy(...)` — state is always immutable.
- Action naming and `// MARK: -` section sets: the rules live in `ui-conventions`.

## Smells

- A `private var` in a ViewModel that mirrors something already in state.
- Two fields that can contradict each other (`isLoading` + `isEnabled`).
- A `finally` block that reads state to decide what to write.
- Nullable state fields that are only non-null "after loading".
- A sealed base class accumulating `open val`s.
- A sub-state rebuilt by hand in more than one action.
- Error→copy mapping hidden as a private ViewModel method, or written out twice.
- A domain type importing anything from `presentation`.
