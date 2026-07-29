---
name: android-core
description: Android platform architecture, lifecycle, Gradle, networking, persistence, dependency injection, background work, testing, security, and shared application infrastructure.
---

# Android Core

## When to Use

- The task changes an Android application or library module, `build.gradle.kts`, version catalog, manifest, build variant, signing, R8, or release configuration.
- The task changes Activity or Fragment lifecycle fundamentals, configuration changes, process recreation, saved state, coroutines, or Flow collection.
- The task implements Android networking, Room, DataStore, Hilt/Dagger, permissions, services, WorkManager, notifications, Android tests, or platform security.

## When NOT to Use

- Do not use this skill alone for detailed Jetpack Compose UI; combine it with `android-compose`.
- Do not use this skill alone for XML/Fragment UI, View Binding, RecyclerView, or MVP; combine it with `android-xml`.
- Do not use it for Compose Multiplatform, shared Koin/Ktor modules, SwiftUI/UIKit, backend Kotlin, or pure Kotlin unrelated to Android.

## Purpose and Boundaries

Own Android concerns shared by Compose and XML applications: SDK integration, application infrastructure, lifecycle, transport, persistence, Android DI, background execution, testing, security, and release engineering. Keep UI-stack architecture in `android-compose` or `android-xml`; keep `commonMain`, Ktor, Koin, and Apple interop in `kotlin-multiplatform`.

## Core Principles

- Keep Android framework types at platform boundaries; keep pure domain code free of `Context`, Activity, Fragment, Retrofit, Room, and DTO types unless a real boundary requires them.
- Give every coroutine a clear owner. Use structured concurrency, cancellation, appropriate dispatchers, `viewModelScope`, `lifecycleScope`, `repeatOnLifecycle`, and read-only public `StateFlow`/`SharedFlow`. Never use `GlobalScope`, uncontrolled custom scopes, or blocking work on the main thread.
- Use repositories to coordinate sources. UI never accesses Retrofit, OkHttp, DAO, Room entity, or persistence preference directly. Map transport, persistence, and platform failures into typed application errors before presentation.
- Prefer focused feature/core ownership over a `Utils.kt` dumping ground or speculative abstractions.

## Build and Release Configuration

- Use Android application and library modules deliberately. Keep Gradle Kotlin DSL, version catalogs, plugin aliases, AGP compatibility, Java/Kotlin toolchains, dependency management, resources, and manifest merging version-aligned.
- Model build types, product flavors, variants, `BuildConfig` fields, signing, resource configuration, R8/ProGuard, and release builds explicitly. Keep secrets outside committed source and verify release shrinking, signing, and variant-specific manifests.
- Combine `kotlin`, `ci-cd`, or Gradle-focused project guidance when language or pipeline concerns are material.

## Lifecycle, State, and Android APIs

- Distinguish Application, Activity, Fragment, and Fragment *view* lifecycles. A Fragment can outlive its view; UI collectors must use the correct lifecycle owner.
- Plan configuration changes, process death, `SavedStateHandle`, and restoration separately. `remember`/View Binding are not process restoration mechanisms.
- Use the Activity Result API for permissions and external results. Validate deep links, intent extras, URIs, FileProvider access, exported components, platform-version checks, and notification permission behavior.

## Dependency Injection

Android-specific DI belongs here. Prefer constructor injection and lifecycle-appropriate Hilt/Dagger bindings:

- Configure `@HiltAndroidApp`, `@AndroidEntryPoint`, modules, component hierarchy, singleton, Activity-retained and ViewModel scopes, Android framework bindings, assisted injection when justified, and WorkManager integration here.
- Do not make Hilt mandatory when the project already has a valid DI solution. Do not use service locators throughout business logic, inject Activity/Fragment into long-lived dependencies, place UI objects in singleton scope, or duplicate complete Hilt/Dagger setup in `android-compose`.
- `android-compose` owns only Route-level retrieval such as `hiltViewModel()` and passing state/callbacks into stateless screens.

## Networking and Persistence

- Configure one long-lived Retrofit/OkHttp client with serialization, interceptors, central authentication/token refresh, request/connect timeouts, deliberately bounded retries, typed error mapping, and safe logging. Never return `Response` or raw transport exceptions to UI, create a client per request, or log tokens/sensitive bodies.
- Keep Room entities and DAOs in the data/persistence layer. Repositories expose application/domain models; UI never sees DAOs or entities. Version and test migrations. Use DataStore intentionally and secure storage boundaries for sensitive values; never keep secrets in plain preferences.

## Background Work, Security, and Testing

- Select WorkManager, foreground service, alarm, or notification channel based on Android execution restrictions, battery/network constraints, retry semantics, and user visibility. Configure notification channels and permissions explicitly.
- Minimize exported components; validate cross-component input; protect logs, notifications, and screenshots where sensitive; use secure build configuration and encrypted/platform-secure storage when appropriate.
- Cover unit, instrumentation, Android integration, coroutine, repository, Room migration, WorkManager, and DI module tests. Prefer fakes where practical and test coroutine dispatch/cancellation deterministically.

## Proportional Architecture

Use a single app module with focused feature packages first. A small project can keep application infrastructure near its features with focused `core` packages. Add library, core, or feature modules only for ownership, reuse, build-time, test-isolation, or independently shipped boundaries. A larger app may use `app`, focused `core:*`, and independently owned `feature:*` modules. Do not create empty layers or global `core` dumping grounds.

## Implementation Guidance

Inspect the installed AGP, Kotlin, dependency, and Android SDK versions before adding build or API code. Follow the existing DI, data, error, and test conventions; update manifests and release rules together with the platform behavior they support.

## Architecture Rules

- Repositories coordinate data sources; DTOs and entities never leak into presentation.
- Scope dependencies to their real lifecycle and map platform exceptions before UI.
- Keep framework bindings explicit and core packages owned; do not add abstraction without a real boundary.

## Anti-Patterns to Avoid

| Anti-pattern                           | Preferred approach                      |
|----------------------------------------|-----------------------------------------|
| `GlobalScope` for application work     | Use lifecycle-owned or injected scopes  |
| Activity injected into singleton       | Inject application-safe abstractions    |
| Retrofit response returned to UI       | Map into domain/application result      |
| DAO used from Activity or Fragment     | Use repository boundary                 |
| One giant `Utils.kt`                   | Create focused components or extensions |
| Secrets committed in source            | Use secure build configuration          |
| New client per API call                | Reuse configured client                 |
| Raw exceptions shown to users          | Map failures into typed UI errors       |
| Unscoped dependency graph              | Use lifecycle-appropriate scopes        |
| Hilt setup duplicated in Compose skill | Keep complete DI ownership here         |

## Connected Skills

- `android-compose` — Android Compose UI and Route-level DI integration.
- `android-xml` — XML, Fragment UI, View Binding, RecyclerView, and MVP.
- `kotlin-multiplatform` — shared KMP concerns; do not move Android Hilt/Dagger there.
- `kotlin`, `ci-cd`, `security-hardening`, `test-strategy`, and data/network skills — combine when their concern is in scope.
