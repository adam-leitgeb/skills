---
name: new-kmp-feature
description: Step-by-step checklist for adding a new feature module to a KMP project (shared ViewModel, Android Compose, iOS SwiftUI) — the files to create and the registrations that are easy to forget. Use when creating a new feature or screen.
user-invocable: false
---

# New KMP Feature

This checklist guides you through creating a new feature/scene in the Kotlin Multiplatform project. Follow these steps in order to ensure all required files and integrations are created.

It covers **what to create and where to register it**. What goes *inside* each piece
lives in its own skill, so each rule has one home:

| Topic | Skill |
|---|---|
| Layers, naming, DI, package structure | `kotlin-multiplatform-architecture` |
| State shape, status modelling, error handling | `kmp-viewmodel-state` |
| Localized strings | `localization-kmp` |
| `+Preview` state factories | `state-model-preview-helpers` |
| SwiftUI view structure | `ios-swiftui-patterns` |
| Unit tests | `android-unittest-structure` |

> This checklist builds the whole feature in one pass. When the shared half is being
> built first from design screenshots and the UI follows later, the user invokes
> `new-kmp-feature-shared-only` — it follows this checklist but stops at placeholder
> iOS/Android views. That skill is user-invoked only; don't route to it yourself.

## 📋 Prerequisites

Before starting, decide on:
- **Feature name**: Use snake_case (e.g., `profile`, `payment_method`)
- **Feature display name**: PascalCase for classes (e.g., `Profile`, `PaymentMethod`)
- **Package path**: `{package}.features.{feature_name}` — `{package}` is a placeholder
  for **the project's own root package**; read it from any existing source file and use
  it verbatim (never a hardcoded vendor package).

## ✅ Step-by-Step Checklist

### 1. Shared Module (commonMain) - Core Feature Files

#### 1.1 Create Feature Directory Structure
- [ ] Create directory: `shared/src/commonMain/kotlin/.../features/{feature_name}/`
- [ ] Create subdirectories:
  - [ ] `di/` - Dependency injection module
  - [ ] `domain/` - Use cases
  - [ ] `presentation/` - ViewModels, state models, preview factories
  - [ ] `data/` - Repository
  - [ ] `model/` - Feature-specific models (if needed)

#### 1.2 Create ViewModel
- [ ] Create `presentation/{FeatureName}ViewModel.kt`
  - [ ] Extend `BaseViewModel<State>` if the screen does not navigate; extend `NavigationViewModel<State>` if it uses `navigate()` / `NavigationState`
  - [ ] Add nested `State : ViewModelState`
  - [ ] Implement `onAppear()` and the screen's `onXxx()` actions

> **Shape of `State` — sealed renderings vs a status field, deriving UI state
> instead of storing flags, stale results, where errors live — is
> `kmp-viewmodel-state`. Read it before writing the State.** In short: sealed
> variants for conditions where the content isn't on screen (loading, error,
> empty), a status field for operations that run while it is (submitting), one
> status instead of several booleans, and everything the UI renders derived
> from it.

- [ ] Add `presentation/{FeatureName}State+Preview.kt` factories (`state-model-preview-helpers`)

#### 1.3 Add Localized Strings
- [ ] Add the feature's keys to the project's `localization.json` and use the
      generated `{FeatureName}Strings` facade — see `localization-kmp` for the
      key naming, plurals and codegen wiring.

> Older projects hand-wrote a `{FeatureName}Strings.kt` object with literal
> strings. That is legacy — new features always go through the JSON source and
> codegen.

#### 1.4 Create UseCase Interface and Implementation
- [ ] Create `domain/{FeatureName}UseCase.kt`
  - [ ] Define `interface {FeatureName}UseCase` with abstract classes
  - [ ] Create `sealed class {FeatureName}UseCaseImpl` with implementations
  - [ ] Extend appropriate base classes from architecture kit (`UnitSuspendUseCase`, `SuspendUseCase`, `UnitUseCase`, `UnitFlowUseCase`)

**Template:**
```kotlin
package {package}.features.{feature_name}.domain

import io.github.foshlabs.kmp.architecturekit.UnitSuspendUseCase

interface {FeatureName}UseCase {
    // TODO: Add use case definitions here
    // Example:
    // abstract class LoadData: UnitSuspendUseCase<Data>()
}

sealed class {FeatureName}UseCaseImpl: {FeatureName}UseCase {
    // TODO: Add use case implementations here
}
```

#### 1.5 Create Repository
- [ ] Create `data/{FeatureName}Repository.kt`
  - [ ] Define `interface {FeatureName}Repository`
  - [ ] Create `class {FeatureName}RepositoryImpl : {FeatureName}Repository`
  - [ ] Add MARK comments: Properties, Methods

