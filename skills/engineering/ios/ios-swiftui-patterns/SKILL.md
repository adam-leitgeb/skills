---
name: ios-swiftui-patterns
description: SwiftUI patterns for the iOS app in a KMP project — view structure, view models, KMP interop. Use when writing or editing SwiftUI.
paths:
  - "**/*.swift"
user-invocable: false
---

# iOS SwiftUI Patterns & Rules

## 🏗️ View Architecture

### Feature View Structure
All feature views must follow this consistent structure:

```swift
struct FeatureView: View {
    @StateViewModel var viewModel: FeatureViewModel = KoinDependencies().featureViewModel

    var body: some View {
        Content(state: viewModel.state)
            .onAppear(perform: viewModel.onAppear)
            .handleNavigation(viewModel)
    }
}

private struct Content: View {
    let state: FeatureViewModel.State

    var body: some View {
        // UI implementation
    }
}
```

Callbacks are closure fields **on the shared `State`** (`state.onSendTap`), wired once in
the ViewModel's `init` — see `kmp-viewmodel-state`. `Content` therefore usually takes only
`state`. When a State doesn't carry its callbacks (older screens), pass them into
`Content` as parameters instead; don't reach into `viewModel` from `Content` either way.

### Key Principles
- **Main View**: Contains ViewModel injection and lifecycle management
- **Private Content View**: Contains actual UI implementation, receives state (and, for older screens, callbacks) as parameters
- **State-driven UI**: All UI decisions based on ViewModel state
- **Callback Pattern**: Actions are closure fields on the shared State; older screens pass them from main view to content view as parameters
- **Separation of Concerns**: ViewModels handle logic, Views handle presentation

## 🔗 ViewModel Integration

### KMP ViewModel Connection
- Use `@StateViewModel` property wrapper for ViewModel injection
- Inject ViewModels through `KoinDependencies().featureViewModel`
- ViewModels are shared KMP code, not platform-specific

```swift
@StateViewModel var viewModel: FeatureViewModel = KoinDependencies().featureViewModel
```

### Required ViewModel Modifiers
Every feature view includes `.onAppear`; add `.handleNavigation(viewModel)` only
when the ViewModel is a `NavigationViewModel` — a plain `BaseViewModel` screen
takes neither navigation wiring (see `new-kmp-feature` Tip 4):
```swift
.onAppear(perform: viewModel.onAppear)
.handleNavigation(viewModel)   // NavigationViewModel only
```

Add an alert modifier **only** when the screen's State exposes a dedicated
dialog-style error field (a screen-blocking error, e.g. a failed load or purchase).
The full-featured shape is a derived `errorAlert: COAlertState?` (title, optional
message, actions such as a retry) rendered by `alert(_:onClose:)`:
```swift
.alert(viewModel.state.errorAlert, onClose: viewModel.state.onDismissErrorTap)
```
For a bare message with just a Close button there is also `.alert(error: String?,
onClose:)`. Screens whose errors render inline from state — e.g. a validation
message under a text field — need no alert modifier.

## 📱 Navigation

### Navigation Integration
- Use `.handleNavigation(viewModel)` on feature views backed by a `NavigationViewModel`
- Navigation state is handled automatically through `NavigationHandlerModifier`
- ViewModels emit navigation events through `navigationStatesFlow`
- Navigation is declarative based on ViewModel state

### Navigation State Handling
- Navigation destination typically exposed in ViewModel state
- Use switch statements to handle different navigation states:

```swift
switch state.navigationDestination {
case .loading:
    loadingState
case .nextScreen:
    NextScreenView()
case .maintenance:
    maintenanceState
default:
    EmptyView()
}
```

## 🎨 Design System

### Component Naming Convention
- All custom components prefixed with `CO` (e.g., `COPrimaryButton`, `COTextField`)
- Components are reusable across features
- Located in `iosApp/Library/Design/`

### Spacing System
Use standardized spacing constants from `CGFloat+Spacing.swift`:
- Constants follow pattern: `.spacingBasicXXXXXS` (smallest) to `.spacingBasicXXL` (largest)
- Always use these constants instead of hardcoded values
- Example: `.spacingBasicM`, `.spacingBasicXS`

### Corner Radius System
Use standardized corner radius constants from `CGFloat+CornerRadius.swift`:
- Constants follow pattern: `.cornerRadiusM`, `.cornerRadiusL`
- Always use these constants for consistent corner styling

### Component Patterns
- **Buttons**: Use `COPrimaryButton` with title and action closure
- **Text Fields**: Use `COTextField` with value binding and callback
- **Loading States**: Built into components (e.g., `COPrimaryButton` has `isLoading` parameter)
- **Feedback**: Use `UIImpactFeedbackGenerator` for button interactions

## 🔧 Error Handling

