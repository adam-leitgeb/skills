---
name: android-implementation-from-ios
description: Port an existing iOS SwiftUI screen to Android Jetpack Compose, matching structure and behavior. Use when implementing the Android side of a feature that already exists on iOS.
user-invocable: false
---


# Android Implementation from iOS Guide

This guide describes how to implement Android (Jetpack Compose) versions of features that already exist on iOS (SwiftUI). Follow these steps to ensure consistency across platforms.

> **Note on the design system:** the mapping tables below reference a fuller design
> system (`Spacing` constants, `COScaffold`/`COPrimaryButton`/… components,
> `AppTypography`, `rememberAppIconPainter`, `OnLifecycleStart`) that this base
> template does **not** ship — the template uses Material 3 directly with shared
> design *tokens* only (`ThemeColors`, `ThemeFonts`, `AppIcon`). Treat those
> component/spacing references as the target shape once you add a design system;
> until then, map them to their Material 3 equivalents. The structural guidance
> (screen vs. `Content` split, `koinViewModel()`, `collectAsStateWithLifecycle()`,
> `HandleNavigation`, composable decomposition) applies as-is.

## 📋 Prerequisites

Before starting:
- **iOS implementation exists**: The feature should be fully implemented on iOS
- **Shared ViewModel exists**: ViewModel should be in `shared/src/commonMain/kotlin/com/jetbrains/kmpapp/features/{feature_name}/presentation/`
- **Navigation route exists**: TemplateAppScene should be defined in shared module


## 🔍 Step 1: Analyze iOS Implementation

### 1.1 Locate iOS View File
- Find the iOS view: `iosApp/iosApp/Features/{FeatureName}/{FeatureName}View.swift`
- Read the entire file to understand the structure

### 1.2 Identify Key Components
Look for these patterns in the iOS code:

**View Structure:**
```swift
struct FeatureView: View {
    @StateViewModel var viewModel: FeatureViewModel = KoinDependencies().featureViewModel
    
    var body: some View {
        Content(
            state: viewModel.state,
            onAction1: viewModel.onAction1,
            onAction2: viewModel.onAction2
        )
        .onAppear(perform: viewModel.onAppear)
        .handleNavigation(viewModel)
        .navigationBarHidden(false)
        .navigationTitle(FeatureStrings.shared.title())
    }
}

private struct Content: View {
    // UI implementation here
}
```

**Key Observations:**
- Main view handles ViewModel and lifecycle
- Private `Content` struct contains actual UI
- Navigation modifiers (`.navigationBarHidden`, `.navigationTitle`)
- Lifecycle hooks (`.onAppear`, `.handleNavigation`)

### 1.3 Map iOS Components to Android Equivalents

| iOS Component | Android Component | Location |
|--------------|-------------------|----------|
| `VStack` | `Column` | `androidx.compose.foundation.layout.Column` |
| `HStack` | `Row` | `androidx.compose.foundation.layout.Row` |
| `LazyVStack` | `LazyColumn` | `androidx.compose.foundation.lazy.LazyColumn` |
| `LazyHStack` | `LazyRow` | `androidx.compose.foundation.lazy.LazyRow` |
| `ScrollView` | `LazyColumn` or `Column` with `verticalScroll` | `androidx.compose.foundation.verticalScroll` |
| `Spacer()` | `Spacer(modifier = Modifier.weight(1f))` | `androidx.compose.foundation.layout.Spacer` |
| `ForEach` | `items()` in LazyColumn | `androidx.compose.foundation.lazy.items` |
| `.padding(.horizontal)` | `.padding(horizontal = Spacing.XXS)` | Use `Spacing` constants |
| `.padding(.vertical)` | `.padding(vertical = Spacing.M)` | Use `Spacing` constants |
| `.padding(.top)` | `.padding(top = Spacing.S)` | Use `Spacing` constants |
| `.padding(.bottom)` | `.padding(bottom = Spacing.S)` | Use `Spacing` constants |
| `.safeAreaInset(edge: .bottom)` | `Box` with `Alignment.BottomCenter` | Position button at bottom |


## 🎨 Step 2: Map Design System Elements

