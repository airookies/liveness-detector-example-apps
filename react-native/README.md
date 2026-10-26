# React Native example (0.88, TypeScript)

## Setup
1. Registry access: `export CLOUDSMITH_TOKEN=<token>` in your shell profile. The repository (`airookies/liveness-detector`) is already set in [`.npmrc`](.npmrc). See the [root README](../README.md).
2. Install and run:
   ```sh
   npm install
   npm run android
   cd ios && bundle install && bundle exec pod install && cd .. && npm run ios
   ```

## What to copy into your app
- **[`.npmrc`](.npmrc)**: routes the `@airookies` scope to Cloudsmith. The token comes from `CLOUDSMITH_TOKEN`, so the file is safe to commit.
- **Dependency:** `npm install @airookies/react-native-liveness-detector@5.0.0`. The package contains the native SDK for both platforms.
- **[`android/build.gradle`](android/build.gradle):** `minSdkVersion = 26`. The template uses 24.
- **[`ios/LivenessExample/Info.plist`](ios/LivenessExample/Info.plist):** `NSCameraUsageDescription`.
- **[`src/liveness.ts`](src/liveness.ts)**:
  - `runLiveness`.
  - `FaceMatchApi`: session, challenge and face-match.
  - `readBase64`, which reads evidence files with `fetch`, so no file-system library is needed.
  - `reasonMessage`.

## Changes from the template
- `react-native-image-picker` was added for the ID photo.
- The template's welcome screen and Jest setup were removed.
- `tsconfig.json` sets `types: []` because Jest is gone.

## Notes
- The SDK supports React Native 0.76 or later, on the old or new architecture.
  - On 0.76–0.81 with Xcode 26, add the `fmt` fix from the React Native integration guide to your `Podfile`.
  - Expo works with `expo prebuild` and the package's config plugin; see the integration guide.
- `start()` resolves for every outcome. It rejects only when no screen can be presented.
- The SDK's simulator slice is arm64 only (Apple silicon Macs). Builds that also target an x86_64 simulator fail with `LivenessDetector-Swift.h` not found or `unsupported Swift architecture`, for example Xcode's "Any iOS Simulator Device". Build for a device, or for an arm64 simulator.
