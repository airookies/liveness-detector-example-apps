# Алдаа засах

## Суулгахад 401, 403 эсвэл "Could not resolve" гарлаа

Хандалтын токен буруу эсвэл олдохгүй байна. Токеныг платформ бүр өөр газраас авна.

| Платформ | Токены байршил |
| --- | --- |
| Android | `~/.gradle/gradle.properties` дотор `cloudsmithToken=<token>` |
| React Native | `CLOUDSMITH_TOKEN` environment variable (`.npmrc` үүнийг уншина) |
| Flutter | `echo '<token>' \| dart pub token add https://dart.cloudsmith.io/airookies/liveness-detector/` |
| iOS | `~/.netrc` дотор `machine dl.cloudsmith.io login token password <token>`, мөн `chmod 600 ~/.netrc` |

Xcode дээр токеныг засаад **File > Packages > Reset Package Caches** хийнэ.

## iOS дээр `camera_unavailable`

`Info.plist`-д `NSCameraUsageDescription` дутуу байна. Нэмээд дахин build хийнэ.

## Emulator, simulator дээр `integrity_failed`

Бодит төхөөрөмж ашиглана. Хөгжүүлэлтийн үед `devMode`-г асааж болох ч зөвхөн debug build дээр ажиллана. Production backend `devMode: true` үр дүнг татгалзах ёстой.

## `unsupported_device`

Apple M4/M5 Mac дээрх зарим emulator загваруудыг ажиллуулж чадахгүй. Бодит утас ашиглана.

## iOS build: "LivenessDetector-Swift.h not found" эсвэл "unsupported Swift architecture"

SDK-ийн simulator хэсэг зөвхөн arm64 дээр ажиллана. x86_64 simulator-ийг target хийсэн build (жишээ нь Xcode-ийн "Any iOS Simulator Device") алдаа өгнө. Төхөөрөмж эсвэл arm64 simulator-т build хийнэ. Native апп дээр дараахыг нэмнэ:

```
EXCLUDED_ARCHS[sdk=iphonesimulator*] = x86_64
```

Simulator дээр зөвхөн build хийгдэнэ, шалгалтад бодит камер хэрэгтэй.

## Android: minSdk-ийн manifest merger алдаа

SDK `minSdk` 26 шаарддаг. `minSdk = 26` (React Native дээр `minSdkVersion = 26`) болгоно. Expo дээр `expo-build-properties`-оор тохируулна.

## React Native 0.76-0.81 + Xcode 26: `fmt` consteval алдаа

React Native-ийн `fmt` pod "call to consteval function ... is not a constant expression" гэж алдаа өгнө. `Podfile`-ийн `post_install`-ийн төгсгөлд нэмнэ:

```ruby
installer.pods_project.targets.each do |t|
  next unless t.name == 'fmt'
  t.build_configurations.each { |c| c.build_settings['CLANG_CXX_LANGUAGE_STANDARD'] = 'c++17' }
end
```

Дараа нь `cd ios && pod install`.

## Log харах

Дэлгэрэнгүй шалтгааныг log-оос харна: камер асаалт, экспозицийн түгжээ, өнгө бүрийн хугацаа, алхам хугацаа хэтэрсэн шалтгаан.

- Android: logcat tag `LivenessCore`
- iOS: subsystem `mn.ekyc.LivenessDetector`, category `LivenessCore`

Холбоотой: [Үр дүн ба шалтгаан](/guide/result).
