# Тохиргоо ба загвар

Бүх платформ ижил тохиргоотой, нэршил нь платформынхоо хэв маягаар бичигдэнэ.

## Тохиргоо

| Тохиргоо | Утга |
| --- | --- |
| `challenge.id` | Backend-ийн `challenge_id`; үр дүн ба нотлох файлд орно |
| `challenge.colors` | Backend-ийн `colors` (`"#RRGGBB"`), өөрчлөлтгүй. Өгөхгүй бол SDK сонгоно; `[]` бол анивчуулахгүй (зөвхөн туршилтад). |
| `challenge.actions` | Зүүн, баруун эргэх, нүд ирмэх, ам ангайх, инээмсэглэх, дарааллаар нь. Өгөхгүй бол SDK нэг эргэлт сонгоно; `[]` бол үйлдэлгүй. |
| `challenge.colorCount` | `colors` өгөөгүй үед SDK хэдэн өнгө сонгох (анхдагч утга нь 4) |
| `locale` | `en` эсвэл `mn`; анхдагч утга нь төхөөрөмжийн хэл |
| `theme` | Өнгө, овалын өргөн, текст солих |
| `devMode` | Зөвхөн debug build дээр emulator/simulator-ийг зөвшөөрнө. Үр дүнд `devMode: true` гарах тул production backend татгалзаж болно. Root, jailbreak шалгалтыг сулруулахгүй. |
| `tuning` | Хоосон үлдээнэ үү |

## Загвар ба текст

::: code-group
```kotlin [Kotlin]
val theme = LivenessTheme(
  accentColor = 0xFF1E88E5.toInt(),
  strings = mapOf("ld_notice_title" to "Эхлэхийн өмнө"),
)
LivenessDetector.start(activity, LivenessOptions(challenge, theme = theme), callback)
```
```swift [Swift]
options.theme.accentColor = .systemBlue
options.theme.strings = ["ld_notice_title": "Эхлэхийн өмнө"]
```
```ts [TypeScript]
start({
  challenge,
  theme: {
    accentColor: '#1E88E5',
    scrimColor: '#D9000000', // #AARRGGBB
    strings: { ld_notice_title: 'Эхлэхийн өмнө' },
  },
});
```
```dart [Dart]
LivenessOptions(
  challenge: challenge,
  theme: const LivenessTheme(accentColor: '#1E88E5', strings: {'ld_notice_title': 'Эхлэхийн өмнө'}),
)
```
:::

Текстийн түлхүүр (`ld_notice_title`, `ld_hint_no_face` гэх мэт) бүх платформ дээр ижил. Англи, монгол хэл суурилагдсан. Бүрэн жагсаалтыг SDK-ийн `Localizable.strings` файлаас үзнэ.

## Өөрийн буцах товч ба толгой хэсэг

5.1 хувилбараас эхлэн iOS болон Android апп шалгалтын дэлгэц дээр өөрийн буцах товч болон баруун дээд буланд лого зэргийг харуулж болно. React Native, Flutter дээр одоогоор байхгүй.

- Өөрийн буцах товч өгвөл зүүн дээд буланд байрлаж, анхдагч "Цуцлах" товч нуугдана. Дарахад шалгалт цуцлагдаж, `cancelled` үр дүн буцна.
- Өнгө анивчих үед эдгээр нь дэлгэцийн ард нуугдана. Дэлгэцийн гэрэл царайг бүрэн гэрэлтүүлэх ёстой.

::: code-group
```swift [Swift]
options.theme.makeBackButton = { onBack in
  let button = UIButton(type: .system)
  button.setTitle("Буцах", for: .normal)
  button.addAction(UIAction { _ in onBack() }, for: .touchUpInside)
  return button
}
options.theme.makeHeaderRight = { UIImageView(image: UIImage(named: "logo")) }
```
```kotlin [Kotlin]
val theme = LivenessTheme(
  backButtonLayout = R.layout.my_back_button,
  headerRightLayout = R.layout.my_header_logo,
)
```
:::

Android дээр layout-ыг SDK-ийн дэлгэц өөрөө inflate хийнэ. `backButtonLayout`-ийн layout бүхэлдээ товч болно.