### 2.1 Spacing Constants

**iOS → Android Mapping:**
- `.spacingBasicXXXXXS` → `Spacing.XXXXXS` (2dp)
- `.spacingBasicXXXS` → `Spacing.XXXS` (8dp)
- `.spacingBasicXXS` → `Spacing.XXS` (16dp)
- `.spacingBasicXS` → `Spacing.XS` (20dp)
- `.spacingBasicS` → `Spacing.S` (24dp)
- `.spacingBasicM` → `Spacing.M` (32dp)
- `.spacingBasicL` → `Spacing.L` (40dp)
- `.spacingBasicXL` → `Spacing.XL` (48dp)
- `.spacingBasicXXL` → `Spacing.XXL` (64dp)

**Location:** `composeApp/src/androidMain/kotlin/com/jetbrains/kmpapp/common/constants/Spacing.kt`

**Usage:**
```kotlin
.padding(horizontal = Spacing.XXS, vertical = Spacing.M)
```

### 2.2 Typography/Fonts

**iOS → Android Mapping:**
- `.coTextTitle1()` → `AppTypography.title1`
- `.coTextTitle2()` → `AppTypography.title2`
- `.coTextTitle3()` → `AppTypography.title3`
- `.coTextTitle4()` → `AppTypography.title4`
- `.coTextBodyL()` → `AppTypography.bodyL`
- `.coTextBodyM()` → `AppTypography.bodyM`
- `.coTextBodyS()` → `AppTypography.bodyS`
- `.coTextCaption()` → `AppTypography.caption`
- `.coTextButtonM()` → `AppTypography.buttonM`
- `.coTextButtonS()` → `AppTypography.buttonS`

**Location:** `shared/src/commonMain/kotlin/com/jetbrains/kmpapp/library/design/theme/AppTypography.kt`

**Usage:**
```kotlin
Text(
    text = "Title",
    style = AppTypography.title1,
    color = ThemeColors.textPrimary.toComposeColor()
)
```

### 2.3 Colors

**iOS → Android Mapping:**
- `ThemeColors.shared.textPrimary.color` → `ThemeColors.textPrimary.toComposeColor()`
- `ThemeColors.shared.textSecondary.color` → `ThemeColors.textSecondary.toComposeColor()`
- `ThemeColors.shared.textTertiary.color` → `ThemeColors.textTertiary.toComposeColor()`
- `ThemeColors.shared.backgroundPrimary.color` → `ThemeColors.backgroundPrimary.toComposeColor()`
- `ThemeColors.shared.accent.color` → `ThemeColors.accent.toComposeColor()`

**Location:** `shared/src/commonMain/kotlin/com/jetbrains/kmpapp/library/design/color/ThemeColors.kt`

**Usage:**
```kotlin
Text(
    text = "Text",
    color = ThemeColors.textPrimary.toComposeColor()
)
```

### 2.4 Icons/Images

**iOS → Android Mapping:**
- `Image(systemName: "icon.name")` → `AppIcon.Symbol.ICON_NAME` or `AppIcon.Category.Name`
- `country.appIcon` → `country.appIcon` (extension property)
- Custom images → Check `AppIcon` enum

**Location:** `shared/src/commonMain/kotlin/com/jetbrains/kmpapp/library/design/icon/AppIcon.kt`

**Usage:**
```kotlin
val iconPainter = rememberAppIconPainter(AppIcon.Symbol.CHEVRON_RIGHT)
Image(
    painter = iconPainter,
    contentDescription = null,
    modifier = Modifier.size(24.dp),
    colorFilter = ColorFilter.tint(ThemeColors.textTertiary.toComposeColor()),
    contentScale = ContentScale.Fit
)
```


## 🧩 Step 3: Identify Shared Components

### 3.1 Common Shared Components

Check iOS code for these components and find Android equivalents:

