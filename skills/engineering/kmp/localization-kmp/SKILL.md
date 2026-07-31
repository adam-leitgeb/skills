---
name: localization-kmp
description: Localization for a KMP app (shared + Android + iOS) — single canonical JSON, build-time codegen of type-safe XxxStrings facades, a runtime Localizer, and CLDR plurals. Use when adding or editing localized strings, adding a language, or touching the localization system.
user-invocable: false
---

# Localization System (KMP)

Strings are authored **once** in a canonical JSON and consumed by **both** Android
(Compose) and iOS (SwiftUI). A build-time codegen step turns the JSON into type-safe
`XxxStrings` facades; at runtime a tiny `Localizer` resolves keys to plain `String`s.
No third-party localization library, no native resource bundles (`.xcstrings` / Android
`strings.xml`).

Where the project keeps a contributor-facing `docs/localization.md`, this is its condensed
agent-facing mirror — keep the two in sync.

## How it fits together

```
shared/src/commonMain/resources/localization.json   ← author strings here (one file)
        │
        ├─ build: generateLocalization (Gradle)  → build/generated/localization/**/XxxStrings.kt
        │     object ProfileStrings { fun title(): String = Localizer.localise("profile.title") }
        │
        └─ runtime: FileLoader.loadFile("localization.json")
              → LocalizationLoader (active language + base fallback) → Localizer.load(map)
              → ProfileStrings.title() → Localizer.localise(...) → plain String
```

- **Canonical source:** `shared/src/commonMain/resources/localization.json`. It fans out
  to both app bundles: Android via `assets.srcDir(src/commonMain/resources)` in
  `shared/build.gradle.kts`; iOS via the **"Copy KMP Resources"** run-script build phase
  in `iosApp.xcodeproj` (rsync into the `.app`).
- **Codegen:** the `generateLocalization` Gradle task reads the JSON and generates the
  `XxxStrings` objects into `build/generated/localization` (wired onto `commonMain` via
  `kotlin.srcDir`). Generated files carry a `// GENERATED — do not edit` header and are
  **not committed**.
- **Runtime:** `library/localization/` holds `Localizer` (the `object` generated code
  calls), `LocalizationLoader`, `LocalizationCoordinator`, `LanguageController`,
  `LocalizationDto`, and `PluralRules` (the CLDR plural-category selector). The map is
  loaded once at app startup, **before** the first string-rendering screen.

## JSON format

A flat object keyed by the full dotted key; each value maps a language code to its
translation. The base language (`en`) is **required** for every key; other languages are
optional and fall back to `en`.

A value is **either** a plain string (singular) **or** an object of `CLDR-category → string`
(plural). A key is plural iff its language values are objects, singular iff they are strings;
a key must be the **same shape across all of its languages** (never mixed — the validation
test enforces this).

```json
{
  "profile.title":          { "en": "Your profile", "de": "Dein Profil" },
  "profile.save_button":    { "en": "Save",         "de": "Speichern" },
  "profile.list.add_button":{ "en": "Add item" },

  "profile.count": {
    "en": { "one": "%1$d item",    "other": "%1$d items" },
    "de": { "one": "%1$d Eintrag", "other": "%1$d Einträge" },
    "pl": { "one": "%1$d pozycja", "few": "%1$d pozycje", "many": "%1$d pozycji" }
  }
}
```

Plural categories are the CLDR keywords: `zero`, `one`, `two`, `few`, `many`, `other`.
`other` is the universal fallback and is **required** on every plural key's base language.

## Key-naming convention (the codegen contract)

A key is `<namespace>.<element-path>`, all lowercase ASCII, `.`-separated; multi-word
segments use snake_case.

- **First segment = namespace** → selects the target package + object via the
  **namespace registry** (`localizationNamespaces` in `shared/build.gradle.kts`). Both
  vary per namespace, so the registry is required. Add an entry for any new namespace.
- **Remaining segments → function name**, lowerCamelCase: every `.`/`_` boundary becomes
  a camelCase hump (`profile.list.add_button` → `listAddButton`).
- **Placeholders** use positional `%1$s` (→ `String` param) / `%1$d` (→ `Int` param) in
  the base value, ordered by index (`arg0, arg1, …`). `%%` is a literal percent.
  Substitution is plain text replacement, **not** locale-aware number formatting.
- **Build fails** on a leading-digit segment, a name collision within an object, or a
  Kotlin keyword as a function name.

A registry entry maps a namespace to its **target package** and **object name**. Most
namespaces are features (`…features.<name>.presentation`), but library namespaces point
at their own package, and the object name can be overridden where the derived name
wouldn't match the project's naming (e.g. a design-system prefix). Read the current
entries from `localizationNamespaces` in `shared/build.gradle.kts` — don't assume.