### Inline Errors (default)
Most errors belong in state and render in place — a message field on the screen's State
or a sub-state (e.g. a row's `errorMessage`), shown as styled text where the error
happened. See `kmp-viewmodel-state` for where error copy lives.

### Alert Pattern (dialog-style errors only)
When a screen-blocking error warrants a dialog, the State exposes a (usually derived)
`errorAlert: COAlertState?` — title, optional message, and actions built from stored
copy and state callbacks — cleared by an `onDismissError()` action, and the view uses
the standardized alert extension:
```swift
.alert(viewModel.state.errorAlert, onClose: viewModel.state.onDismissErrorTap)
```
Guard `onDismissError()` on the error actually being present: after an action button
is tapped, both platforms also fire `onClose`, and the guard keeps that stray dismiss
from clobbering a retry already in flight. A plain-message variant
`.alert(error: String?, onClose:)` exists for alerts with no actions.

### Error Extension
The `View+Alert` extension handles:
- Optional error string display
- Automatic alert presentation/dismissal
- Consistent "Close" button action

## 📁 File Organization

### Feature Structure
```
iosApp/iosApp/Features/FeatureName/
├── FeatureView.swift
└── FeatureSubComponent.swift (if needed)
```

### Library Structure
```
iosApp/iosApp/Library/
├── Design/
│   ├── COButton.swift
│   ├── COTextField.swift
│   └── Text Field/
├── Navigation/
│   ├── NavigationHandlerModifier.swift
│   └── NavigationManager.swift
└── Koin/
    └── KMPObservableViewModel.swift
```

### Common Structure
```
iosApp/iosApp/Common/
├── Constants/
│   ├── CGFloat+Spacing.swift
│   └── CGFloat+CornerRadius.swift
├── Extensions/
│   ├── View+Alert.swift
│   └── String+Error.swift
├── Styles/
│   └── Text+Fonts.swift
└── Views/
    └── BaseScrollView.swift
```

## 🔄 State Management

### State Binding Pattern
Use consistent binding pattern for two-way data flow:
```swift
TextField("Email", text: Binding(
    get: { state.email },
    set: onEmailChanged
))
```

### State-Driven UI
- All UI conditionals based on state properties
- Use `@ViewBuilder` for conditional view rendering
- Disable/enable UI elements based on state flags

```swift
@ViewBuilder
private var navigationButton: some View {
    if let title = state.skipButtonTitle {
        Button(title, action: onTapSkip)
    }
}
```

## 🔍 Previews

### Preview Requirements
- All views must include `#Preview` for design-time viewing
- Use mock state data that represents realistic scenarios
- Include multiple preview variations when useful

```swift
#Preview {
    FeatureView()
        .environmentObject(NavigationManager())
}
```

### Preview with State
For Content views, build state through the shared `+Preview` factories, never a
hand-built `State(...)` initializer — factories survive renames and added fields,
and a sealed `State` has no callable constructor (see `state-model-preview-helpers`):
```swift
@available(iOS 17.0, *)
#Preview {
    Content(
        state: .companion.previewSingle(),
        onAction: {}
    )
}
```

## 📝 Code Style

### MARK Comments
Use MARK comments to organize code sections:
```swift
// MARK: - Properties
// MARK: - Body
// MARK: - Private Views
// MARK: - Actions
// MARK: - Previews
```

### ViewBuilder Usage
- Use `@ViewBuilder` for conditional view logic
- Keep view building logic clean and readable
- Extract complex views into private computed properties

### Naming Conventions
- **Views**: `FeatureNameView`
- **Components**: `COComponentName`
- **Actions**: `onActionName` (e.g., `onTapContinue`, `onEmailChanged`)
- **State Properties**: Use descriptive names matching ViewModel state
- **Private Views**: Use descriptive computed property names

## 🔧 Dependencies

### Required Imports
Standard imports for feature views:
```swift
import SwiftUI
import Shared
import KMPObservableViewModelSwiftUI
```

Additional imports as needed:
```swift
import Foundation // For data types
import Combine    // For publishers
```

### ViewModel Integration Extension
The `KMPObservableViewModel.swift` provides necessary conformances:
```swift
extension Kmp_observableviewmodel_coreViewModel: @retroactive ObservableObject {}
extension Kmp_observableviewmodel_coreViewModel: @retroactive ViewModel {}
```

## ⚡ Performance

### Animation Guidelines
- Use `.animation(.easeOut, value: stateProperty)` for state-driven animations
- Apply `.transition(.opacity)` for view transitions
- Keep animations smooth and purposeful

### View Lifecycle
- Use `.onAppear` for initialization only
- Use `.onDisappear` for cleanup when needed
- Handle Combine cancellables properly in navigation modifier

## 🎯 Accessibility

### Semantic Views
- Use semantic SwiftUI components when possible
- Provide appropriate accessibility labels for custom components
- Ensure proper contrast and touch targets