| iOS Component | Android Component | Location |
|--------------|-------------------|----------|
| `COPrimaryButton` | `COPrimaryButton` | `composeApp/.../library/design/views/COPrimaryButton.kt` |
| `COSecondaryButton` | `COSecondaryButton` | `composeApp/.../library/design/views/COSecondaryButton.kt` |
| `COTextField` | `COTextField` | `composeApp/.../library/design/views/COTextField.kt` |
| `SelectableRow` | `SelectableRow` | `composeApp/.../common/views/SelectableRow.kt` |
| `RaisedButton` | `RaisedButton` | `composeApp/.../common/views/RaisedButton.kt` |
| `COScaffold` | `COScaffold` | `composeApp/.../library/design/views/COScaffold.kt` |
| `COAlertDialog` | `COAlertDialog` | `composeApp/.../library/design/views/COAlertDialog.kt` |
| `CODivider` | `CODivider` | `composeApp/.../library/design/views/CODivider.kt` |

### 3.2 Component Usage Patterns

**iOS:**
```swift
COPrimaryButton(
    title: FeatureStrings.PrimaryButton().confirm(),
    action: onTapConfirm
)
```

**Android:**
```kotlin
COPrimaryButton(
    title = FeatureStrings.PrimaryButton.confirm(),
    onClick = onTapConfirm
)
```

**Key Differences:**
- iOS uses `action:` closure, Android uses `onClick:` lambda
- iOS uses `.shared` for strings, Android uses direct object access
- iOS uses `()` for function calls, Android uses direct property access


## 🏗️ Step 4: Create Android Screen Structure

### 4.1 File Location
Create: `composeApp/src/androidMain/kotlin/com/jetbrains/kmpapp/features/{feature_name}/{FeatureName}Screen.kt`

### 4.2 Screen Structure Template

```kotlin
package com.jetbrains.kmpapp.features.{feature_name}

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.jetbrains.kmpapp.features.{feature_name}.presentation.{FeatureName}ViewModel
import com.jetbrains.kmpapp.features.{feature_name}.presentation.{FeatureName}Strings
import com.jetbrains.kmpapp.library.compose.OnLifecycleStart
import com.jetbrains.kmpapp.library.design.views.COScaffold
import com.jetbrains.kmpapp.library.navigation.HandleNavigation
import org.koin.androidx.compose.koinViewModel

/**
 * {Feature name} screen matching iOS {FeatureName}View.swift
 * {Brief description of what the screen does}
 */
@Composable
fun {FeatureName}Screen(navController: NavController) {
    val viewModel: {FeatureName}ViewModel = koinViewModel()
    val state by viewModel.states.collectAsStateWithLifecycle()

    // Handle navigation events from the ViewModel
    HandleNavigation(viewModel, navController)

    // Call onAppear when screen is fully visible (after animation completes)
    OnLifecycleStart { viewModel.onAppear() }

    Content(
        state = state,
        navController = navController,
        onAction1 = { viewModel.onAction1() },
        onAction2 = { viewModel.onAction2(it) }
    )
}

@Composable
private fun Content(
    state: {FeatureName}ViewModel.State,
    navController: NavController,
    onAction1: () -> Unit,
    onAction2: (String) -> Unit
) {
    COScaffold(
        title = {FeatureName}Strings.title(),
        navController = navController,
        showBackButton = true // Set based on iOS .navigationBarHidden(false)
    ) { paddingValues: PaddingValues ->
        // UI implementation here
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Content matching iOS Content struct
        }
    }
}
```

### 4.3 Structure Rules

**Top-Level Screen (`{FeatureName}Screen`):**
- ✅ Handles ViewModel injection via `koinViewModel()`
- ✅ Collects state via `collectAsStateWithLifecycle()`
- ✅ Handles navigation via `HandleNavigation(viewModel, navController)`
- ✅ Calls `viewModel.onAppear()` using `OnLifecycleStart` (ensures screen is fully visible after animation completes)
  - **Why `OnLifecycleStart` instead of `LaunchedEffect(Unit)`?** 
    - `OnLifecycleStart` waits for the screen to be fully visible and animations to complete before calling `onAppear()`
    - This matches iOS behavior where `.onAppear` is called after the view is fully rendered
    - `LaunchedEffect(Unit)` runs immediately when the composable is first composed, which may be too early
  - **Import:** `com.jetbrains.kmpapp.library.compose.OnLifecycleStart`
