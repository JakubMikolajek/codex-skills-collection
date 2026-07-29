---
name: kotlin-multiplatform
description: Kotlin Multiplatform and Compose Multiplatform architecture, source sets, Ktor, Koin, platform abstractions, native Apple UI interoperability, shared persistence, concurrency, and testing.
---

# Kotlin Multiplatform

## When to Use

- The task changes `commonMain`, `commonTest`, `androidMain`, `iosMain`, `jvmMain`, `desktopMain`, or code shared across two or more Kotlin targets.
- The task adds shared Kotlin domain/data/presentation code, Compose Multiplatform, Ktor Client, Koin modules, `expect`/`actual`, Kotlin/Native, shared persistence, or shared tests.
- The task bridges shared Kotlin/Compose to Swift, SwiftUI, UIKit, CocoaPods, Swift Package Manager, `ComposeUIViewController`, `UIViewControllerRepresentable`, `UIKitView`, or `UIKitViewController`.

## When NOT to Use

- Do not use for Android-only Compose or XML screens; use `android-compose` or `android-xml` with `android-core`.
- Do not use for JVM/backend Kotlin, a platform-specific Android change with no shared impact, or a pure Swift app with no shared Kotlin code.
- Do not use KMP merely because a project uses Kotlin.

## Purpose and Boundaries

Own multiplatform source sets, shared Kotlin, Ktor, Koin, platform abstractions, Compose Multiplatform, Kotlin/Native, shared persistence/testing, and Apple-host interoperability. Do not own Android Retrofit/Room/Hilt/Dagger (use `android-core`) or Android-only Compose presentation (use `android-compose`). Do not place SwiftUI source in `iosMain`: it is Kotlin compiled for iOS; native Swift UI belongs in the `iosApp` target.

## Core Principles

- Keep `commonMain` platform-neutral: no Android SDK, UIKit, SwiftUI, JVM-only APIs, Android `Context`, Hilt, Dagger, Retrofit, or platform entities.
- Put platform implementations in platform source sets. Prefer injected interfaces; use `expect`/`actual` only when compile-time platform differences, primitives, or interop justify it.
- Share business logic where valuable, not merely to maximize shared-code percentage. Native UI remains valid. Apple structural UI normally stays native; Android follows Android conventions.
- Use feature-first organization and constructor injection. Do not build global `repositories/`, `viewmodels/`, `usecases/`, or `screens/` directories.

## Feature-First Source Sets

```text
shared/src
├── commonMain/kotlin/com.example.app
│   ├── core/{common,network,database,di}
│   ├── feature/devices/{data,domain,presentation}
│   └── platform/{PlatformInfo,SecureStorage,ExternalNavigator}.kt
├── commonTest
├── androidMain
├── androidUnitTest
├── iosMain
├── iosTest
├── desktopMain
└── desktopTest
```

A feature may contain `data/{remote,local,mapper}`, optional `domain/{model,repository,usecase}`, and `presentation/{ViewModel,UiState,Action,Effect}`. Add domain only for genuine business, reuse, or testing boundaries. For larger systems, allow `app-android`, `app-ios`, `shared:core:*`, `shared:feature:*`, and `shared:ui`; platform apps are composition roots and features do not depend on unrelated features.

## Proportional Architecture

For a small project, keep one `shared` module with feature-first packages and only the source sets the targets require. Add domain layers and separate shared modules only when independent ownership, reuse, build performance, test isolation, or platform contracts justify them. Do not turn `commonMain` into an unstructured shared bucket.

## Architecture Rules

- Shared APIs use neutral models and contracts; platform code implements them in its source set.
- Application targets own startup, native structure, and platform dependency composition.
- Give exactly one layer ownership of each navigation, tab, safe-area, and scroll-dependent behavior.

## Implementation Guidance

Inspect target/source-set declarations, installed Ktor/Koin/Compose versions, framework export configuration, generated Swift interface, deployment target, and selected SDK before emitting code. Validate each target that the change affects rather than transferring Android assumptions to iOS or desktop.

## Networking and Dependency Injection

Prefer Ktor Client for shared networking. Keep a configured long-lived client and platform engines in source sets; allow injected `HttpClient`, injected engine, an `expect`/`actual` factory, or platform startup composition. Inspect installed Ktor/Koin versions before emitting executable configuration.

- Configure serialization, request/connect/socket timeouts, central authentication/token refresh, typed errors, and safe logging. Never return `HttpResponse` or raw Ktor exceptions to UI, create a client per request, or log tokens/sensitive bodies.
- Prefer Koin for shared DI unless the project already uses another KMP-compatible solution. Start one container at the platform composition root; explicitly combine shared and platform modules; preserve test replacement.
- Use constructor injection. Do not scatter `get()` through business logic, create one giant module, use qualifiers without multiple real implementations, place Android `Context` in `commonMain`, or initialize Koin per controller. Never use Hilt/Dagger annotations in shared code.

