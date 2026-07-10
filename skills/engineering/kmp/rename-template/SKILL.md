---
name: rename-template
description: Rename a freshly-cloned fosh-labs KMP template to a new project. Give it the project name; it derives the Gradle/repo name, package (= applicationId = namespace), and iOS bundle id from the fosh-labs naming convention, confirms, then makes every edit across Android, shared Kotlin, and iOS so the project is dev-ready. Use right after cloning the template, or when the user asks to rename the template or set up a new project from it.
argument-hint: "<project name> — e.g. Acme Todo"
---

# Rename the KMP Template to a New Project

Takes a fresh clone of the fosh-labs KMP template and makes it a named, dev-ready
project. **You give one thing — the project name.** The skill derives every identifier
from it, confirms them, then renames the package (Android `applicationId` + `namespace`,
shared Kotlin, SQLDelight), the iOS bundle id, the Gradle project name, and the display
name.

## Naming convention (how identifiers are derived)

From a project name like **`Acme Todo`**:

| Identifier | Rule | Example |
|---|---|---|
| Display name (app name) | the project name, as given | `Acme Todo` |
| App segment | lowercase, strip everything non-alphanumeric | `acmetodo` |
| Package / `applicationId` / `namespace` / iOS bundle id | `<prefix>.<segment>` — **identical** on both platforms | `com.foshlabs.acmetodo` |
| Gradle `rootProject.name` / repo name | kebab-case + `-kmp` suffix | `acme-todo-kmp` |

The **prefix is asked every run** (default `com.foshlabs`, but override it for client
work — that's why it isn't baked in).

## The template's starting identifiers (what gets replaced)

| What | Current value | Lives in |
|---|---|---|
| Gradle project name | `KMP-App-Template-Native` | `settings.gradle.kts` |
| Package / applicationId / namespace | `com.foshlabs.kmpapp` | ~140 `.kt`/`.kts`/`.xml`/`.sq` files + 6 source dirs |
| Android app name | `KMP App` | `composeApp/src/androidMain/res/values/strings.xml` |
| iOS bundle id | `com.jetbrains.kmpapp.KMP-App-Template-Native` *(stale — different root)* | `iosApp/Configuration/Config.xcconfig` |
| iOS app name | `KMP App` | `iosApp/Configuration/Config.xcconfig` |

iOS reads `BUNDLE_ID`, `APP_NAME`, `TEAM_ID` from `Config.xcconfig` via `${…}` in the
Xcode project, so **no `project.pbxproj` edits are needed.**

## Step 0 — Derive, confirm, clean slate

Get the **project name** (from the argument, or ask). Ask for the **ID prefix** (default
`com.foshlabs`) and the optional **Apple Team ID** (needed only to run on a device).
Then derive the values and set the working variables:

```bash
PROJECT_NAME="Acme Todo"          # from the user
PREFIX="com.foshlabs"             # asked each run

SEGMENT="$(printf '%s' "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]')"
NEW_PKG="$PREFIX.$SEGMENT"                                     # = applicationId = bundle id
SLUG="$(printf '%s' "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')-kmp"
DISPLAY="$PROJECT_NAME"

OLD_PKG="com.foshlabs.kmpapp";  OLD_PATH="com/foshlabs/kmpapp";  NEW_PATH="${NEW_PKG//.//}"
```

**Show the user the derived table and confirm** before editing:

```
Display name : Acme Todo
Package / id : com.foshlabs.acmetodo   (Android applicationId + namespace, iOS bundle id)
Project/repo : acme-todo-kmp
```

Ensure `git status` is clean and **work on a branch** — the rename is a large, reviewable,
revertible diff.

## Step 1 — Rename the package (Android + shared Kotlin + SQLDelight)

Replace the string in file **contents**, then move the source **directories**.

```bash
# 1a) Replace the package string everywhere (content-based, path-independent)
grep -rlZ --include='*.kt' --include='*.kts' --include='*.xml' --include='*.sq' \
  --exclude-dir={build,.git,.gradle,.kotlin,.idea} "$OLD_PKG" . \
  | xargs -0 perl -pi -e "s/\\Q$OLD_PKG\\E/$NEW_PKG/g"

# 1b) Move the package directories in each source set, then drop empty leftovers
for base in \
  composeApp/src/androidMain/kotlin \
  shared/src/androidMain/kotlin \
  shared/src/androidUnitTest/kotlin \
  shared/src/commonMain/kotlin \
  shared/src/commonMain/sqldelight \
  shared/src/iosMain/kotlin ; do
  [ -d "$base/$OLD_PATH" ] || continue
  mkdir -p "$base/$(dirname "$NEW_PATH")"
  git mv "$base/$OLD_PATH" "$base/$NEW_PATH"
  find "$base/com" -type d -empty -delete 2>/dev/null || true
done
```

This also fixes `applicationId`/`namespace` in `composeApp/build.gradle.kts`, the shared
`namespace` (`…​.shared`) and SQLDelight `packageName` (`…​.database`) in
`shared/build.gradle.kts` — they're all `com.foshlabs.kmpapp*` and caught by 1a.

## Step 2 — Gradle project name

`settings.gradle.kts`: `rootProject.name = "KMP-App-Template-Native"` → `"$SLUG"`
(e.g. `"acme-todo-kmp"`).

## Step 3 — Display name

- `composeApp/src/androidMain/res/values/strings.xml`:
  `<string name="app_name">KMP App</string>` → `…>$DISPLAY</string>`
- `iosApp/Configuration/Config.xcconfig`: `APP_NAME=KMP App` → `APP_NAME=$DISPLAY`

## Step 4 — iOS bundle id (and team)

In `iosApp/Configuration/Config.xcconfig`:

- `BUNDLE_ID=com.jetbrains.kmpapp.KMP-App-Template-Native` → `BUNDLE_ID=$NEW_PKG`
  (identical to the Android `applicationId`; this also drops the stale `jetbrains` root).
- `TEAM_ID=` → the Apple Team ID, if provided.

## Step 5 — Optional cleanup (only if asked)

- **Scene type:** rename `TemplateAppScene` → `{App}Scene` in `application/AppScene.kt`
  and its references.
- **Android app class:** the template ships a sample `MuseumApp` class
  (`composeApp/src/androidMain/.../app/MuseumApp.kt`, referenced as `.app.MuseumApp` in
  `AndroidManifest.xml`). Rename to `{App}App` if you want it gone.
- The Kotlin→native framework is named `Shared` (`import Shared` on iOS). Leave it — it's
  an internal module name, not user-facing.

## Step 6 — Verify

```bash
# No stray template identifiers should remain (org.jetbrains.kotlin plugin imports are fine).
grep -rn --exclude-dir={build,.git,.gradle,.kotlin,.idea} \
  -e "com.foshlabs.kmpapp" -e "com.jetbrains.kmpapp" \
  -e "KMP-App-Template-Native" . || echo "clean"

./gradlew :composeApp:assembleDebug          # Android builds with the new id
```

For iOS, open `iosApp/iosApp.xcodeproj` in Xcode and build the `iosApp` scheme; confirm
the bundle id and display name are the new values. Leftover `KMP App` in `README.md` /
`CLAUDE.md` is cosmetic — update the docs if the user wants.