- ✅ Passes state and callbacks to `Content` composable
- ❌ **DO NOT** include `COScaffold` here - it goes in `Content`

**Content Composable:**
- ✅ Contains `COScaffold` with title and navigation setup
- ✅ Receives `state`, `navController`, and action callbacks as parameters
- ✅ Implements the actual UI matching iOS `Content` struct
- ✅ Uses `paddingValues` from `COScaffold` for proper spacing

### 4.4 Decompose Views into Smaller Composables

**Best Practice:** Break down complex UI into smaller, focused composables. This improves readability, reusability, and testability.

**When to Decompose:**
- ✅ When a composable exceeds ~50-100 lines
- ✅ When you have repeated UI patterns (e.g., list items, cards, rows)
- ✅ When a section has clear semantic meaning (e.g., header, footer, section)
- ✅ When a composable handles multiple concerns (e.g., layout + data formatting)

**Decomposition Patterns:**

**1. Extract List Items:**
```kotlin
// ❌ BAD - Item rendering inline
LazyColumn {
    items(state.items) { item ->
        Row(modifier = Modifier.fillMaxWidth()) {
            Text(text = item.title)
            Text(text = item.value)
        }
    }
}

// ✅ GOOD - Extracted item composable
LazyColumn {
    items(
        items = state.items,
        key = { it.id }
    ) { item ->
        ItemRow(item = item, onClick = { onTapItem(item) })
    }
}

@Composable
private fun ItemRow(
    item: ItemModel,
    onClick: () -> Unit
) {
    RaisedButton(
        colorScheme = ThemeColors.secondaryButton.neutral,
        onClick = onClick
    ) {
        Row(modifier = Modifier.fillMaxWidth()) {
            Text(text = item.title)
            Text(text = item.value)
        }
    }
}
```

**2. Extract Sections:**
```kotlin
// ❌ BAD - All sections in one composable
Column {
    // Header section
    Column {
        Text(text = state.header.title)
        COPrimaryButton(...)
    }
    
    // Practice section
    Column {
        Text(text = "PRACTICE")
        PracticeRow(...)
        PracticeRow(...)
    }
    
    // Premium banner
    if (state.premiumBanner != null) {
        COPremiumBanner(...)
    }
}

// ✅ GOOD - Extracted section composables
Column {
    HeaderSection(
        header = state.header,
        onTapGenerateTest = onTapGenerateTest
    )
    
    PracticeSection(
        mistakesCount = state.mistakesCount,
        savedQuestionsCount = state.savedQuestionsCount,
        onTapMistakes = onTapMistakes,
        onTapSavedQuestions = onTapSavedQuestions
    )
    
    if (state.premiumBanner != null) {
        COPremiumBanner(model = state.premiumBanner!!)
    }
}

@Composable
private fun HeaderSection(
    header: HeaderModel,
    onTapGenerateTest: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(Spacing.S)
    ) {
        HighlightedTextView(model = header.message)
        COPrimaryButton(
            state = header.button,
            onClick = onTapGenerateTest
        )
    }
}

@Composable
private fun PracticeSection(
    mistakesCount: String,
    savedQuestionsCount: String,
    onTapMistakes: () -> Unit,
    onTapSavedQuestions: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(Spacing.XXXS)
    ) {
        Text(
            text = LearnStrings.SkillPracticeSection.title().uppercase(),
            style = AppTypography.title3
        )
        PracticeRow(...)
        PracticeRow(...)
    }
}
```

