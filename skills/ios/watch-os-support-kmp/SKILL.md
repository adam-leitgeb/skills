---
name: watch-os-support-kmp
description: Adding watchOS support to a Kotlin Multiplatform iOS app where the watch app depends on shared code. Use when configuring a watchOS target.
user-invocable: false
---


# Cursor Rules: Adding watchOS Support to Kotlin Multiplatform iOS App

## Overview
When adding watchOS support to a Kotlin Multiplatform iOS app where the watch app needs to depend on shared code, follow these essential steps to ensure proper build configuration.

## Required Changes

### 1. Gradle Configuration (`shared/build.gradle.kts`)

**Add watchOS targets:**
```kotlin
val watchosArm64 = watchosArm64()
val watchosDeviceArm64 = watchosDeviceArm64() // Required for real watchOS device builds
val watchosX64 = watchosX64()
val watchosSimulatorArm64 = watchosSimulatorArm64()

// Create watchOS XCFramework
val watchosXcFramework = XCFramework("SharedWatch")

// Build watchOS frameworks
listOf(
    watchosArm64,
    watchosX64,
    watchosSimulatorArm64,
    watchosDeviceArm64 // Required for real watchOS device builds
).forEach { target ->
    target.binaries.framework {
        baseName = "SharedWatch"
        isStatic = true
        watchosXcFramework.add(this)
    }
}
```

**Add watchOS source sets:**
```kotlin
sourceSets {
    watchosMain.dependencies {
        implementation(libs.ktor.client.darwin) // if using Ktor
    }
    // ... other source sets
}
```

**Add watchOS Gradle tasks:**
```kotlin
tasks.register("embedAndSignAppleFrameworkForWatchXcode") {
    dependsOn("assembleSharedWatchDebugXCFramework")
}
```

### 2. Xcode Project Configuration

**Add "Compile Kotlin Watch Framework" build phase to watch app target:**
- Target: `TallyCounter Watch App`
- Script: `./gradlew :shared:embedAndSignAppleFrameworkForWatchXcode`
- Add to `buildPhases` array in `project.pbxproj`
- Place BEFORE Sources phase

**Disable User Script Sandboxing:**
- Set `ENABLE_USER_SCRIPT_SANDBOXING = NO` for watch app target
- Apply to both Debug and Release configurations

**Add framework search paths:**
- Add `$(SRCROOT)/../shared/build/XCFrameworks/$(CONFIGURATION:lower)/` to watch app target
- Use XCFrameworks directory (not xcode-frameworks)
- Apply to both Debug and Release configurations
- Format as array with `$(inherited)` and custom path
- Note: `$(CONFIGURATION:lower)` resolves to `debug`/`release` (lowercase)

**Link the framework:**
- Add `SharedWatch.xcframework` to watch app target's "Frameworks, Libraries, and Embedded Content"
- Set to "Do Not Embed" (static framework)
- Framework location: `shared/build/XCFrameworks/debug/SharedWatch.xcframework`
- **Critical**: Framework must be explicitly linked, not just searchable

### 3. Build Process

**Build order:**
1. Build iOS app first: `xcodebuild -scheme iosApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=18.6' build`
2. Build watch app: `xcodebuild -scheme "TallyCounter Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (42mm),OS=26.0' build`

**Troubleshooting:**
- Stop Gradle daemon if builds fail: `./gradlew --stop`
- Ensure correct simulator names/versions are available
- Verify framework search paths include watchOS frameworks

**Common Issues & Solutions:**

**"No such module 'SharedWatch'" error:**
- Ensure framework is linked in "Frameworks, Libraries, and Embedded Content"
- Verify Framework Search Paths use `XCFrameworks/$(CONFIGURATION:lower)/` (not `xcode-frameworks`)
- Framework must be explicitly linked, not just searchable via search paths
- Clean build folder and rebuild

**Real device build failures (iOS app with embedded watch app):**
- Error: `While building for iOS, no library for this platform was found in SharedWatch.xcframework`
- Cause: Missing `watchosDeviceArm64()` target in Gradle configuration
- Solution: Add `watchosDeviceArm64()` target to `shared/build.gradle.kts` (see section 1)
- Without this target, the XCFramework only contains simulator slices, causing failures when building for physical devices

**Directory structure differences:**
- iOS app: `shared/build/xcode-frameworks/$(CONFIGURATION)/$(SDK_NAME)/`
- Watch app: `shared/build/XCFrameworks/$(CONFIGURATION:lower)/`
- `$(CONFIGURATION:lower)` resolves to `debug`/`release` (lowercase)
- Both apps use different build output directories

**Framework not found:**
- Verify build script runs before Sources phase
- Check that `SharedWatch.xcframework` exists in expected location
- Ensure framework is set to "Do Not Embed" for static frameworks

## Key Points
- Watch app uses different Gradle task than iOS app (`embedAndSignAppleFrameworkForWatchXcode` vs `embedAndSignAppleFrameworkForXcode`)
- User script sandboxing must be disabled for Gradle execution
- Both iOS and watchOS targets can be built in single `iosApp` scheme build
- Watch app gets embedded in iOS app's `Watch/` folder during build
- WatchOS frameworks are generated as `SharedWatch.xcframework`

## Critical Configuration Details

**Framework Search Paths Format:**

**iOS App:**
```
FRAMEWORK_SEARCH_PATHS = (
    "$(inherited)",
    "$(SRCROOT)/../shared/build/xcode-frameworks/$(CONFIGURATION:lower)/$(SDK_NAME)",
);
```

**Watch App:**
```
FRAMEWORK_SEARCH_PATHS = (
    "$(inherited)",
    "$(SRCROOT)/../shared/build/XCFrameworks/$(CONFIGURATION:lower)/",
);
```

**Directory Structure:**
- iOS app: `shared/build/xcode-frameworks/Debug/iphoneos26.0/Shared.framework`
- Watch app: `shared/build/XCFrameworks/debug/SharedWatch.xcframework`
- Different build output directories for iOS vs watchOS

**Build Script Order:**
1. Compile Kotlin Watch Framework (runs Gradle task)
2. Sources (compiles Swift code)
3. Frameworks (links frameworks)
4. Resources (copies assets)

## Complete Setup Checklist

### ✅ Required Steps for Watch App:
1. **Add build script** for Kotlin framework compilation
2. **Disable User Script Sandboxing** for watch app target
3. **Set Framework Search Paths** to `$(SRCROOT)/../shared/build/XCFrameworks/$(CONFIGURATION:lower)/`
4. **Link SharedWatch.xcframework** in "Frameworks, Libraries, and Embedded Content"
5. **Set framework to "Do Not Embed"** (static framework)
6. **Initialize Koin** in watch app's `init()` method

### ⚠️ Common Pitfalls:
- Framework Search Paths ≠ Framework Linking (both required)
- iOS uses `xcode-frameworks`, watchOS uses `XCFrameworks`
- `$(CONFIGURATION:lower)` for watchOS, `$(CONFIGURATION)` for iOS
- Framework must be explicitly linked, not just searchable
