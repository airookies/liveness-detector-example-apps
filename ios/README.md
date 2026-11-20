# iOS example (Swift, SwiftUI)

## Setup
1. SDK frameworks: we send you `LivenessDetector.xcframework.zip`, `LivenessCore.xcframework.zip` and `SHA256SUMS` for each version. No token is needed. Check the zips with `shasum -a 256 -c SHA256SUMS --ignore-missing`, then unzip both into [`LivenessDetectorPackage/`](LivenessDetectorPackage), next to `Package.swift`:
   ```sh
   unzip LivenessDetector.xcframework.zip -d LivenessDetectorPackage
   unzip LivenessCore.xcframework.zip -d LivenessDetectorPackage
   ```
   The frameworks are git-ignored.
2. Open `LivenessExample.xcodeproj`, choose your team under Signing & Capabilities, and run it on an iPhone. If Xcode cannot find the frameworks, check that both folders sit next to `Package.swift`, then use File > Packages > Reset Package Caches.

## What to copy into your app
- **[`LivenessDetectorPackage/`](LivenessDetectorPackage)**: a Swift package that wraps the two binary frameworks, `LivenessDetector` (the API and screen) and `LivenessCore` (the engine and models).
  - Copy the folder into your repo and add it with File > Add Package Dependencies… > Add Local…, then link the `LivenessDetector` product.
  - For a new SDK version, replace both frameworks in the folder.
- **`Info.plist`** (set in [`project.yml`](project.yml)):
  - `NSCameraUsageDescription` is required. Without it, the check ends with `camera_unavailable`.
  - Optionally, `LSApplicationQueriesSchemes: [cydia]` for one of the jailbreak checks.
- **[`LivenessIntegration.swift`](LivenessExample/LivenessIntegration.swift)**:
  - `runLiveness`: `LivenessDetector.start` as async/await, presented from SwiftUI.
  - `FaceMatchApi`: session, challenge and face-match.
  - `LivenessReason.message`.

## Without SwiftPM
Add both frameworks to the target's **Frameworks, Libraries, and Embedded Content** and set both to **Embed & Sign**.

## Notes
- Requirements: iOS 15, Xcode 26 or later. The SDK ships a Swift interface built with Xcode 26.
- The SDK's simulator slice is arm64 only, so the project sets `EXCLUDED_ARCHS[sdk=iphonesimulator*] = x86_64`. The simulator only builds; the check needs a device camera.
- The project is generated from [`project.yml`](project.yml) with XcodeGen (`brew install xcodegen && xcodegen generate`). The generated `.xcodeproj` is committed, so you only need XcodeGen to change it.
- `NSAllowsLocalNetworking` is only so the backend flow can reach an `http://` session server on your network.
