# iOS example (Swift, SwiftUI)

## Setup
1. Registry access: put `machine dl.cloudsmith.io login token password <token>` in `~/.netrc` and run `chmod 600 ~/.netrc`. Set your `ORG/REPO` in [`LivenessDetectorPackage/Package.swift`](LivenessDetectorPackage/Package.swift). See the [root README](../README.md).
2. Open `LivenessExample.xcodeproj`, choose your team under Signing & Capabilities, and run it on an iPhone.
   - Xcode resolves the package and downloads both frameworks.
   - If resolution fails, check `~/.netrc`, then use File > Packages > Reset Package Caches.

## What to copy into your app
- **[`LivenessDetectorPackage/`](LivenessDetectorPackage)**: a Swift package that wraps the two binary frameworks, `LivenessDetector` (the API and screen) and `LivenessCore` (the engine and models).
  - Copy the folder into your repo and add it with File > Add Package Dependencies… > Add Local…, then link the `LivenessDetector` product.
  - Or host it in a git repository of your own.
  - For a new SDK version, update `version` and both checksums.
- **`Info.plist`** (set in [`project.yml`](project.yml)):
  - `NSCameraUsageDescription` is required. Without it, the check ends with `camera_unavailable`.
  - Optionally, `LSApplicationQueriesSchemes: [cydia]` for one of the jailbreak checks.
- **[`LivenessIntegration.swift`](LivenessExample/LivenessIntegration.swift)**:
  - `runLiveness`: `LivenessDetector.start` as async/await, presented from SwiftUI.
  - `FaceMatchApi`: session, challenge and face-match.
  - `LivenessReason.message`.

## Notes
- Requirements: iOS 15, Xcode 26 or later. The SDK ships a Swift interface built with Xcode 26.
- The SDK's simulator slice is arm64 only, so the project sets `EXCLUDED_ARCHS[sdk=iphonesimulator*] = x86_64`. The simulator only builds; the check needs a device camera.
- The project is generated from [`project.yml`](project.yml) with XcodeGen (`brew install xcodegen && xcodegen generate`). The generated `.xcodeproj` is committed, so you only need XcodeGen to change it.
- `NSAllowsLocalNetworking` is only so the backend flow can reach an `http://` session server on your network.
