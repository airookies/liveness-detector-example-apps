# Android

## Шаардлага

- `minSdk` 26, `compileSdk` 34 эсвэл түүнээс дээш, Android Gradle Plugin 8.1+.
- Kotlin 1.9+ эсвэл зөвхөн Java.
- ABI: arm64-v8a, armeabi-v7a, x86\_64.

## Суулгах

Токеныг `~/.gradle/gradle.properties` файлд `cloudsmithToken=<token>` гэж хадгална ([Хандалт ба токен](/guide/access)). Дараа нь сан болон dependency нэмнэ.

::: code-group

```kotlin [settings.gradle.kts]
dependencyResolutionManagement {
  repositories {
    google()
    mavenCentral()
    maven {
      url = uri("https://dl.cloudsmith.io/basic/airookies/liveness-detector/maven/")
      credentials {
        username = "token"
        password = providers.gradleProperty("cloudsmithToken").get()
      }
      content { includeGroup("mn.ekyc") }
    }
  }
}
```

```groovy [settings.gradle]
dependencyResolutionManagement {
  repositories {
    google()
    mavenCentral()
    maven {
      url "https://dl.cloudsmith.io/basic/airookies/liveness-detector/maven/"
      credentials {
        username "token"
        password providers.gradleProperty("cloudsmithToken").get()
      }
      content { includeGroup "mn.ekyc" }
    }
  }
}
```

:::

```kotlin
// app/build.gradle.kts
dependencies {
  implementation("mn.ekyc:liveness-detector:5.0.0")
}
```

SDK `CAMERA` зөвшөөрлийг өөрөө зарлаж, ажиллах үед хэрэглэгчээс асууна. R8 дүрмийг өөртөө агуулсан тул нэмэлт тохиргоо шаардахгүй.

## Эхлүүлэх

Backend-ээс авсан сорилыг (challenge) SDK-д өгч, үр дүнг боловсруулна.

```kotlin
import mn.ekyc.livenessdetector.*

val challenge = Challenge(
  id = response.challengeId,
  colors = response.colors,  // backend-ийн илгээснээр нь
  actions = listOf(LivenessAction.TURN_LEFT, LivenessAction.BLINK),  // эсвэл null
)
LivenessDetector.start(activity, LivenessOptions(challenge, locale = Locale("mn"))) { result ->
  when (result.status) {
    LivenessStatus.PASSED -> upload(
      selfie = result.selfie!!.file.readBytes(),
      zip = result.archive!!.file.readBytes(),
      challengeId = result.challengeId,
      integrity = result.integrity,
    )
    else -> showError(result.reason)
  }
}
```

Callback нэг удаа, SDK-ийн дэлгэц хаагдсаны дараа main thread дээр дуудагдана. Буцах товч дарах эсвэл апп цаана орвол `CANCELLED` буцна.

::: tip Зөвлөгөө
Emulator дээр зөвхөн `devMode = true` бөгөөд апп debuggable үед ажиллана. Бодит утсаар турших нь зүгээр.
:::

Жишээ апп: [android](https://github.com/airookies/liveness-detector-example-apps/tree/main/android). Үргэлжлүүлэн [Backend урсгал](/guide/backend) болон [Үр дүн ба шалтгаан](/guide/result) хэсгийг үзнэ үү.
