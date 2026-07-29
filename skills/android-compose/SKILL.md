---
name: android-compose
description: Android-only Jetpack Compose architecture, state management, MVVM/UDF, navigation, design systems, performance, accessibility, and testing.
---

# Android Compose

## When to Use

- The task adds or changes Android-only `@Composable` screens, Material 3 UI, previews, Navigation Compose, `ComposeView`, or `AndroidView`.
- The task investigates recomposition, Compose state, stability, lazy-list keys, effects, accessibility, performance, or Compose UI tests.
- The task uses ViewModel-driven Compose UI, `collectAsStateWithLifecycle`, or Route-level `hiltViewModel()` integration.

## When NOT to Use

- Do not use for XML layouts, Fragment-only screens, RecyclerView adapters, or MVP Presenters; use `android-xml`.
- Do not use for Compose Multiplatform UI in `commonMain`; use `kotlin-multiplatform`.
- Do not use for complete Hilt/Dagger configuration, general Android Gradle, backend Kotlin, or native SwiftUI/UIKit work.

## Purpose and Boundaries

Own Android-only Compose presentation architecture. `android-core` owns Android platform, Retrofit/Room, and complete Hilt/Dagger configuration. This skill owns only Compose DI integration: obtain a ViewModel at Route level, then pass immutable state and callbacks into reusable Composables.

## Core Principles

- Prefer feature-first organization; do not create global `activities/`, `viewmodels/`, `repositories/`, `screens/`, or `components/` folders.
- Use immutable `UiState`, private mutable state, public read-only `StateFlow`, lifecycle-aware collection, typed actions, deliberate one-time effects, state hoisting, and UDF.
- Keep ViewModels at Route level. Screens are stateless where practical, render state, accept callbacks or `onAction`, remain previewable without a real ViewModel, and never retrieve services directly.
- Keep business logic, networking, database access, and dependency lookup out of Composables. Keep local components beside their screen; put truly reusable design-system components in `core/designsystem`.

## Feature-First Structure

Start with a focused single module:

```text
com.example.app
├── core/{common,designsystem,navigation,network,database,testing}
├── feature
│   └── devices/{data,domain,presentation/device_details,navigation}
└── di
```

For a non-trivial screen, use `DeviceDetailsRoute.kt`, `DeviceDetailsScreen.kt`, `DeviceDetailsViewModel.kt`, `DeviceDetailsUiState.kt`, `DeviceDetailsAction.kt`, `DeviceDetailsEffect.kt`, and a nearby `component/` folder. In the data layer, retain DTOs/entities and map them in repositories. Add a pure domain layer only for meaningful business logic, multiple sources, independent tests, shared contracts, multiple owners, or anticipated modularization.

```kotlin
@Composable
fun DeviceDetailsRoute(
    onNavigateBack: () -> Unit,
    viewModel: DeviceDetailsViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    DeviceDetailsScreen(state, viewModel::onAction, onNavigateBack)
}
```

## Route, Screen, State, Action, and Effect

- **Route:** obtain ViewModel, collect lifecycle-safely, connect navigation/platform integrations, and pass state/callbacks.
- **Screen:** render only; do not contain business logic, service location, or a real ViewModel requirement.
- **UiState:** represent persistent loading, content, empty, and error state explicitly.
- **Action:** represent typed user/UI intent without leaking raw Android events unless needed.
- **Effect:** represent navigation, snackbar, dialog, permission, or external-intent commands deliberately; do not persist one-time navigation in state by accident.

## Compose State and Effects

Differentiate state that survives recomposition (`remember`), configuration changes (`ViewModel`, `rememberSaveable` when appropriate), and process recreation (saved state/restoration). Use `derivedStateOf`, `LaunchedEffect`, `DisposableEffect`, `SideEffect`, and `rememberUpdatedState` only with intentional keys. Do not launch work on each recomposition or use `LaunchedEffect(Unit)` as unrelated application lifecycle infrastructure.

## Navigation, Design, Performance, and Accessibility

- Use Navigation Compose with typed/explicit destinations; keep structural navigation in one owner. Use adaptive layouts/window size classes where product needs them.
- Follow Material 3 and project design tokens. Use previews for static states, errors, empty states, large text, and light/dark variants.
- Favor immutable/stable models, stable domain IDs in lazy lists, bounded derived work, and profiling before memoization. Test semantics, visible state, and interaction with Compose UI tests.
- Provide semantic labels/roles, logical focus order, adequate target sizes, dynamic type/font scaling, contrast, and non-color-only meaning. Use `AndroidView`/`ComposeView` only at an explicit interoperability boundary.

## Proportional Architecture

For a small app, a feature may use `data/`, `model/`, and `presentation/` without a domain layer. For larger apps, use `app`, focused `core:*`, and `feature:*` modules. Features must not depend directly on unrelated features; `core` must not become a dumping ground. Modularize for measurable ownership, reuse, test, or build benefits—not appearance.

## Architecture Rules

- Keep domain independent from Compose, Activity/Fragment, Retrofit, and Room.
- Keep presentation models immutable and map data-layer types before presentation.
- Use one structural navigation owner and local feature components before global reuse.

## Implementation Guidance

Inspect the installed Compose, Navigation, Material, lifecycle, and DI versions before producing API-specific code. Implement loading/content/empty/error states, previews, semantics, and focused UI tests with the project’s existing test stack.

## Dependency Injection Boundary

Hilt is optional. Compose may use Hilt, Dagger, Koin, manual DI, or an existing project convention. Keep retrieval at Route level (`hiltViewModel()` when selected); pass state/callbacks instead of `Context`, ViewModel, or container lookup through reusable trees. Full Hilt/Dagger modules, scopes, Worker integration, and Android framework bindings belong to `android-core`.

## Explicit Routing Boundary

Use with `android-core` for Android-only Compose. Combine with `android-xml` only for migration or `ComposeView`/`AndroidView` hybrid screens. Do not route Android-only Compose to `kotlin-multiplatform` merely because it uses Kotlin.

## Anti-Patterns to Avoid

| Anti-pattern                           | Preferred approach                  |
|----------------------------------------|-------------------------------------|
| ViewModel passed through whole tree    | Keep ViewModel at Route level       |
| Retrofit/DAO called from Composable    | Use ViewModel and repository        |
| Mutable state exposed publicly         | Expose immutable `StateFlow`        |
| Navigation stored permanently in state | Use a deliberate effect mechanism   |
| Coroutine on every recomposition       | Use ViewModel scope or keyed effect |
| Global components folder               | Keep local components near screen   |
| Domain layer for every feature         | Add it only when valuable           |
| One-line use case around every call    | Add use cases for meaningful logic  |
| Dozens of modules in a small app       | Modularize when justified           |
| `Context` passed through Composables   | Use a platform boundary/abstraction |
| Unstable list keys                     | Use stable domain identifiers       |
| Full Hilt setup duplicated here        | Keep it in `android-core`           |

## Connected Skills

- `android-core` — normally combine for Android platform and DI infrastructure.
- `android-xml` — combine only for migration/interoperability.
- `kotlin-multiplatform` — combine only when Android Compose hosts shared KMP code.
- `kotlin` — language-specific concerns.
