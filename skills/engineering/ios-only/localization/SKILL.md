---
name: localization
description: iOS-only localization — Kotlin key objects + an Xcode String Catalog (Localizable.xcstrings) resolved via NSLocalizedString. Use when adding or editing localized strings in an iOS-only app. (KMP apps use the localization-kmp skill instead.)
user-invocable: false
---


# Localization System (iOS-only)

This iOS-only app localizes via Kotlin key objects backed by an Xcode String Catalog
(`Localizable.xcstrings`) resolved with `NSLocalizedString`. (KMP projects do **not** use
this approach — they author one canonical JSON with codegen; see the `localization-kmp` skill.)

## Architecture

### 1. Kotlin String Objects (Shared Module)
Located in `shared/src/commonMain/kotlin/com/foshlabs/tally_counter/features/*/presentation/`

These objects define localization keys as Kotlin functions that return string identifiers:

```kotlin
object CounterListStrings {
    fun title(): String = "counter-list.title"
    fun addCounterButtonTitle(): String = "counter-list.add-counter-button.title"
    
    object NewCounterAlert {    
        fun title(): String = "counter-list.create-new-counter.title"
        fun placeholder(): String = "counter-list.create-new-counter.name-text-field.placeholder"
    }
}
```

**Pattern:** Use nested objects for grouping related strings (e.g., alerts, dialogs).

### 2. iOS Localizable Strings
Located in `iosApp/iosApp/Resources/Localizable.xcstrings`

This is an Xcode String Catalog (`.xcstrings` format) containing all translations.

**Structure:**
```json
{
  "sourceLanguage": "en",
  "strings": {
    "counter-list.title": {
      "extractionState": "manual",
      "localizations": {
        "en": { "stringUnit": { "state": "translated", "value": "Counters" } },
        "ar": { "stringUnit": { "state": "translated", "value": "العدّادات" } },
        "de": { "stringUnit": { "state": "translated", "value": "Zähler" } },
        // ... more languages
      }
    }
  }
}
```

### 3. Swift String Extension
Located in `iosApp/iosApp/Common/Extensions/String+Localization.swift`

```swift
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
```

## Supported Languages
- 🇬🇧 English (en) - source language
- 🇦🇪 Arabic (ar)
- 🇩🇪 German (de)
- 🇪🇸 Spanish (es)
- 🇫🇷 French (fr)
- 🇨🇳 Chinese Simplified (zh-Hans)

## Usage in Swift Views

```swift
private let localization = CounterListStrings()

var body: some View {
    Text(localization.title().localized)
    Button(localization.addCounterButtonTitle().localized) { }
}
```

## Adding New Localized Strings

### Step 1: Add Key to Kotlin Object
```kotlin
object YourFeatureStrings {
    fun yourNewString(): String = "your-feature.your-new-string"
}
```

### Step 2: Add Translations to Localizable.xcstrings
Add entry with all 6 language translations:
```json
"your-feature.your-new-string": {
  "extractionState": "manual",
  "localizations": {
    "en": { "stringUnit": { "state": "translated", "value": "Your English Text" } },
    "ar": { "stringUnit": { "state": "translated", "value": "نص عربي" } },
    "de": { "stringUnit": { "state": "translated", "value": "Deutscher Text" } },
    "es": { "stringUnit": { "state": "translated", "value": "Texto en español" } },
    "fr": { "stringUnit": { "state": "translated", "value": "Texte français" } },
    "zh-Hans": { "stringUnit": { "state": "translated", "value": "中文文本" } }
  }
}
```

### Step 3: Use in Swift
```swift
let localization = YourFeatureStrings()
Text(localization.yourNewString().localized)
```

## Key Naming Convention
- Use kebab-case for keys
- Structure: `feature-name.component.property`
- Examples:
  - `counter-list.title`
  - `counter-list.add-counter-button.title`
  - `counter-list.create-new-counter.button.save`
  - `widget.description`

## Best Practices
1. ✅ Always add ALL 6 language translations when adding new strings
2. ✅ Use nested objects in Kotlin for logical grouping (e.g., alerts, buttons)
3. ✅ Keep the English text as the source of truth
4. ✅ Use descriptive key names that indicate context
5. ❌ Never hardcode user-facing strings in Swift views
6. ❌ Don't skip languages - maintain consistency across all translations