**3. Extract Helper Composables:**
```kotlin
// ❌ BAD - Complex logic inline
@Composable
private fun MistakeRow(model: MistakeItem, onTap: () -> Unit) {
    RaisedButton(...) {
        Column {
            Text(text = model.questionAttempt.question.text)
            Row {
                Image(...) // X mark icon
                Text(text = "${model.remainingToCorrect}")
                Box(...) // Divider
                Text(text = model.categoryName ?: "")
            }
        }
    }
}

// ✅ GOOD - Extracted helper composables
@Composable
private fun MistakeRow(
    model: MistakeItem,
    onTap: () -> Unit
) {
    RaisedButton(...) {
        Column {
            QuestionTitle(model = model)
            Row {
                MistakeCountTag(model = model)
                model.categoryName?.let { categoryName ->
                    VerticalDivider()
                    CategoryName(categoryName = categoryName)
                }
            }
        }
    }
}

@Composable
private fun QuestionTitle(model: MistakeItem) {
    Text(
        text = model.questionAttempt.question.text,
        style = AppTypography.title3,
        color = ThemeColors.textPrimary.toComposeColor()
    )
}

@Composable
private fun MistakeCountTag(model: MistakeItem) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Image(...) // X mark icon
        Text(text = "${model.remainingToCorrect}")
    }
}

@Composable
private fun VerticalDivider() {
    Box(
        modifier = Modifier
            .width(2.dp)
            .height(14.dp)
            .background(ThemeColors.border.toComposeColor())
    )
}
```

**4. Use MARK Comments for Organization:**
```kotlin
@Composable
private fun Content(...) {
    // Main layout
    Column(...) {
        HeaderSection(...)
        Separator()
        PracticeSection(...)
    }
}

// MARK: - Section Composables

@Composable
private fun HeaderSection(...) { ... }

@Composable
private fun PracticeSection(...) { ... }

// MARK: - Helper Composables

@Composable
private fun Separator() {
    CODivider()
    Spacer(modifier = Modifier.height(Spacing.M))
}

@Composable
private fun PracticeRow(...) { ... }
```

**Naming Conventions:**
- **Section composables**: `{SectionName}Section` (e.g., `HeaderSection`, `PracticeSection`)
- **Row/Item composables**: `{ItemName}Row` (e.g., `MistakeRow`, `PracticeRow`)
- **Helper composables**: Descriptive names (e.g., `QuestionTitle`, `MistakeCountTag`, `VerticalDivider`)
- **All private composables**: Use `private` modifier

**Benefits:**
- ✅ Improved readability - Each composable has a single responsibility
- ✅ Easier testing - Can test individual composables in isolation
- ✅ Better reusability - Composables can be reused across screens
- ✅ Easier maintenance - Changes are localized to specific composables
- ✅ Better performance - Compose can skip recomposition of unchanged composables


## 📐 Step 5: Layout Implementation

### 5.1 PaddingValues Usage

**Important:** `PaddingValues` constructor requires explicit parameters:

```kotlin
// ✅ CORRECT
contentPadding = PaddingValues(
    start = Spacing.XXS,
    top = Spacing.M,
    end = Spacing.XXS,
    bottom = 80.dp
)

// ❌ WRONG - Cannot mix horizontal/vertical with bottom
contentPadding = PaddingValues(
    horizontal = Spacing.XXS,
    vertical = Spacing.M,
    bottom = 80.dp // This will cause compilation error
)
```

### 5.2 Bottom Button Pattern (iOS safeAreaInset)

**iOS:**
```swift
.safeAreaInset(edge: .bottom) {
    COPrimaryButton(
        title: FeatureStrings.PrimaryButton().confirm(),
        action: onTapConfirm
    )
    .padding(.horizontal, .spacingBasicXXS)
    .padding(.bottom, .spacingBasicS)
}
```

**Android:**
```kotlin
Box(
    modifier = Modifier.fillMaxSize()
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(
            start = Spacing.XXS,
            top = Spacing.M,
            end = Spacing.XXS,
            bottom = 80.dp // Space for bottom button
        )
    ) {
        // List items
    }

    // Bottom button (similar to iOS safeAreaInset)
    Box(
        modifier = Modifier
            .align(Alignment.BottomCenter)
            .fillMaxWidth()
            .padding(horizontal = Spacing.XXS)
            .padding(bottom = Spacing.S)
    ) {
        COPrimaryButton(
            title = FeatureStrings.PrimaryButton.confirm(),
            onClick = onTapConfirm
        )
    }
}
```

### 5.3 List Implementation

**iOS LazyVStack:**
```swift
LazyVStack(spacing: .spacingBasicXXXS) {
    ForEach(state.items, id: \.id) { item in
        ItemRow(item: item)
    }
}
.padding(.horizontal, .spacingBasicXXS)
.padding(.top, .spacingBasicM)
```