**Template:**
```kotlin
package {package}.features.{feature_name}.data

interface {FeatureName}Repository {
    // TODO: Add repository methods here
}

class {FeatureName}RepositoryImpl: {FeatureName}Repository {
    
    // MARK: - Properties
    
    // TODO: Add properties if needed
    
    // MARK: - Methods
    
    // TODO: Implement repository methods here
}
```

#### 1.6 Create DI Module
- [ ] Create `di/{featureName}Module.kt`
  - [ ] Register repository as `single<{FeatureName}Repository> { {FeatureName}RepositoryImpl() }`
  - [ ] Register use cases as `factory<{FeatureName}UseCase.{UseCaseName}> { {FeatureName}UseCaseImpl.{UseCaseName}(...) }`
  - [ ] Register ViewModel as `factory { {FeatureName}ViewModel(...) }`

**Template:**
```kotlin
package {package}.features.{feature_name}.di

import {package}.features.{feature_name}.data.{FeatureName}Repository
import {package}.features.{feature_name}.data.{FeatureName}RepositoryImpl
import {package}.features.{feature_name}.domain.{FeatureName}UseCase
import {package}.features.{feature_name}.domain.{FeatureName}UseCaseImpl
import {package}.features.{feature_name}.presentation.{FeatureName}ViewModel
import org.koin.dsl.module

val {featureName}Module = module {
    // Register repository
    single<{FeatureName}Repository> { {FeatureName}RepositoryImpl() }
    
    // Register use cases
    // factory<{FeatureName}UseCase.LoadData> { {FeatureName}UseCaseImpl.LoadData(get()) }
    
    // Register ViewModel
    factory { 
        {FeatureName}ViewModel(
            // TODO: Add use case parameters here
        )
    }
}
```

#### 1.7 Register Feature Module
- [ ] Open `shared/src/commonMain/kotlin/.../features/featureModule.kt`
- [ ] Add import: `import {package}.features.{feature_name}.di.{featureName}Module`
- [ ] Add module to list: `{featureName}Module,`

### 2. TemplateAppScene Integration

> The scene **type** is `TemplateAppScene` (Kotlin sealed interface, Swift enum),
> but it lives in a file called `AppScene.kt` / `AppScene.swift`. Check the actual
> names in the project before creating anything.

#### 2.1 Add TemplateAppScene to Shared Module
- [ ] Open `shared/src/commonMain/kotlin/.../application/AppScene.kt`
- [ ] Add: `data object {FeatureName}: TemplateAppScene`

#### 2.2 Add TemplateAppScene to Android Navigation
- [ ] Open `composeApp/src/androidMain/kotlin/.../library/navigation/mapToDestination.kt`
- [ ] Add case to `when` expression: `TemplateAppScene.{FeatureName} -> {FeatureName}`
- [ ] Add serializable object: `@Serializable object {FeatureName}`

#### 2.3 Add TemplateAppScene to iOS Navigation
- [ ] Open `iosApp/iosApp/App/AppScene.swift`
  - [ ] Add case: `case {featureName}`
- [ ] Open `iosApp/iosApp/App/AppScene+Convertible.swift`
  - [ ] Add case: `case is TemplateAppScene{FeatureName}: return .{featureName}`
- [ ] Open `iosApp/iosApp/App/AppScene+Factory.swift`
  - [ ] Add case: `case .{featureName}: {FeatureName}View()`

#### 2.4 Add Analytics Key (optional – if your project has analytics)
- [ ] If using analytics, add case to your scene analytics mapping: `TemplateAppScene.{FeatureName} -> "{feature_name}"`
  - [ ] Use snake_case for the analytics screen ID (e.g., `profile`, `payment_method`)

### 3. iOS Implementation

#### 3.1 Create iOS View
- [ ] Create directory: `iosApp/iosApp/Features/{FeatureName}/`
- [ ] Create `{FeatureName}View.swift`
  - [ ] Use `@StateViewModel` property wrapper
  - [ ] Inject ViewModel: `KoinDependencies().{featureName}ViewModel`
  - [ ] Create private `Content` struct
  - [ ] Add required modifiers: `.onAppear`, `.handleNavigation`
  - [ ] Add preview support

**Template:**
```swift
import KMPObservableViewModelSwiftUI
import Shared
import SwiftUI

struct {FeatureName}View: View {
    @StateViewModel var viewModel: {FeatureName}ViewModel = KoinDependencies().{featureName}ViewModel

    var body: some View {
        Content(
            state: viewModel.state
        )
        .onAppear(perform: viewModel.onAppear)
        .handleNavigation(viewModel)
        .navigationBarHidden(true)
    }
}

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

// MARK: - Previews

#Preview {
    Content(
        state: {FeatureName}ViewModel.State()
    )
}
```

