# React Native

## Шаардлага

- React Native 0.76+, хуучин болон шинэ архитектур хоёуланд ажиллана.
- iOS 15, Android API 26 (`minSdkVersion`-ыг template-ийн 24-өөс 26 болгоно).
- Expo: `expo prebuild`-ээр development build хийнэ. Expo Go-д ажиллахгүй.

## Суулгах

Токеныг environment хувьсагчаар өгч, `@airookies` scope-ыг төслийн `.npmrc`-д заана.

```sh
export CLOUDSMITH_TOKEN=<token>
```

```ini
@airookies:registry=https://npm.cloudsmith.io/airookies/liveness-detector/
//npm.cloudsmith.io/airookies/liveness-detector/:_authToken=${CLOUDSMITH_TOKEN}
```

```sh
npm install @airookies/react-native-liveness-detector
```

Package нь хоёр платформын native SDK-г агуулсан тул өөр зүйл татах шаардлагагүй.

**Android:** `android/build.gradle` дотор `minSdkVersion = 26` болгоно.

**iOS:** `ios/<App>/Info.plist`-д `NSCameraUsageDescription` нэмээд `cd ios && pod install` ажиллуулна. RN 0.76–0.81 + Xcode 26 дээр `fmt` алдаа гарвал: [Алдаа засах](/guide/troubleshooting).

**Expo:** config plugin нэмж, `expo-build-properties`-оор Android-ийн доод хувилбарыг өсгөнө. Дараа нь `npx expo prebuild`.

```json
{
  "expo": {
    "plugins": [
      ["@airookies/react-native-liveness-detector", { "cameraPermission": "Камерыг таныг байгаа эсэхийг шалгахад ашиглана." }],
      ["expo-build-properties", { "android": { "minSdkVersion": 26 } }]
    ]
  }
}
```

## Хэрэглээ

```ts
import { start } from '@airookies/react-native-liveness-detector';

const challenge = await fetchChallenge(); // POST /api/client/challenge
const result = await start({
  challenge: { id: challenge.challenge_id, colors: challenge.colors, actions: challenge.actions },
  locale: 'mn',
});

if (result.status === 'passed') {
  // file:// хаягийг base64 болгох readBase64: /guide/backend
  const selfie = await readBase64(result.selfie!.uri);
  const zip = await readBase64(result.archive!.uri);
  await faceMatch({ challenge_id: result.challengeId, integrity: result.integrity, selfie, zip });
} else {
  showError(result.reason); // 'step_timeout', 'camera_permission_denied', 'integrity_failed', …
}
```

`start` цуцлалт, алдаа зэрэг бүх үр дүнд resolve хийнэ. Дэлгэц гаргах боломжгүй (`no_activity`, `no_view_controller`) эсвэл тохиргоо буруу (`invalid_options`) үед л reject хийнэ.

Жишээ апп: [react-native](https://github.com/airookies/liveness-detector-example-apps/tree/main/react-native). Үргэлжлүүлэн [Backend урсгал](/guide/backend) болон [Үр дүн ба шалтгаан](/guide/result) хэсгийг үзнэ үү.
