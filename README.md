# LivenessDetector example apps

Small apps that show how to integrate LivenessDetector 5 into your own app. Each one installs the SDK from the private Cloudsmith repository, exactly as your app will.

Docs for clients (Mongolian): <https://airookies.github.io/liveness-detector-example-apps/>.

| App | Folder | Stack |
| --- | --- | --- |
| Android | [`android/`](android) | Kotlin, Jetpack Compose |
| iOS | [`ios/`](ios) | Swift, SwiftUI, Swift Package Manager |
| React Native | [`react-native/`](react-native) | React Native 0.88, TypeScript |
| Flutter | [`flutter/`](flutter) | Flutter 3.44, Dart |

Every app has the same two screens:

- **Quick start**: runs the check with a challenge the SDK picks (one head turn, four colours) and shows the result: status, steps, selfie, evidence files. No backend needed, so start here.
- **Backend flow**: the real integration. It creates a session, gets a challenge from Face Match, runs the check, sends the evidence and an ID photo to face-match, and prints the response, including the verification token.

The integration code sits in one file per app, so you can copy it into your project. UI code is kept separate.

| App | Integration file |
| --- | --- |
| Android | [`LivenessIntegration.kt`](android/app/src/main/java/mn/ekyc/example/liveness/LivenessIntegration.kt) |
| iOS | [`LivenessIntegration.swift`](ios/LivenessExample/LivenessIntegration.swift) and [`Package.swift`](ios/LivenessDetectorPackage/Package.swift) |
| React Native | [`src/liveness.ts`](react-native/src/liveness.ts) |
| Flutter | [`lib/liveness.dart`](flutter/lib/liveness.dart) |

## 1. Registry access (once per computer)

You receive two things from us:
- the repository, `airookies/liveness-detector` (the same for everyone);
- an **entitlement token**, which is read-only and specific to your company.

**Never commit the token.** Every setup below keeps it in your home directory or your shell environment.

Store the token for the platforms you use:

| Platform | Where the token goes |
| --- | --- |
| Android (Gradle) | `~/.gradle/gradle.properties`: `cloudsmithToken=<token>` |
| iOS (SwiftPM / Xcode) | `~/.netrc`: `machine dl.cloudsmith.io login token password <token>`, then `chmod 600 ~/.netrc` (or download the frameworks by hand, see [`ios/README.md`](ios/README.md#manual-download-without-swiftpm)) |
| React Native (npm) | your shell profile (`~/.zshrc`): `export CLOUDSMITH_TOKEN=<token>` (`.npmrc` reads it) |
| Flutter (pub) | once: `echo '<token>' \| dart pub token add https://dart.cloudsmith.io/airookies/liveness-detector/` |

On CI, set the same values as secrets: a Gradle property or `ORG_GRADLE_PROJECT_cloudsmithToken`, a `.netrc` written by the job, and `CLOUDSMITH_TOKEN`. For Flutter on CI, run `dart pub token add https://dart.cloudsmith.io/airookies/liveness-detector/ --env-var CLOUDSMITH_TOKEN`.

## 2. Run

Use a real phone. Emulators and simulators have no camera, and the SDK's device checks reject them (`integrity_failed`).

- **Android:** open `android/` in Android Studio and run it, or run `cd android && ./gradlew installDebug`.
- **iOS:** open `ios/LivenessExample.xcodeproj`, set your team under Signing & Capabilities, and run it on a device. Xcode downloads the SDK through `~/.netrc`.
- **React Native:** `cd react-native && npm install`, then `npm run android`, or `cd ios && bundle install && bundle exec pod install && cd .. && npm run ios`.
- **Flutter:** `cd flutter && flutter pub get && flutter run`.

Each folder's README has the platform details: minimum versions, permissions, and what changed from the template.

## 3. The backend flow

```
your backend        POST <session URL>                 -> request_id, row_id, session_token
app -> Face Match   POST /api/client/challenge          -> challenge_id, colors, actions
app                 LivenessDetector.start(challenge)    -> result + evidence files
app -> Face Match   POST /api/client/face-match         -> scores, verification_token
your backend        POST /api/client/verify (with the verification token, using your backend key)
```

- A challenge is single-use and valid for 90 seconds, so fetch a new one for each attempt.
- Upload only when `status` is `passed`. For every other outcome, show the message for its `reason`; each app has the suggested texts in English and Mongolian.

**The API key.** The example apps take the Face Match base URL, API key and session URL as inputs so you can try them quickly. In production, never ship an API key in an app: your backend should create the session and hold the key.

**Local session server.** To use one running on your computer:
- Android: run `adb reverse tcp:4000 tcp:4000`, and `http://localhost:4000/...` works on the phone.
- iPhone: use your computer's LAN address, e.g. `http://192.168.1.10:4000/...`.

## More

- **Integration guides** (options, theme and strings, headless mode, every result field), sent with your access:
  - Overview: `README.md`
  - Android: `android.md`
  - iOS: `ios.md`
  - React Native: `react-native.md`
  - Flutter: `flutter.md`
- **Logs:**
  - Android: logcat tag `LivenessCore`.
  - iOS: subsystem `mn.ekyc.LivenessDetector`.