#### 3.2 Register ViewModel in KoinDependencies
- [ ] Open `shared/src/iosMain/kotlin/.../KoinDependencies.kt`
- [ ] Add import: `import {package}.features.{feature_name}.presentation.{FeatureName}ViewModel`
- [ ] Add property: `val {featureName}ViewModel: {FeatureName}ViewModel by inject()`

### 4. Android Implementation (Optional - if needed)

#### 4.1 Create Android Composable
- [ ] Create directory: `composeApp/src/androidMain/kotlin/.../features/{feature_name}/`
- [ ] Create `{FeatureName}Screen.kt` composable
- [ ] Inject ViewModel using Koin
- [ ] Implement UI using Jetpack Compose

### 5. Verification Checklist

- [ ] All files compile without errors
- [ ] ViewModel extends `BaseViewModel<State>` or `NavigationViewModel<State>` (if screen uses navigation)
- [ ] State implements `ViewModelState`
- [ ] Repository interface and implementation created
- [ ] Repository registered as `single` in DI module
- [ ] DI module registered in `featureModule.kt`
- [ ] TemplateAppScene added to all three locations (shared, Android, iOS)
- [ ] Analytics key added (if project uses analytics)
- [ ] iOS ViewModel registered in `KoinDependencies`
- [ ] iOS View follows the standard pattern
- [ ] Strings come from `localization.json`, not literals
- [ ] All TODO comments addressed or documented

## 📝 Naming Conventions Reference

| Type | Convention | Example |
|------|-----------|---------|
| Feature directory | snake_case | `profile`, `payment_method` |
| Feature class names | PascalCase | `Profile`, `PaymentMethod` |
| ViewModel | `{FeatureName}ViewModel` | `ProfileViewModel` |
| UseCase | `{FeatureName}UseCase` | `ProfileUseCase` |
| Repository | `{FeatureName}Repository` | `ProfileRepository` |
| DI Module | `{featureName}Module` | `profileModule` |
| State | `State` (nested) | `ProfileViewModel.State` |
| Action methods | `on{ActionName}()` | `onTapContinue()`, `onSelectItem()` |
| iOS View | `{FeatureName}View` | `ProfileView` |
| Package | `{package}.features.{feature_name}` | `{package}.features.profile` |

## 🔍 Quick Reference: File Locations

### Shared Module
- ViewModel: `shared/src/commonMain/kotlin/.../features/{feature_name}/presentation/{FeatureName}ViewModel.kt`
- UseCase: `shared/src/commonMain/kotlin/.../features/{feature_name}/domain/{FeatureName}UseCase.kt`
- Repository: `shared/src/commonMain/kotlin/.../features/{feature_name}/data/{FeatureName}Repository.kt`
- DI Module: `shared/src/commonMain/kotlin/.../features/{feature_name}/di/{featureName}Module.kt`
- Feature Modules: `shared/src/commonMain/kotlin/.../features/featureModule.kt`
- Scenes: `shared/src/commonMain/kotlin/.../application/AppScene.kt`
- Analytics: (optional) add to your analytics mapping if used

### iOS
- View: `iosApp/iosApp/Features/{FeatureName}/{FeatureName}View.swift`
- TemplateAppScene / AppScene: `iosApp/iosApp/App/AppScene.swift`, `AppScene+Convertible.swift`, `AppScene+Factory.swift`
- KoinDependencies: `shared/src/iosMain/kotlin/.../KoinDependencies.kt`

### Android
- Navigation: `composeApp/src/androidMain/kotlin/.../library/navigation/mapToDestination.kt`

## 💡 Tips

1. **Start with the skeleton**: Create all files with TODO comments first, then implement
2. **Follow existing patterns**: Look at a recent feature in *this* project for reference — older ones may predate current conventions
3. **Test incrementally**: After each major step, verify compilation
4. **Navigation**: For screens that navigate, use `NavigationViewModel` and `navigate(NavigationState)`; use `HandleNavigation(viewModel, navController)` in the UI. For screens that do not navigate, use `BaseViewModel` and do not call `HandleNavigation`.
5. **Errors**: a use case's failure modes are a sealed taxonomy in the feature's `domain/`, carrying data only; the error→copy mapping is a named extension in `presentation/` — see `kmp-viewmodel-state`

## 🚨 Common Mistakes to Avoid

- ❌ Forgetting to register module in `featureModule.kt`
- ❌ Missing TemplateAppScene in one of the three locations (shared, Android, iOS)
- ❌ Forgetting to add analytics key (if project uses analytics)
- ❌ Not registering ViewModel in `KoinDependencies` for iOS
- ❌ Forgetting to create the Repository and register it in the DI module
- ❌ ViewModels calling repositories directly (must use UseCases)
- ❌ Missing required modifiers in iOS View (`.onAppear`, `.handleNavigation`)
- ❌ Wrong package naming (should use snake_case for feature names)
- ❌ Hand-writing a `{FeatureName}Strings.kt` with literal strings instead of adding keys to `localization.json`
