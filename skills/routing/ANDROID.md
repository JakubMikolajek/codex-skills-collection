# ANDROID Stack Sub-Branch

## When to enter this branch

- The task changes Android platform/build/lifecycle/data/DI/background/security concerns.
- The task changes Android-only Compose UI or Android XML/Fragment UI.

## When NOT to enter this branch

- KMP shared code, `commonMain`, Ktor/Koin shared modules, and Apple bridges use KOTLIN_MULTIPLATFORM.
- Do not load Compose and XML skills together unless migration, `ComposeView`, `AndroidView`, or hybrid screens are involved.

## Decision tree

| If the task involves...                                                                                                                      | Read next                                                                                    |
|----------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| Android build, lifecycle, Retrofit/OkHttp, Room/DataStore, Hilt/Dagger, permissions, services, WorkManager, notifications, security, testing | skills/android-core/SKILL.md                                                                 |
| Android-only Jetpack Compose, Navigation Compose, Material 3, recomposition, Route/Screen, previews, Compose tests                           | skills/android-core/SKILL.md + skills/android-compose/SKILL.md                               |
| XML, Fragment, View Binding, RecyclerView, Navigation Component, MVP, Presenter, custom View, resources                                      | skills/android-core/SKILL.md + skills/android-xml/SKILL.md                                   |
| XML-to-Compose migration or `ComposeView`/`AndroidView` interoperability                                                                     | skills/android-core/SKILL.md + skills/android-compose/SKILL.md + skills/android-xml/SKILL.md |
| Hilt or Dagger configuration                                                                                                                 | skills/android-core/SKILL.md                                                                 |
| Android `hiltViewModel()` integration                                                                                                        | skills/android-core/SKILL.md + skills/android-compose/SKILL.md                               |
| Android-only Retrofit networking                                                                                                             | skills/android-core/SKILL.md                                                                 |

## Combination rules

- Load `android-core` with either Android UI stack.
- Do not route Android-only Compose to `kotlin-multiplatform`.
- Keep full Hilt/Dagger configuration in `android-core`; keep only Compose DI retrieval in `android-compose`.
