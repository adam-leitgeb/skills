---
name: rename-template
description: Rename a freshly-cloned fosh-labs KMP template to a new project — sets the project name, package / applicationId, iOS bundle id, and display name across Android, shared Kotlin, and iOS in one pass. Use right after cloning the template, or when the user asks to rename the template or set up a new project from it.
argument-hint: "<Display Name> <package/bundle id> — e.g. Acme com.acme.app"
---

# Rename the KMP Template to a New Project

Turns a fresh clone of the fosh-labs KMP template into a named project: renames the
package (Android `applicationId` + `namespace`, shared Kotlin, SQLDelight), the iOS
bundle id, and the app display name.

## The template's starting identifiers

| What | Current value | Lives in |
|---|---|---|
| Gradle project name | `KMP-App-Template-Native` | `settings.gradle.kts` |
| Package / applicationId / namespace | `com.foshlabs.kmpapp` | ~140 `.kt`/`.kts`/`.xml`/`.sq` files + 6 source dirs |
| Android app name | `KMP App` | `composeApp/src/androidMain/res/values/strings.xml` |
| iOS bundle id | `com.jetbrains.kmpapp.KMP-App-Template-Native` *(stale — note the different root)* | `iosApp/Configuration/Config.xcconfig` |
| iOS app name | `KMP App` | `iosApp/Configuration/Config.xcconfig` |

iOS reads `BUNDLE_ID`, `APP_NAME`, `TEAM_ID` from `Config.xcconfig` via `${…}` in the
Xcode project, so **no `project.pbxproj` edits are needed.**

## Step 0 — Gather inputs and a clean slate

Ask the user (don't guess) and confirm before touching anything:

- **Display name** — e.g. `Acme` (Android + iOS app name).
- **Package / applicationId** — e.g. `com.acme.app` (replaces `com.foshlabs.kmpapp`).
- **iOS bundle id** — defaults to the package.
- **Apple Team ID** — optional; needed only to run on a device.

Then ensure `git status` is clean and **work on a branch** — the rename is a large,
reviewable, revertible diff. Set the working variables:

```bash
OLD_PKG="com.foshlabs.kmpapp";  OLD_PATH="com/foshlabs/kmpapp"
NEW_PKG="com.acme.app"                       # <- set from user input
NEW_PATH="${NEW_PKG//.//}"                    # -> com/acme/app
```

## Step 1 — Rename the package (Android + shared Kotlin + SQLDelight)

Two parts: replace the string in file **contents**, then move the source **directories**.

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

`settings.gradle.kts`: `rootProject.name = "KMP-App-Template-Native"` → the project name
(no spaces, e.g. `"Acme"`).

## Step 3 — Display name

- `composeApp/src/androidMain/res/values/strings.xml`:
  `<string name="app_name">KMP App</string>` → `<string name="app_name">Acme</string>`
- `iosApp/Configuration/Config.xcconfig`: `APP_NAME=KMP App` → `APP_NAME=Acme`

## Step 4 — iOS bundle id (and team)

In `iosApp/Configuration/Config.xcconfig`:

- `BUNDLE_ID=com.jetbrains.kmpapp.KMP-App-Template-Native` → `BUNDLE_ID=com.acme.app`
  (drop the stale `jetbrains` root and the template suffix — set it to the clean bundle id).
- `TEAM_ID=` → the Apple Team ID, if the user provided one.

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
