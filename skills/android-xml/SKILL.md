---
name: android-xml
description: Android XML layouts, Activities, Fragments, View Binding, RecyclerView, Navigation Component, MVP, Android Views, resources, lifecycle safety, and testing.
---

# Android XML

## When to Use

- The task changes XML layout/resources, styles/themes, custom Android Views, View Binding, ConstraintLayout, MotionLayout, or resource qualifiers.
- The task implements Fragment screens, DialogFragment, BottomSheetDialogFragment, Navigation Component, Safe Args, RecyclerView, `ListAdapter`, or `DiffUtil`.
- The task uses MVP contracts/Presenters or diagnoses Fragment view-lifecycle, binding, adapter, insets, or Espresso/FragmentScenario failures.

## When NOT to Use

- Do not use for Compose-first screens, Compose state, or Navigation Compose; use `android-compose`.
- Do not use for Compose Multiplatform UI, backend Kotlin, general Gradle work without XML/Fragment relevance, or native SwiftUI/UIKit.

## Purpose and Boundaries

Treat XML/MVP as a maintained production stack, not a mandatory migration target. Own XML presentation and Android View integrations. `android-core` owns lifecycle fundamentals, networking, persistence, Android DI, build, and security; this skill applies those rules to XML UI. `kotlin-multiplatform` owns shared code and KMP UI.

## Core Principles

- Keep Android View integration and lifecycle ownership in the Fragment, testable presentation decisions in the Presenter, and data access behind repositories.
- Treat the Fragment view lifecycle as a real boundary: binding, adapters, listeners, and collectors must not outlive it.
- Use feature-first structure, typed callbacks/effects, and incremental migration only when it delivers measurable value.

## Feature-First Architecture

Do not use global `activities/`, `fragments/`, `presenters/`, `adapters/`, or `repositories/` folders. Prefer:

```text
com.example.app
├── core/{common,navigation,network,database,ui,testing}
├── feature
│   └── devices/{data,domain,presentation/device_details,navigation}
└── di
```

Use `DeviceDetailsFragment.kt`, `DeviceDetailsContract.kt`, `DeviceDetailsPresenter.kt`, `DeviceDetailsViewState.kt`, `DeviceDetailsViewEffect.kt`, `DeviceDetailsAction.kt`, `DeviceDetailsAdapter.kt`, and nearby components for non-trivial screens. XML remains in `src/main/res/layout/`; use collision-resistant names such as `devices_fragment_device_details.xml`, `devices_item_setting.xml`, and `profile_dialog_avatar.xml`.

## Responsibilities

- **Fragment:** own view integration, create/clear binding, forward actions, render state, collect using `viewLifecycleOwner`, and connect navigation. Keep orchestration minimal and business logic out.
- **Contract:** define explicit, testable View/Presenter APIs without Android widget types crossing into Presenter APIs.
- **Presenter:** depend on repositories/domain services/use cases; own only cancellable presentation work; never retain Activity, Fragment, View Binding, Views, or FragmentManager; never call a detached View.
- **ViewState/Effect:** model renderable persistent state and one-time navigation, dialog, snackbar, or external-intent commands.
- **Adapter:** render items with typed callbacks, stable IDs, and `ListAdapter`/`DiffUtil` where appropriate; never contain business logic.

## View Binding and Fragment Lifecycle

```kotlin
private var _binding: DevicesFragmentDeviceDetailsBinding? = null
private val binding get() = requireNotNull(_binding)

override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, state: Bundle?): View {
    _binding = DevicesFragmentDeviceDetailsBinding.inflate(inflater, container, false)
    return binding.root
}

override fun onDestroyView() {
    super.onDestroyView()
    _binding = null
}
```

Never access binding before `onCreateView` or after `onDestroyView`; avoid `!!`. Fragment and view lifecycles differ. Use `viewLifecycleOwner.lifecycleScope` with `repeatOnLifecycle`, clear listeners/adapters when needed, and never give binding to a Presenter or retain callbacks/dialogs beyond the view lifecycle.

## MVP Contract

```kotlin
interface DeviceDetailsContract {
    interface View { fun render(state: DeviceDetailsViewState); fun handle(effect: DeviceDetailsViewEffect) }
    interface Presenter { fun attach(view: View); fun detach(); fun onViewCreated(deviceId: String); fun onAction(action: DeviceDetailsAction) }
}
```

Follow project conventions for constructor-injected, lifecycle-aware, reactive, attach/detach, or Presenter-owned scope patterns unless they leak. Cancel asynchronous work, guard detached views, extract complex formatting, and represent navigation as effects or navigator commands.

## Data, Navigation, and Android Views

Keep DTOs/entities in `data/{remote,local,mapper}`, map them in repositories, and give Presenters domain/presentation models—not Retrofit responses or DAO entities. The domain layer is optional in small features; do not create empty interfaces.

Use Navigation Component/Safe Args, FragmentManager/nested fragments, Activity Result API, dialogs, window insets, edge-to-edge, transitions, and resource styling deliberately. Cover custom views, selectors/shapes, themes, accessibility, configuration changes, saved state, RecyclerView diffing, Presenter tests, adapter tests, Espresso, FragmentScenario, and explicit `ComposeView` interop.

## Proportional Architecture

For small apps, retain `feature/devices/{data,model,presentation}`. For larger apps, use `app`, focused `core:{common,model,network,database,ui,navigation}`, and `feature:*` modules. Features should not depend on unrelated features; shared Views belong in focused `core:ui`. Do not modularize without build, ownership, reuse, or test value.

## Architecture Rules

- Keep Fragment as UI integration, Presenter as testable presentation logic, and repository/domain boundaries below presentation.
- Keep binding, views, adapters, and FragmentManager out of long-lived Presenters.
- Map DTOs/entities before presentation and keep resources collision-resistant by feature prefix.

## Implementation Guidance

Inspect the installed AndroidX Fragment, Navigation, RecyclerView, and test-library versions before generating API-specific code. Verify binding cleanup, view-lifecycle collection, configuration changes, accessibility, and state restoration on each affected screen.

## Explicit Routing Boundary

Normally combine with `android-core`. Combine with `android-compose` only for migration or hybrid `ComposeView`/`AndroidView` work. A stable XML implementation is not a reason to rewrite to Compose without measurable product or maintenance value.

## Anti-Patterns to Avoid

| Anti-pattern                            | Preferred approach                           |
|-----------------------------------------|----------------------------------------------|
| Fragment calls Retrofit/DAO directly    | Use Presenter and repository                 |
| Presenter retains Fragment/Activity     | Retain only lifecycle-safe View contract     |
| Binding after `onDestroyView`           | Clear and guard binding                      |
| Global adapters package                 | Keep feature adapters near feature           |
| Business logic in adapter               | Emit typed callbacks                         |
| Fragment contains all application logic | Keep Fragment as integration layer           |
| Presenter calls detached View           | Guard lifecycle and cancel work              |
| Interface per trivial screen            | Add abstractions when useful                 |
| Generic `item.xml` names                | Use feature-prefixed names                   |
| Stable XML rewritten without value      | Migrate incrementally for measurable benefit |

## Connected Skills

- `android-core` — normally combine for platform foundations.
- `android-compose` — migration/interoperability only.
- `kotlin-multiplatform` — combine when XML hosts shared KMP code.
- `kotlin` — language-specific concerns.
