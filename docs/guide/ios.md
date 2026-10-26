# iOS

## Шаардлага

- iOS 15+, Xcode 26+.
- Төхөөрөмж (arm64). Apple silicon Mac дээр simulator-оор build хийж болно, гэхдээ simulator-т камер байхгүй тул шалгалт `camera_unavailable`-аар дуусна. Бодит төхөөрөмж дээр турших хэрэгтэй.

## Суулгах

SDK нь хоёр framework: `LivenessDetector.xcframework` болон `LivenessCore.xcframework`.

1. `~/.netrc` файлд токеноо бичиж, эрхийг нь хязгаарлана:

   ```txt [~/.netrc]
   machine dl.cloudsmith.io login token password <token>
   ```

   ```sh
   chmod 600 ~/.netrc
   ```

2. Жишээ репогийн `ios/LivenessDetectorPackage` хавтсыг өөрийн төсөл рүү хуулна.
3. Xcode: **File > Add Package Dependencies… > Add Local…** гэж хавтсыг сонгоод `LivenessDetector` product-ыг target-даа холбоно.
4. `Info.plist`-д `NSCameraUsageDescription` нэмнэ. Үүнгүйгээр шалгалт `error` / `camera_unavailable` буцаана.

### Гараар татах (сонголт)

SwiftPM ашиглахгүй бол zip-үүдийг татаж, `Package.swift` доторх checksum-тай тулгана.

```sh
curl -sLfO "https://dl.cloudsmith.io/<token>/airookies/liveness-detector/raw/names/LivenessDetector.xcframework/versions/5.0.0/LivenessDetector.xcframework.zip"
curl -sLfO "https://dl.cloudsmith.io/<token>/airookies/liveness-detector/raw/names/LivenessCore.xcframework/versions/5.0.0/LivenessCore.xcframework.zip"
shasum -a 256 LivenessDetector.xcframework.zip LivenessCore.xcframework.zip
```

Unzip хийж, хоёуланг нь target-ийн **Frameworks, Libraries, and Embedded Content** хэсэгт **Embed & Sign** болгоно.

::: warning Анхаар
Токен орсон URL-ыг скрипт, README, git-д хэзээ ч commit хийхгүй.
:::

## Эхлүүлэх

```swift
import LivenessDetector

let challenge = Challenge(id: response.challengeId, colors: response.colors, actions: [.turnLeft, .blink])
let options = LivenessOptions(challenge: challenge, language: "mn")

LivenessDetector.start(from: viewController, options: options) { result in
  switch result.status {
  case .passed:
    let selfie = try? Data(contentsOf: result.selfie!.url)
    let zip = try? Data(contentsOf: result.archive!.url)
    upload(selfie: selfie, zip: zip, challengeId: result.challengeId, integrity: result.integrity)
  default:
    showError(result.reason)
  }
}
```

SDK дэлгэцээ `viewController`-оос бүтэн дэлгэцээр гаргаж, хаагдсаны дараа `completion`-ийг main thread дээр нэг удаа дуудна. Апп цаана орвол шалгалт цуцлагдана. SwiftUI-д `UIViewControllerRepresentable` ашиглана.

Жишээ апп: [ios](https://github.com/airookies/liveness-detector-example-apps/tree/main/ios). Үргэлжлүүлэн [Backend урсгал](/guide/backend) болон [Үр дүн ба шалтгаан](/guide/result) хэсгийг үзнэ үү.