## Platform Abstractions, Coroutines, and Persistence

Use platform-neutral contracts such as `SecureStorage`; implement them in `androidMain`/`iosMain`. Use `expect`/`actual` only where injection would add meaningless ceremony. Keep structured concurrency, explicit scope/cancellation ownership, injected dispatchers where useful, read-only flows, and no unmanaged application-wide scopes. Do not assume Android lifecycle or `Dispatchers.Main` support in shared code; define who cancels Swift Flow observation and never expose internal scopes to Swift.

Use project-selected SQLDelight, multiplatform settings, Room Multiplatform, supported DataStore, or platform storage behind contracts. Keep persistence entities/driver types in data, map to neutral models, version/test migrations, and store sensitive values in Keychain/Keystore/equivalent secure storage.

## Compose Multiplatform

Shared UI may use Route/Screen, immutable state, actions, effects, and injected services like Android Compose, but it must remain platform-neutral: no Android `Context`, Android-only destinations, or UIKit/SwiftUI types. Keep system pickers, permissions, settings, auth handoff, native controllers, and platform-specific UI in source sets or host apps. Use `UIKitView`/`UIKitViewController` only at a focused component boundary; do not embed a whole native navigation hierarchy in a shared Composable.

## Native Apple Shell and Interoperability

Before changing native interop, inspect the target repository’s actual branch, Xcode target, source-set locations, generated framework interface, deployment target, and SDK. The `swift-ui` branch of the cited LiquidGlassKMP reference was inspected: `iosApp/iosApp/ContentView.swift`, `iosApp/iosApp/iOSApp.swift`, `shared/src/iosMain/kotlin/com/plcoding/liquidglassprep/MainViewController.kt`, and `shared/src/commonMain/kotlin/com/plcoding/liquidglassprep/TabScreen.kt`. It demonstrates a SwiftUI `TabView`/`NavigationStack`, a `UIViewControllerRepresentable` host, an `iosMain` `ComposeUIViewController` factory, and shared Compose content. Adapt the pattern; never copy its names, framework symbols, deployment target, or padding values.

| Responsibility                                               | Location                         |
|--------------------------------------------------------------|----------------------------------|
| Shared business logic, neutral state, shared Compose content | `commonMain`                     |
| Kotlin/Native implementations and `UIViewController` factory | `iosMain`                        |
| SwiftUI app entry, navigation, tabs, toolbars, menus, sheets | native `iosApp`                  |
| Liquid Glass and Apple-specific UI behavior                  | native SwiftUI/UIKit in `iosApp` |

Expose a small Kotlin factory returning `UIViewController` with neutral parameters/callbacks. Inspect the generated framework interface—never guess names such as `MainViewControllerKt`. In SwiftUI, create it once in `makeUIViewController`, only update mutable configuration in `updateUIViewController`, and avoid retain cycles/coroutines or DI setup in factories.

```text
SwiftUI shell → UIViewControllerRepresentable → exported UIViewController
→ ComposeUIViewController → shared Compose screen → shared state/domain/data
```

SwiftUI owns native navigation paths, `TabView`, toolbars, sheets, safe areas, accessibility, and Apple presentation. Compose emits semantic callbacks. Never create competing Compose and native navigation/tab bars for one flow.

## Native iOS Decision Table

| Requirement                                     | Preferred implementation                         |
|-------------------------------------------------|--------------------------------------------------|
| Shared business logic or neutral state          | `commonMain`                                     |
| Shared Compose screen content                   | `commonMain`                                     |
| iOS Kotlin implementation or controller factory | `iosMain`                                        |
| Native app root, navigation, tabs, Liquid Glass | SwiftUI/UIKit in native `iosApp`                 |
| Native shell hosting Compose                    | `UIViewControllerRepresentable`                  |
| One focused native component in Compose         | `UIKitView` or `UIKitViewController`             |
| Apple-only type needed by shared UI             | Redesign the boundary                            |
| Scroll-driven native tab behavior               | Prefer a native scrolling container              |
| Transparent Compose content                     | Configure every UIKit/SwiftUI hosting layer      |
| Shared DI startup                               | Initialize once at the platform application root |

## Koin Composition Example

Treat exact APIs as version-dependent, but keep the composition shape explicit:

```kotlin
val devicesModule = module {
    single<DevicesRepository> { DevicesRepositoryImpl(api = get(), localDataSource = get()) }
    factory { DeviceListViewModel(repository = get()) }
}

fun initKoin(platformModule: Module) = startKoin {
    modules(sharedModules, platformModule)
}
```