Dispatch logic — a `title()` that picks between two generated accessors — is **not** a
string. Keep it out of the generated object; it belongs on the type doing the choosing.

### Plurals (the codegen contract for plural keys)

- A plural key's **first placeholder must be `%1$d`** — it is both the count selector and
  substitution arg 1. Codegen **fails the build** if a plural key's leading placeholder
  isn't `%1$d`.
- Codegen emits a count-taking function calling `localisePlural`:
  `profile.count` → `fun count(arg0: Int): String = Localizer.localisePlural("profile.count", arg0, arg0.toString())`.
  Additional placeholders (`%2$s`, …) become extra params after `arg0`.
- Placeholders must be **consistent across all categories** of a language; codegen parses
  the param list from the base `other` template (always present).
- `%1$d` is still plain substitution, **not** ICU number formatting — `count(1000)` renders
  `1000`, not `1,000` / `1.000`. Plurals fix grammar, not number formatting.

## Adding a new string

1. Add the key (+ at least the `en` value) to `localization.json`.
2. Reference the generated accessor at the call site, e.g. `ProfileStrings.title()`
   (Kotlin) / `ProfileStrings().title()` (Swift). Run a Gradle sync / build so codegen
   regenerates.

**Plural string:** author the value as a category map (`{ "one": …, "other": … }`) with
`other` on `en`, and make `%1$d` the **first** placeholder in every category. Codegen emits
`fun key(arg0: Int)`. Every shipped language must cover all categories its plural rules can
produce (see "Adding a new language").

## Adding a new language

This is the convention the build guards most strictly — getting it wrong ships
silently-wrong plurals. For a language that has **plural keys**, it is **three steps**, not
just "add the code to the JSON":

1. **Translate** — add the language code to the relevant keys in `localization.json`. For
   plural keys, provide every category that language's rules can produce (e.g. `pl` →
   `one` / `few` / `many`).
2. **Add a `pluralCategory` branch** in `library/localization/PluralRules.kt` (and include
   the primary subtag in the co-located `pluralLanguages` set). The selector matches on the
   primary subtag, so `pl-PL` → `pl`.
3. **Add a `PluralRulesTest` row** verifying the branch against the CLDR sample data for
   that language.

An **expansion-guard** validation test fails the build if any language code in
`localization.json` has no `pluralCategory` branch — so a translation can't introduce a
language the selector doesn't cover (which would silently return `other` for every count).
Missing singular keys simply fall back to `en`. `LanguageController` picks the active
language from the OS locale (an in-app override seam via `Preferences` exists but no picker
UI ships yet).

## Rules

- **`State` fields stay plain `String`.** Never resolve a generated string into a stored
  `val` with an `XxxStrings` default — `val title: String = ProfileStrings.title()` runs
  at `State()` construction (in previews and the `NavigationViewModel<State>(State())`
  bootstrap), **before** the map is loaded, and returns the raw key.
- **Prefer a lazy computed getter on `State`:** `val title: String get() = ProfileStrings.title()`.
  It resolves at *access* (after load) and re-resolves on a language change. The field is
  still a plain `String` to callers; only resolution is deferred. Resolving once in the VM
  body via `state = state.copy(title = …)` also works but snapshots the value and goes
  stale on a mid-session language switch — prefer the getter.
- Plural categories are likewise resolved at runtime by the active language — same
  load-ordering caveat as singular strings.
- **Previews pass literal strings**, never call `XxxStrings.*` (the map isn't loaded in the
  preview process). A computed-getter field can't be overridden with a literal, so it
  renders the raw key in a preview — for fields a preview must render, keep them plain
  stored fields set in the VM body and pass a literal; use the getter for fields previews
  don't read.
- Never hardcode user-facing English in `*.kt` / `*.swift` — author it in the JSON.

## Testing

Pure-JVM tests live in `shared/src/androidUnitTest/.../library/localization/`. Run them
with `./gradlew :shared:testDebugUnitTest`.

- `LocalizerTest` — lookup, `%1$s` substitution, base fallback, missing-key → key; plural
  category hit, missing-category → `other` fallback, `%1$d` substitution, unloaded/missing → key.
- `PluralRulesTest` — table-driven verification of `pluralCategory` against the published
  CLDR sample integers, one row per language (the correctness anchor for the selector).
- `LocalizationJsonValidationTest` — the silent-at-runtime mistakes the compiler can't
  catch: JSON parses, no duplicate keys, every key has a base value, placeholders consistent
  across languages; plural **shape consistency** (a key is plural in all languages or none),
  base `other` present on every plural key, **per-language category coverage**, and the
  **expansion guard** (every language in the JSON has a `pluralCategory` branch).
