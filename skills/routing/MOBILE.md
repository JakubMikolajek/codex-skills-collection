# MOBILE Branch

## When to enter this branch

- Task involves Android application/platform code, Jetpack Compose, XML layouts, Fragments, Android Gradle, or Android release concerns.
- Task involves Kotlin Multiplatform source sets, shared Android/iOS Kotlin, Compose Multiplatform, Kotlin/Native, Ktor, Koin, or a SwiftUI/UIKit host for shared Kotlin.
- Files being edited are Android manifests/resources, Android Gradle modules, `commonMain`, `androidMain`, `iosMain`, or KMP target configuration.

## When NOT to enter this branch

- Backend Kotlin/JVM services, Spring Boot, or general Kotlin syntax use BACKEND → `kotlin`.
- Pure SwiftUI apps with no shared Kotlin use FRONTEND → NATIVE.
- Do not route Android-only Compose to KMP merely because it uses Kotlin; do not route native Apple UI to `android-compose`.

## Decision tree

| If the task involves...                                                                                                                 | Read next                              |
|-----------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------|
| Android build, lifecycle, networking, Room, Hilt, permissions, services, notifications, release                                         | skills/routing/ANDROID.md              |
| Android-only Jetpack Compose                                                                                                            | skills/routing/ANDROID.md              |
| Android XML, Fragment, View Binding, RecyclerView, MVP                                                                                  | skills/routing/ANDROID.md              |
| Shared Kotlin across Android/iOS, `commonMain`/`androidMain`/`iosMain`, Compose Multiplatform, Ktor, Koin, Kotlin/Native                | skills/routing/KOTLIN_MULTIPLATFORM.md |
| SwiftUI/UIKit hosting shared Kotlin, `ComposeUIViewController`, `UIViewControllerRepresentable`, native SwiftUI shell, KMP Liquid Glass | skills/routing/KOTLIN_MULTIPLATFORM.md |

## Combination rules

- `android-compose` normally combines with `android-core`; `android-xml` normally combines with `android-core`.
- `kotlin-multiplatform` may combine with one Android UI skill when Android hosts shared code.
- Combine `android-compose` and `android-xml` only for migration or interoperability.
- Combine `kotlin-multiplatform` with `swiftui` for substantial native SwiftUI/UIKit host implementation.
- Combine `kotlin`, Gradle, CI, database, networking, or testing skills only when their specific concern is in scope.