Android startup may add `androidContext(this@App)`; iOS passes its platform module once before a bridge factory is used. Keep host-provided platform modules test-replaceable.

## Liquid Glass, Scrolling, Safe Areas, and Transparency

Liquid Glass is native Apple UI. Use native SwiftUI/UIKit APIs only after inspecting the selected SDK/deployment target; isolate `#available` checks, provide functional fallbacks, and verify newest/minimum supported OS. Do not recreate it with Compose blur, place Apple types in shared code, or imitate Apple materials on Android/desktop.

Native scroll effects do not automatically observe a Compose `LazyColumn`. Prefer a native scrolling container when native chrome depends on scroll, retain a non-scroll-dependent mode, or build an explicit tested bridge only when justified—never use undocumented UIKit mutations. SwiftUI owns structural safe areas when it owns navigation/tabs; avoid duplicate Compose padding and test portrait, landscape, split view, cutouts, keyboard, and transitions. For transparent hosting, configure Compose, `UIViewController`, UIKit parents, and SwiftUI containers; `Color.Transparent` alone is not enough.

## Swift and Objective-C Interoperability

Export small Swift-friendly APIs; avoid internal DTOs/entities, complex generics, internal coroutine scopes, and hidden platform failures. Define error mapping, suspension/cancellation ownership, Flow bridging, and platform initialization. Verify actual Swift symbols through the generated framework interface and the selected CocoaPods/SPM export configuration rather than assumptions.

## Testing

Put shared logic in `commonTest`; use fakes, coroutine test dispatchers, Ktor `MockEngine`, serialization tests, Koin module verification, migration tests, domain/shared-presentation tests, and platform-only implementation tests without duplicate cross-source-set tests. Hybrid apps also need Swift unit tests, XCUITest/native shell checks, availability builds, simulator/device visual verification, orientation, dark mode, Reduce Transparency, Dynamic Type, safe-area, transparency, lifecycle presentation/dismissal, and native-scroll checks. Unit tests alone cannot validate material, animation, transparency, or native scrolling.

## Android Compose versus Compose Multiplatform

| Task                                                                 | Skills                                                                |
|----------------------------------------------------------------------|-----------------------------------------------------------------------|
| Android-only Compose                                                 | `android-core` + `android-compose`                                    |
| Compose UI in `commonMain`                                           | `kotlin-multiplatform`                                                |
| KMP shared data with Android Compose host                            | `kotlin-multiplatform` + `android-core` + `android-compose`           |
| KMP shared data with XML host                                        | `kotlin-multiplatform` + `android-core` + `android-xml`               |
| SwiftUI/UIKit host for shared Kotlin or native shell hosting Compose | `kotlin-multiplatform` + `swiftui` when substantial native UI changes |
| Hilt/Dagger configuration                                            | `android-core`                                                        |
| Shared Koin/Ktor                                                     | `kotlin-multiplatform`                                                |

## Anti-Patterns to Avoid

| Anti-pattern                                     | Preferred approach                      |
|--------------------------------------------------|-----------------------------------------|
| Android/SwiftUI/UIKit type in `commonMain`       | Use platform-neutral contract           |
| Hilt/Dagger/Retrofit in shared code              | Use Koin/constructor injection and Ktor |
| `expect`/`actual` for every service              | Prefer injected interfaces              |
| Koin `get()` throughout business logic           | Constructor injection                   |
| New `HttpClient` per request                     | Reuse configured client                 |
| Raw Ktor error reaches UI                        | Map typed errors                        |
| Every screen forced into shared UI               | Share only when valuable                |
| SwiftUI source in `iosMain`                      | Keep SwiftUI in native `iosApp`         |
| Liquid Glass recreated in Compose                | Use native SwiftUI/UIKit                |
| Native tabs/navigation duplicated by Compose     | Assign one structural owner             |
| Generated framework name guessed                 | Inspect generated Swift interface       |
| Controller recreated on each update              | Use representable lifecycle             |
| Compose assumes automatic native scroll behavior | Treat scroll bridging explicitly        |
| Scattered hardcoded safe-area padding            | Centralize documented inset ownership   |
| Opaque UIKit host around transparent Compose     | Configure every host layer              |
| Koin initialized per controller                  | Initialize once at app startup          |

## Connected Skills

- `android-core`, `android-compose`, and `android-xml` — combine only when Android is a host platform.
- `kotlin` — language-specific implementation concerns.
- `swiftui` — combine for substantial native SwiftUI/UIKit implementation in an KMP project.
- Combine Gradle, CI, networking, database, and testing skills when those concerns are in scope.
