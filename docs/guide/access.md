# Хандалт ба токен

## Танд 

- `airookies/liveness-detector` сан.
- Хандалтын токен, сан татаж суулгах эрхтэй.

Гарын авлагад токеныг `<token>` гэж бичсэн. Бодит токеноо оруулна.

## Токен хэрэглэх

| Платформ | Байрлал | Агуулга |
| --- | --- | --- |
| Android | `~/.gradle/gradle.properties` | `cloudsmithToken=<token>` |
| iOS | `~/.netrc` | `machine dl.cloudsmith.io login token password <token>` |
| React Native | env хувьсагч | `export CLOUDSMITH_TOKEN=<token>`, `.npmrc` үүнийг уншина |
| Flutter | `dart pub token` | `echo '<token>' \| dart pub token add https://dart.cloudsmith.io/airookies/liveness-detector/` |

::: warning Анхаар
Токеныг хэзээ ч git-д commit хийхгүй. `.npmrc`, `settings.gradle.kts` зэрэг commit хийдэг файлд зөвхөн хувьсагчийн нэр бичнэ.
:::

## CI

CI дээр токеныг secret болгож хадгалаад job-д дамжуулна.

```sh
# Android (Gradle)
export ORG_GRADLE_PROJECT_cloudsmithToken=<token>

# React Native
export CLOUDSMITH_TOKEN=<token>

# Flutter
dart pub token add https://dart.cloudsmith.io/airookies/liveness-detector/ --env-var CLOUDSMITH_TOKEN

# iOS: job `~/.netrc` файлыг өөрөө бичнэ
printf 'machine dl.cloudsmith.io login token password %s\n' "$CLOUDSMITH_TOKEN" > ~/.netrc
chmod 600 ~/.netrc
```

Дараагийн алхам: [Backend урсгал](/guide/backend), эсвэл платформоо сонгоно уу: [Android](/guide/android), [iOS](/guide/ios), [React Native](/guide/react-native), [Flutter](/guide/flutter).
