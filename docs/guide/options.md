# Тохиргоо ба загвар

Бүх платформ ижил тохиргоотой, нэршил нь платформынхоо хэв маягаар бичигдэнэ.

## Тохиргоо

| Тохиргоо | Утга |
| --- | --- |
| `challenge.id` | Backend-ийн `challenge_id`; үр дүн ба нотлох файлд орно |
| `challenge.colors` | Backend-ийн `colors` (`"#RRGGBB"`), өөрчлөлтгүй. Өгөхгүй бол SDK сонгоно; `[]` бол анивчуулахгүй (зөвхөн туршилтад). |
| `challenge.actions` | Зүүн, баруун эргэх, нүд ирмэх, ам ангайх, инээмсэглэх, дарааллаар нь. Өгөхгүй бол SDK нэг эргэлт сонгоно; `[]` бол үйлдэлгүй. |
| `challenge.colorCount` | `colors` өгөөгүй үед SDK хэдэн өнгө сонгох (анхдагч 4) |
| `locale` | `en` эсвэл `mn`; анхдагчаар төхөөрөмжийн хэл |
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

::: warning
Эхлэхийн өмнөх анхааруулгыг (дэлгэц өнгөөр анивчина) хасахгүй байна уу. Анивчуулга нь хуурамчаас хамгаалах гол алхам бөгөөд өөр хувилбаргүй.
:::

## Нууцлал

- Кадр санах ойд боловсруулагдана.
- Зөвхөн selfie, хажуугийн зураг, өнгөний кадр, zip аппын cache хавтсанд бичигдэнэ.
- SDK өгөгдөл цуглуулахгүй, аналитикгүй.
- Нүүрний зураг нь биометрийн өгөгдөл (GDPR 9-р зүйл) тул хэрэглэгчийн зөвшөөрлийн урсгалдаа тусгана. "Инээмсэглэх" нь зөвхөн амьд эсэхийг шалгах үйлдэл, SDK сэтгэл хөдлөл тодорхойлохгүй.
