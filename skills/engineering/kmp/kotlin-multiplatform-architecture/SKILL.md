---
name: kotlin-multiplatform-architecture
description: Kotlin Multiplatform Clean Architecture conventions — module/layer structure, MVVM, Koin DI, naming. Use when writing or editing Kotlin (.kt/.kts) in a KMP project.
paths:
  - "**/*.kt"
user-invocable: false
---

# Kotlin Multiplatform Clean Architecture Rules

## 🏗️ Architecture Patterns

### Clean Architecture Layers
- **Presentation Layer**: ViewModels and UI components
- **Domain Layer**: UseCases, models, and business logic
- **Data Layer**: Repositories, DTOs, and data sources
- ViewModels don't interact with repositories directly - they must use UseCases as intermediaries
- Each feature should have clear separation between these layers

### MVVM Pattern
- ViewModels extend `BaseViewModel<State>` (state and ViewModel machinery only) or `NavigationViewModel<State>` (adds navigation)
- Use `NavigationViewModel` for screen ViewModels that use navigation (`navigate()`, `NavigationState`); use `BaseViewModel` for screens that do not
- State is nested inside the ViewModel and implements `ViewModelState`
- Navigation is handled through `NavigationState` and `navigate()` on `NavigationViewModel` (from navigation kit)
- **How to shape that State — sealed renderings vs a status field, deriving UI state
  instead of storing flags, where errors live — is `kmp-viewmodel-state`.** Don't
  duplicate those rules here.

### Dependency Injection (Koin)
- Each feature should have its own DI module (e.g., `selectCountryModule`)
- ViewModels should be registered as `factory` instances
- Repository implementations should be bound to their interfaces
- Group modules logically in `registerSharedModules()`

## 📁 Code Organization

### Feature Structure
Each feature should follow this structure:
```
features/feature_name/
├── di/
│   └── featureNameModule.kt
├── domain/
│   └── FeatureNameUseCase.kt
├── presentation/
│   └── FeatureNameViewModel.kt
└── data/ (if needed)
    └── FeatureNameRepository.kt
```

### Package Naming
- **Always use the project's own root package** (reverse-domain notation) — read it
  from any existing source file; never hardcode a vendor package. Throughout these
  skills `{package}` stands in for that actual root.
- Feature packages should use snake_case (e.g., `select_country`)
- Class names should use PascalCase

## 🔧 Code Conventions

### UseCase Pattern
- Define UseCases as interfaces with abstract class implementations
- Group related UseCases in a single interface
- Implement concrete UseCases as sealed classes
- UseCases should extend appropriate base classes from architecture kit (UseCase, SuspendUseCase, UnitUseCase, UnitFlowUseCase, UnitSuspendUseCase)

### Repository Pattern
- Always define repository interfaces
- Implement concrete repositories with "Impl" suffix
- Use DTO to Domain model conversion with `toDomain()` extensions
- Repositories handle data persistence and API calls

### ViewModel Structure
- Use `viewModelScope.launch` for coroutines
- Organize with `// MARK: -` sections (topical, not a fixed set)
- State shape, status modelling and error handling: see `kmp-viewmodel-state`

### Naming Conventions
- ViewModels: `FeatureNameViewModel`
- UseCases: `FeatureNameUseCase` with nested implementations
- Repositories: `FeatureNameRepository` (interface) and `FeatureNameRepositoryImpl`
- DI Modules: `featureNameModule`
- State classes: `State` (nested in ViewModel)
- Action methods: `onActionName()` (e.g., `onTapContinue()`, `onSelectCountry()`)

## 🔄 Data Flow

### Unidirectional Data Flow
1. UI triggers action on ViewModel
2. ViewModel calls UseCase
3. UseCase interacts with Repository
4. Repository returns data through Domain models
5. ViewModel updates State
6. UI reacts to State changes

### Error Handling
- Failure modes are a sealed taxonomy in the domain layer, carrying data only
- User-facing copy is presentation's job — a domain type must never import
  `presentation` (that inverts the dependency direction)
- How a ViewModel turns an error into state: see `kmp-viewmodel-state`

## 🎯 Platform-Specific Rules

### Shared Module (commonMain)
- Contains all business logic, domain models, and data layer
- ViewModels should be platform-agnostic
- Use expect/actual for platform-specific implementations
- **Architecture kit** (io.github.foshlabs.kmp.architecturekit): UseCase bases, BaseViewModel, ViewModelState
- **Navigation kit** (io.github.foshlabs.kmp.navigationkit): NavigationViewModel, NavigationState, AppScene, compose/navigation helpers (HandleNavigation, LocalNavigationManager, NavigationManager)

### Platform Modules
- Android: UI with Jetpack Compose
- iOS: UI with SwiftUI, bridge through KoinDependencies
- Platform-specific implementations in androidMain/iosMain

### View Naming Conventions
- **iOS (SwiftUI)**: Only top-level screen views use the "View" suffix (e.g., `LearnView`, `HomeView`). Sub-views and components do not use the suffix (e.g., `TipsSection`, `PracticeSection`).
- **Android (Compose)**: Only top-level screen composables use the "Screen" suffix (e.g., `LearnScreen`, `HomeScreen`). Sub-composables and components do not use the suffix (e.g., `TipsSection`, `PracticeSection`).

## 📝 Documentation
- Use KDoc for public APIs
- MARK comments for code organization (iOS/Swift style)
- Inline comments for complex business logic
- Keep README updated with architecture decisions

## 🎨 Code Formatting

### File Endings
- Files must end with exactly 1 empty line, not more
- This ensures consistent formatting across the codebase
