# Android example (Kotlin, Jetpack Compose)

## Setup
1. Registry access: `cloudsmithToken=<token>` in `~/.gradle/gradle.properties`, and your `ORG/REPO` in [`settings.gradle.kts`](settings.gradle.kts) (see the [root README](../README.md)).
2. Open this folder in Android Studio, or run `./gradlew installDebug` with a phone connected.

## What to copy into your app
- **[`settings.gradle.kts`](settings.gradle.kts)**: the Cloudsmith Maven repository, which uses basic auth with username `token` and your token as the password. `includeGroup("mn.ekyc")` keeps Gradle from looking for other libraries there.
- **[`app/build.gradle.kts`](app/build.gradle.kts)**: `implementation("mn.ekyc:liveness-detector:5.0.0")` and `minSdk = 26`.
  - The SDK brings CameraX, its R8 rules and the `CAMERA` permission, and asks for the permission itself.
- **[`LivenessIntegration.kt`](app/src/main/java/mn/ekyc/example/liveness/LivenessIntegration.kt)**:
  - `runLiveness`: `LivenessDetector.start` as a suspend function.
  - `FaceMatchApi`: session, challenge and face-match.
  - `LivenessReason.message()`.
- **[`MainActivity.kt`](app/src/main/java/mn/ekyc/example/liveness/MainActivity.kt)**: calls the SDK from Compose. It passes the `ComponentActivity`, collects the result in a coroutine, and picks the ID photo with `PickVisualMedia`.

## Notes
- Requirements: `minSdk` 26, `compileSdk` 34+, AGP 8.1+, Kotlin 1.9+.
- Release builds use R8 (`isMinifyEnabled = true`) and need no extra rules.
- The manifest has `usesCleartextTraffic` only so the backend flow can reach an `http://` session server on your computer (`adb reverse tcp:4000 tcp:4000`). Remove it in your app.
