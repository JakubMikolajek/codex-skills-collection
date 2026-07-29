# KOTLIN MULTIPLATFORM Stack Sub-Branch

## When to enter this branch

- The task changes shared Kotlin across Android/iOS or `commonMain`, `commonTest`, `androidMain`, `iosMain`, JVM, or desktop source sets.
- The task changes Compose Multiplatform, shared Ktor networking, Koin modules, `expect`/`actual`, Kotlin/Native, shared persistence, or shared tests.
- The task hosts shared Kotlin/Compose from SwiftUI/UIKit using a `ComposeUIViewController` bridge or native SwiftUI shell.

## When NOT to enter this branch

- Android-only Compose uses ANDROID → `android-core` + `android-compose`; Android XML uses ANDROID → `android-core` + `android-xml`.
- Do not route backend Kotlin or general Kotlin syntax here. Do not route pure SwiftUI with no shared Kotlin here.

## Decision tree

| If the task involves...                                                                                                  | Read next                                                                 |
|--------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------|
| Shared Kotlin, `commonMain`, `iosMain`, source sets, Compose Multiplatform, Ktor, Koin, `expect`/`actual`, Kotlin/Native | skills/kotlin-multiplatform/SKILL.md                                      |
| KMP with Android Compose host                                                                                            | `kotlin-multiplatform` + ANDROID → `android-core` + `android-compose`     |
| KMP with Android XML host                                                                                                | `kotlin-multiplatform` + ANDROID → `android-core` + `android-xml`         |
| SwiftUI/UIKit hosting shared Kotlin, native SwiftUI shell, `ComposeUIViewController`, `UIViewControllerRepresentable`    | `kotlin-multiplatform`; also use `swiftui` for substantial native host UI |
| KMP Liquid Glass implementation                                                                                          | `kotlin-multiplatform`; also use `swiftui` when available                 |
| Shared Koin configuration or Ktor networking                                                                             | skills/kotlin-multiplatform/SKILL.md                                      |

## Combination rules

- KMP may combine with one Android UI skill only when Android hosts shared code.
- KMP combines with `swiftui` for substantial native SwiftUI/UIKit implementation.
- Koin/Ktor are KMP ownership; Hilt/Dagger remain Android-core ownership.
- Never place SwiftUI source in Kotlin `iosMain`; it belongs to native `iosApp`. Kotlin `iosMain` contains Kotlin/Native implementations and focused controller bridges.
