# Flutter

## Шаардлага

- Flutter 3.24+ (Dart 3.5).
- iOS 15, Android API 26.
- iOS дээр Swift Package Manager эсвэл CocoaPods аль алиныг нь дэмжинэ.

## Суулгах

Токеныг компьютер бүр дээр нэг удаа бүртгэнэ.

```sh
echo '<token>' | dart pub token add https://dart.cloudsmith.io/airookies/liveness-detector/
```

CI дээр environment хувьсагчаар: `dart pub token add https://dart.cloudsmith.io/airookies/liveness-detector/ --env-var CLOUDSMITH_TOKEN`.

```yaml
# pubspec.yaml
dependencies:
  liveness_detector:
    hosted: https://dart.cloudsmith.io/airookies/liveness-detector/
    version: ^5.0.0
```

Plugin хоёр платформын native SDK-г агуулсан.

**Android:** `android/app/build.gradle` дотор `minSdk = 26` болгоно. Plugin өөрийн Activity-г эхлүүлдэг тул `FlutterActivity` хэвээр байж болно.

**iOS:** `ios/Runner/Info.plist`-д `NSCameraUsageDescription` нэмж, deployment target-ыг 15.0 болгоно. CocoaPods ашигладаг бол `Podfile`-д `platform :ios, '15.0'`.

## Хэрэглээ

```dart
import 'package:liveness_detector/liveness_detector.dart';

final result = await LivenessDetector.start(LivenessOptions(
  challenge: Challenge(
    id: challenge['challenge_id'],
    colors: List<String>.from(challenge['colors']),
    actions: const [LivenessAction.turnLeft, LivenessAction.blink],
  ),
  locale: 'mn',
));

if (result.status == LivenessStatus.passed) {
  final selfie = base64Encode(await result.selfie!.file.readAsBytes());
  final zip = base64Encode(await result.archive!.file.readAsBytes());
  await faceMatch(challengeId: result.challengeId, integrity: result.integrity, selfie: selfie, zip: zip);
} else {
  showError(result.reason); // LivenessReason.stepTimeout, cameraPermissionDenied, …
}
```

`start` бүх үр дүнд (цуцлалт, алдаа орно) дуусна. Дэлгэц гаргах боломжгүй (`no_activity`, `no_view_controller`) эсвэл тохиргоо буруу (`invalid_options`) үед л `PlatformException` шидэнэ.

Жишээ апп: [flutter](https://github.com/airookies/liveness-detector-example-apps/tree/main/flutter). Үргэлжлүүлэн [Backend урсгал](/guide/backend) болон [Үр дүн ба шалтгаан](/guide/result) хэсгийг үзнэ үү.