**Android LazyColumn:**
```kotlin
LazyColumn(
    modifier = Modifier.fillMaxSize(),
    contentPadding = PaddingValues(
        start = Spacing.XXS,
        top = Spacing.M,
        end = Spacing.XXS,
        bottom = 0.dp
    ),
    verticalArrangement = Arrangement.spacedBy(Spacing.XXXS)
) {
    items(
        items = state.items,
        key = { it.id }
    ) { item ->
        ItemRow(item = item)
    }
}
```


## 🔗 Step 6: Navigation Integration

### 6.1 Update App.kt

**Location:** `composeApp/src/androidMain/kotlin/com/jetbrains/kmpapp/app/App.kt`

**Add import:**
```kotlin
import com.jetbrains.kmpapp.features.{feature_name}.{FeatureName}Screen
```

**Update navigation route:**
```kotlin
composable<{FeatureName}> {
    {FeatureName}Screen(navController = navController)
}
```

**Replace placeholder if exists:**
```kotlin
// Remove this:
composable<{FeatureName}> {
    PlaceholderScreen("{Feature Name}")
}

// Add this:
composable<{FeatureName}> {
    {FeatureName}Screen(navController = navController)
}
```

### 6.2 Navigation Route Verification

Ensure route exists in:
- `shared/src/commonMain/kotlin/com/jetbrains/kmpapp/library/navigation/mapToDestination.kt`
- Should already exist if iOS implementation is complete


## ✅ Step 7: Verification Checklist

### 7.1 Structure Checklist
- [ ] Top-level screen handles ViewModel and lifecycle only
- [ ] `Content` composable contains `COScaffold`
- [ ] `Content` receives state and callbacks as parameters
- [ ] Navigation handled via `HandleNavigation`
- [ ] `onAppear()` called using `OnLifecycleStart` (ensures screen is fully visible after animation completes)
- [ ] Complex UI decomposed into smaller composables (sections, rows, helpers)
- [ ] MARK comments used to organize composable groups
- [ ] All private composables properly scoped

### 7.2 Design System Checklist
- [ ] All spacing uses `Spacing` constants (not hardcoded values)
- [ ] All typography uses `AppTypography` styles
- [ ] All colors use `ThemeColors` with `.toComposeColor()`
- [ ] All icons use `AppIcon` enum with `rememberAppIconPainter`
- [ ] Padding values use correct `PaddingValues` constructor

### 7.3 Component Checklist
- [ ] Shared components imported from correct locations
- [ ] Component props match iOS equivalents (e.g., `onClick` vs `action`)
- [ ] String access matches pattern (direct object vs `.shared`)
- [ ] Button titles use `.uppercase()` if iOS uses `.uppercased()`

### 7.4 Layout Checklist
- [ ] List implementations use `LazyColumn`/`LazyRow` appropriately
- [ ] Bottom buttons positioned using `Box` with `Alignment.BottomCenter`
- [ ] Content padding accounts for bottom buttons
- [ ] Spacing between items matches iOS (check `spacing` parameter)

### 7.5 Navigation Checklist
- [ ] Screen registered in `App.kt` navigation routes
- [ ] Import statement added for screen composable
- [ ] `NavController` passed to screen
- [ ] Back button shown if iOS has `.navigationBarHidden(false)`


## 🎯 Step 8: Common Patterns Reference

### 8.1 Screen with List and Bottom Button

```kotlin
@Composable
private fun Content(
    state: ViewModel.State,
    navController: NavController,
    onAction: () -> Unit
) {
    COScaffold(
        title = Strings.title(),
        navController = navController,
        showBackButton = true
    ) { paddingValues: PaddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(
                    start = Spacing.XXS,
                    top = Spacing.M,
                    end = Spacing.XXS,
                    bottom = 80.dp
                ),
                verticalArrangement = Arrangement.spacedBy(Spacing.XXXS)
            ) {
                items(
                    items = state.items,
                    key = { it.id }
                ) { item ->
                    ItemRow(item = item)
                    Spacer(modifier = Modifier.height(Spacing.XXXS))
                }
            }

            Box(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
                    .padding(horizontal = Spacing.XXS)
                    .padding(bottom = Spacing.S)
            ) {
                COPrimaryButton(
                    title = Strings.PrimaryButton.confirm(),
                    onClick = onAction
                )
            }
        }
    }
}
```

