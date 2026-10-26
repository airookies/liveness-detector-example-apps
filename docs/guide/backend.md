# Backend урсгал

SDK өөрөө сүлжээнд хандахгүй. Сорил (challenge) авах, нотлох файл (evidence files) илгээх ажлыг таны backend болон апп хийнэ.

## 4 алхам

1. **Session үүсгэх.** Таны backend Face Match дээр session үүсгэж, аппдаа `request_id`, `row_id`, `session_token` өгнө.
2. **Сорил авах.** `POST /api/client/challenge` дуудлагыг `X-API-KEY`-тэй хийнэ. Хариуд `challenge_id`, `colors`, `actions` ирнэ.
3. **Шалгалт ажиллуулах.** Апп сорилыг SDK-ийн `start` руу дамжуулна. `status` нь `passed` бол дараагийн алхам руу орно.
4. **Илгээх ба баталгаажуулах.** `POST /api/client/face-match` руу selfie, zip (base64), `challenge_id`, `integrity` илгээнэ. Дараа нь таны backend `verification_token`-оор `/api/client/verify`-г дуудаж эцсийн шийдвэрийг авна.

## face-match body

```json
{
  "request_id": "...", "row_id": 0,
  "challenge_id": "<result.challengeId>",
  "integrity": "<result.integrity>",
  "data": {
    "image1": {"base64": "<selfie JPEG, base64>", "border": false, "liveness_check": true, "sequence": "<evidence zip, base64>"},
    "image2": {"base64": "<ID photo, base64>", "border": true, "liveness_check": false, "sequence": ""}
  }
}
```

## Нотлох файлыг base64 болгох

::: code-group
```kotlin [Kotlin]
val selfie = Base64.encodeToString(result.selfie!!.file.readBytes(), Base64.NO_WRAP)
val zip = Base64.encodeToString(result.archive!!.file.readBytes(), Base64.NO_WRAP)
```
```swift [Swift]
let selfie = try Data(contentsOf: result.selfie!.url).base64EncodedString()
let zip = try Data(contentsOf: result.archive!.url).base64EncodedString()
```
```ts [TypeScript]
// RN-ийн fetch нь file:// URI-г уншина
async function readBase64(uri: string): Promise<string> {
  const blob = await (await fetch(uri)).blob();
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result).replace(/^data:.*?;base64,/, ''));
    reader.onerror = () => reject(reader.error);
    reader.readAsDataURL(blob);
  });
}
const selfie = await readBase64(result.selfie!.uri);
```
```dart [Dart]
final selfie = base64Encode(await result.selfie!.file.readAsBytes());
final zip = base64Encode(await result.archive!.file.readAsBytes());
```
:::

## Анхаарах зүйл

- Сорил нэг удаагийн бөгөөд 90 секунд хүчинтэй. Оролдлого бүрт шинээр аваарай.
- Нотлох файлыг зөвхөн `passed` үед илгээнэ.
- Production дээр API key зөвхөн таны backend дээр байна. Аппад хэзээ ч бүү оруул.
- Face Match-ийн хариу `data.response`, `response` эсвэл шууд JSON хэлбэртэй ирж болно. Жишээ апп гурвууланг нь задалдаг.

::: tip
Жишээ апп backend-гүйгээр ажиллахын тулд Face Match-г шууд дууддаг. Энэ нь зөвхөн турших зориулалттай.
:::

## Жишээ код

Session, сорил, face-match дуудлага болон хариуг задлах кодыг жишээ аппуудаас хуулж авч болно.

- [Android: `LivenessIntegration.kt`](https://github.com/airookies/liveness-detector-example-apps/blob/main/android/app/src/main/java/mn/ekyc/example/liveness/LivenessIntegration.kt)
- [iOS: `LivenessIntegration.swift`](https://github.com/airookies/liveness-detector-example-apps/blob/main/ios/LivenessExample/LivenessIntegration.swift)
- [React Native: `liveness.ts`](https://github.com/airookies/liveness-detector-example-apps/blob/main/react-native/src/liveness.ts)
- [Flutter: `liveness.dart`](https://github.com/airookies/liveness-detector-example-apps/blob/main/flutter/lib/liveness.dart)

Үр дүнгийн талбарууд: [Үр дүн ба шалтгаан](/guide/result).
