# Flutter example (3.44, Dart)

## Setup
1. Registry access: once per computer:
   ```sh
   echo '<token>' | dart pub token add https://dart.cloudsmith.io/airookies/liveness-detector/
   ```
   On CI, use `--env-var CLOUDSMITH_TOKEN` instead of piping the token. The repository is already set in [`pubspec.yaml`](pubspec.yaml). See the [root README](../README.md).
2. `flutter pub get && flutter run` with a phone connected.

## What to copy into your app
- **[`pubspec.yaml`](pubspec.yaml)**: `liveness_detector` as a `hosted:` dependency from Cloudsmith. The plugin contains the native SDK for both platforms.
- **[`android/app/build.gradle.kts`](android/app/build.gradle.kts)**: `minSdk = 26`. The template uses `flutter.minSdkVersion`.
- **[`ios/Runner/Info.plist`](ios/Runner/Info.plist)**: `NSCameraUsageDescription`. Also set the iOS deployment target to 15.0 (Runner target, and `platform :ios, '15.0'` if you use CocoaPods).
- **[`lib/liveness.dart`](lib/liveness.dart)**:
  - `runLiveness`.
  - `FaceMatchApi`: session, challenge and face-match.
  - `reasonMessage`.

## Notes
- Requirements: Flutter 3.24 or later (Dart 3.5). The plugin works with Swift Package Manager (the default from 3.44) and with CocoaPods.
- The plugin starts its own Activity, so `FlutterActivity` is fine as it is.
- Added packages: `http`, `image_picker` (ID photo, which needs `NSPhotoLibraryUsageDescription`) and `shared_preferences`.
- `usesCleartextTraffic` and `INTERNET` in the Android manifest are for the backend flow against a local `http://` session server.
- The SDK's simulator slice is arm64 only (Apple silicon Macs). Builds that also target an x86_64 simulator fail with `LivenessDetector-Swift.h` not found or `unsupported Swift architecture`, for example `flutter build ios --simulator`. Build for a device, or for an arm64 simulator.
