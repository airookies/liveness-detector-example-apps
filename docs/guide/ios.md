# iOS

## Шаардлага

- iOS 15+, Xcode 26+.
- Төхөөрөмж (arm64). Apple silicon Mac дээр simulator-оор build хийж болно, гэхдээ simulator-т камер байхгүй тул шалгалт `camera_unavailable`-аар дуусна. Бодит төхөөрөмж дээр турших хэрэгтэй.

## Суулгах

SDK нь `LivenessDetector.xcframework` болон `LivenessCore.xcframework` гэсэн хоёр framework-оос бүрдэнэ. Хувилбар бүрийн zip файлууд болон `SHA256SUMS`-ийг бид танд шууд хүргүүлнэ. iOS-д токен шаардлагагүй.

1. Zip файлуудыг `SHA256SUMS`-тэй тулгаж шалгана:

   ```sh
   shasum -a 256 -c SHA256SUMS --ignore-missing
   ```

2. Жишээ репогийн `ios/LivenessDetectorPackage` хавтсыг өөрийн төсөл рүү хуулаад, хоёр zip-ийг тэр хавтас дотор `Package.swift`-ийн хажууд задална:

   ```sh
   unzip LivenessDetector.xcframework.zip -d LivenessDetectorPackage
   unzip LivenessCore.xcframework.zip -d LivenessDetectorPackage
   ```

3. Xcode: **File > Add Package Dependencies… > Add Local…** гэж хавтсыг сонгоод `LivenessDetector` product-ыг target-даа холбоно.
4. `Info.plist`-д `NSCameraUsageDescription` нэмнэ. Үүнгүйгээр шалгалт `error` / `camera_unavailable` буцаана.

Шинэ хувилбар гарахад хавтас доторх хоёр framework-ийг шинээр нь солино.

SwiftPM ашиглахгүй бол хоёр framework-ийг target-ийн **Frameworks, Libraries, and Embedded Content** хэсэгт нэмж, хоёуланг нь **Embed & Sign** болгоно.

## Хэрэглээ

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

SDK дэлгэцээ `viewController`-оос бүтэн дэлгэцээр гаргаж, хаагдсаны дараа `completion`-ийг main thread дээр нэг удаа дуудна. Апп background-д орвол шалгалт цуцлагдана. SwiftUI-д `UIViewControllerRepresentable` ашиглана.

Жишээ апп: [ios](https://github.com/airookies/liveness-detector-example-apps/tree/main/ios). Үргэлжлүүлэн [Backend урсгал](/guide/backend) болон [Үр дүн ба шалтгаан](/guide/result) хэсгийг үзнэ үү.