### 8.2 Screen with Scrollable Content

```kotlin
@Composable
private fun Content(
    state: ViewModel.State,
    navController: NavController
) {
    COScaffold(
        title = Strings.title(),
        navController = navController,
        showBackButton = true
    ) { paddingValues: PaddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = Spacing.XXS, vertical = Spacing.M)
        ) {
            // Content here
        }
    }
}
```

### 8.3 Screen with Sections and Dividers

```kotlin
@Composable
private fun Content(
    state: ViewModel.State,
    navController: NavController
) {
    COScaffold(
        title = Strings.title(),
        navController = navController
    ) { paddingValues: PaddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = Spacing.XXS, vertical = Spacing.M)
        ) {
            state.sections.forEachIndexed { index, section ->
                Section(model = section)

                // Add divider between sections (not after last section)
                if (index < state.sections.size - 1) {
                    Spacer(modifier = Modifier.height(Spacing.M))
                    CODivider()
                    Spacer(modifier = Modifier.height(Spacing.M))
                }
            }
        }
    }
}
```

### 8.4 Decomposed Screen Example

```kotlin
@Composable
private fun Content(
    state: ViewModel.State,
    navController: NavController,
    onTapGenerateTest: () -> Unit,
    onTapMistakes: () -> Unit,
    onTapSavedQuestions: () -> Unit
) {
    COScaffold(
        title = Strings.title(),
        navController = navController,
        showBackButton = false
    ) { paddingValues: PaddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = Spacing.XXS)
        ) {
            HeaderSection(
                header = state.header,
                onTapGenerateTest = onTapGenerateTest
            )

            Separator()

            PracticeSection(
                mistakesCount = state.mistakesCount,
                savedQuestionsCount = state.savedQuestionsCount,
                onTapMistakes = onTapMistakes,
                onTapSavedQuestions = onTapSavedQuestions
            )

            if (state.premiumBanner != null) {
                COPremiumBanner(model = state.premiumBanner!!)
            }
        }
    }
}

// MARK: - Section Composables

@Composable
private fun HeaderSection(
    header: HeaderModel,
    onTapGenerateTest: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = Spacing.M, bottom = Spacing.M),
        verticalArrangement = Arrangement.spacedBy(Spacing.S)
    ) {
        HighlightedTextView(model = header.message)
        COPrimaryButton(
            state = header.button,
            onClick = onTapGenerateTest
        )
    }
}

@Composable
private fun PracticeSection(
    mistakesCount: String,
    savedQuestionsCount: String,
    onTapMistakes: () -> Unit,
    onTapSavedQuestions: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = Spacing.M),
        verticalArrangement = Arrangement.spacedBy(Spacing.M)
    ) {
        Text(
            text = Strings.SkillPracticeSection.title().uppercase(),
            style = AppTypography.title3,
            color = ThemeColors.textPrimary.toComposeColor()
        )

        Column(
            verticalArrangement = Arrangement.spacedBy(Spacing.XXXS)
        ) {
            PracticeRow(
                icon = AppIcon.Learn.MISTAKES,
                title = Strings.SkillPracticeSection.mistakesTitle(),
                value = mistakesCount,
                onClick = onTapMistakes
            )
            PracticeRow(
                icon = AppIcon.Learn.SAVED_QUESTIONS,
                title = Strings.SkillPracticeSection.savedQuestionsTitle(),
                value = savedQuestionsCount,
                onClick = onTapSavedQuestions
            )
        }
    }
}

// MARK: - Helper Composables

@Composable
private fun Separator() {
    CODivider()
    Spacer(modifier = Modifier.height(Spacing.M))
}

@Composable
private fun PracticeRow(
    icon: AppIcon,
    title: String,
    value: String,
    onClick: () -> Unit
) {
    val iconPainter = rememberAppIconPainter(icon)
    val colorScheme: ElevatedButtonColors = ThemeColors.secondaryButton.neutral

    RaisedButton(
        colorScheme = colorScheme,
        onClick = onClick
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(Spacing.XXXS)
        ) {
            Image(
                painter = iconPainter,
                contentDescription = null,
                modifier = Modifier.size(20.dp),
                contentScale = ContentScale.Fit
            )

            Text(
                text = title,
                style = AppTypography.buttonM,
                color = colorScheme.text.toComposeColor(),
                modifier = Modifier.weight(1f)
            )

            Text(
                text = value,
                style = AppTypography.buttonM,
                color = ThemeColors.textSecondary.toComposeColor()
            )

            val chevronPainter = rememberAppIconPainter(AppIcon.Symbol.CHEVRON_RIGHT)
            Image(
                painter = chevronPainter,
                contentDescription = null,
                modifier = Modifier.width(20.dp),
                colorFilter = ColorFilter.tint(ThemeColors.border.toComposeColor()),
                contentScale = ContentScale.Fit
            )
        }
    }
}
```


