---
name: android-unittest-structure
description: Structure and conventions for Android/Kotlin unit tests in a KMP project. Use when writing or editing unit tests.
user-invocable: false
---

# Android Unit Test Structure

The `androidUnitTest` source set contains unit tests for the **shared code** (commonMain). These tests run on the JVM/Android and verify the shared business logic, ViewModels, UseCases, and data layer. The structure must mirror `commonMain` for consistency and discoverability.

## Top-Level Structure (commonMain)

```
kmpapp/
├── application/   # Reusable app-level components
├── data/          # Reusable data layer (repositories, DTOs)
├── domain/        # Reusable domain models and use cases
├── library/       # Reusable utilities and design system
└── features/      # Feature-specific code
```

## Test Structure (androidUnitTest)

Tests follow the same layout. Place tests in the package path that mirrors the source being tested.

### Reusable Component Tests

Tests for `application`, `data`, `domain`, or `library` go in the corresponding top-level folders:

- `application/` → tests for app-level components
- `data/` → tests for repositories, converters, data sources
- `domain/` → tests for shared domain logic
- `library/` → tests for utilities, design system

### Feature-Specific Tests

Tests for feature code go under `features/<feature_name>/` with the same subfolders:

```
features/login/
├── domain/       # LoginUseCaseTest.kt
└── presentation/ # LoginViewModelTest.kt
```

Each feature may have `domain/`, `presentation/`, and `data/` subfolders. Only create the subfolders you need for existing tests.

## Examples

| Source (commonMain) | Test (androidUnitTest) |
|---------------------|-------------------------|
| `features/login/domain/LoginUseCase.kt` | `features/login/domain/LoginUseCaseTest.kt` |
| `features/login/presentation/LoginViewModel.kt` | `features/login/presentation/LoginViewModelTest.kt` |
| `data/repository/CurrentUserRepository.kt` | `data/repository/CurrentUserRepositoryTest.kt` |
| `domain/validator/UrlValidator.kt` | `domain/validator/UrlValidatorTest.kt` |

## Package Naming

Test packages must match the source package exactly. A test for `{package}.features.login.domain.LoginUseCase` lives in package `{package}.features.login.domain` with file `LoginUseCaseTest.kt`. (`{package}` is a placeholder — use the project's own root package, read from any existing source file, never a hardcoded vendor package.)
