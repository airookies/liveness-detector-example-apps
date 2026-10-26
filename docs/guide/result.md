# Үр дүн ба шалтгаан

`start` нь амжилттай, алдаа, цуцлалт зэрэг бүх тохиолдолд үр дүн буцаана.

## Талбарууд

| Талбар | Утга |
| --- | --- |
| `status` | Шалгалтын төлөв |
| `reason` | `passed` биш үед шалтгаан |
| `challengeId` | Нотлох файл хамаарах сорил |
| `steps` | Алхам бүр: `passed`, `durationMs`, `peak` (эргэлтэд градус, илэрхийлэлд оноо) |
| `selfie` | JPEG, `image1.base64`-д |
| `sideImage` | Толгой эргүүлсэн үеийн JPEG (zip дотор бас бий) |
| `colorFrames` | Өнгө бүрийн JPEG (zip дотор бас бий) |
| `archive` | Нотлох файлын zip, `image1.sequence`-д |
| `integrity` | `ok` эсвэл зөрчлийн нэр, `integrity` талбарт |
| `devMode` | `devMode` асаалттай байсан эсэх |

`status` утгууд: `passed`, `failed`, `cancelled`, `error`.

Нотлох файл бүр аппын cache хавтсанд хадгалагдах бөгөөд зам эсвэл URI, нэр, SHA-256, өргөн, өндрийн мэдээлэл агуулна.

::: warning
Илгээсний дараа нотлох файлыг устгах шаардлагатай.
:::

## Шалтгаан (`reason`)

| `reason` | Юу болсон | Хэрэглэгчид харуулах мессеж |
| --- | --- | --- |
| `step_timeout`, `session_timeout` | Алхмыг хугацаандаа хийгээгүй (алхамд 16 с, нийт 120 с) | Хугацаа дууслаа. Зааврыг дагаад дахин оролдоно уу. |
| `face_lost` | Нүүр хүрээнээс гарсан | Нүүрээ зууван хүрээнд байлгана уу. |
| `multiple_faces` | Хоёр дахь нүүр орж ирсэн | Зөвхөн нэг хүн байх ёстой. |
| `flash_failed` | Өнгөний цэвэр кадр хоёр удаа авагдаагүй | Гэрэл анивчих үед хөдлөхгүй байна уу. |
| `cancelled` | Хэрэглэгч цонхыг хаасан эсвэл апп background-д шилжсэн | Цуцлагдлаа. |
| `camera_permission_denied` | Камерын зөвшөөрөл өгөөгүй | Тохиргооноос камерын зөвшөөрөл олгоно уу. |
| `camera_unavailable` | Камер асаагүй (iOS дээр `NSCameraUsageDescription` дутуу үед мөн) | Камер ажиллахгүй байна. Дараа дахин оролдоно уу. |
| `integrity_failed` | Төхөөрөмжийн шалгалт амжилтгүй; `integrity` нь шалтгааныг заана | Энэ төхөөрөмж дээр шалгалт ажиллахгүй. |
| `unsupported_device` | CPU загварыг ажиллуулж чадахгүй (жишээ нь Apple M4/M5 дээрх зарим emulator) | Бодит утас ашиглана уу. |
| `internal_error` | Бусад алдаа; дэлгэрэнгүй нь log-д | Алдаа гарлаа. Дахин оролдоно уу. |

## Төхөөрөмжийн шалгалт (`integrity`)

| Утга | Тайлбар |
| --- | --- |
| `ok` | Зөрчилгүй |
| `virtualCamera` | Виртуал камер илэрсэн |
| `virtualCameraApp` | Виртуал камерын апп илэрсэн |
| `noBuiltInCamera` | Төхөөрөмжийн өөрийн камер олдсонгүй |
| `emulator` | Emulator эсвэл simulator |
| `rooted` | Root хийсэн төхөөрөмж (Android) |
| `jailbroken` | Jailbreak хийсэн төхөөрөмж (iOS) |

## Платформ бүрийн нэршил

Утгууд ижил, бичиглэл нь платформоос хамаарна. React Native дээр string, бусад нь enum.

| Android | iOS | React Native | Flutter |
| --- | --- | --- | --- |
| `LivenessReason.STEP_TIMEOUT` | `.stepTimeout` | `'step_timeout'` | `LivenessReason.stepTimeout` |
| `LivenessStatus.PASSED` | `.passed` | `'passed'` | `LivenessStatus.passed` |

Backend-д `integrity`-г үр дүнгээс нь шууд дамжуулна.