## 🚨 Common Mistakes to Avoid

### ❌ Structure Mistakes
- **Putting `COScaffold` in top-level screen** - It should be in `Content`
- **Missing `Content` composable** - Always separate UI from ViewModel logic
- **Not passing `paddingValues`** - Always use padding from `COScaffold`
- **Monolithic composables** - Break down complex UI into smaller composables
- **Missing decomposition** - Extract sections, rows, and helper composables
- **No MARK comments** - Use MARK comments to organize composable groups

### ❌ Design System Mistakes
- **Hardcoded spacing values** - Always use `Spacing` constants
- **Wrong `PaddingValues` constructor** - Cannot mix `horizontal`/`vertical` with `bottom`
- **Missing `.toComposeColor()`** - Colors need conversion
- **Wrong typography style** - Check iOS font size and weight

### ❌ Component Mistakes
- **Wrong callback name** - Use `onClick` not `action`
- **Missing string access** - Use direct object access, not `.shared`
- **Wrong icon enum path** - Check `AppIcon` structure

### ❌ Layout Mistakes
- **Forgetting bottom padding** - Lists need space for bottom buttons
- **Wrong alignment** - Use `Alignment.BottomCenter` for bottom buttons
- **Missing `key` parameter** - LazyColumn items need unique keys


## 📚 Reference Files

### iOS Reference
- View: `iosApp/iosApp/Features/{FeatureName}/{FeatureName}View.swift`
- Components: `iosApp/iosApp/Common/Views/`
- Design: `iosApp/iosApp/Library/Design/`

### Android Reference
- Screen: `composeApp/src/androidMain/kotlin/com/jetbrains/kmpapp/features/{feature_name}/{FeatureName}Screen.kt`
- Components: `composeApp/src/androidMain/kotlin/com/jetbrains/kmpapp/common/views/`
- Design: `composeApp/src/androidMain/kotlin/com/jetbrains/kmpapp/library/design/`

### Shared Reference
- ViewModel: `shared/src/commonMain/kotlin/com/jetbrains/kmpapp/features/{feature_name}/presentation/`
- Strings: `shared/src/commonMain/kotlin/com/jetbrains/kmpapp/features/{feature_name}/presentation/{FeatureName}Strings.kt`
- Design System: `shared/src/commonMain/kotlin/com/jetbrains/kmpapp/library/design/`


## 💡 Tips

1. **Start with structure** - Create the top-level screen and Content composable first
2. **Copy iOS layout** - Match the iOS structure as closely as possible
3. **Decompose early** - Break down UI into smaller composables as you build, not after
4. **Use existing screens as reference** - Check `MistakeListScreen.kt` or `LearnScreen.kt` for decomposition patterns
5. **Test incrementally** - Build after each major section to catch errors early
6. **Match spacing exactly** - Use the spacing mapping table to ensure pixel-perfect matching
7. **Verify shared components** - Check if components exist before creating new ones
8. **Follow naming conventions** - Use same naming as iOS where possible
9. **Use MARK comments** - Organize composables with MARK comments for better navigation


This guide ensures consistent Android implementations that match iOS designs and leverage shared components effectively.
