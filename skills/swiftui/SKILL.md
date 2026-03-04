---
name: swiftui
description: SwiftUI implementation and review patterns for iOS 17+ Apple-platform UI using MVVM, the Observation API, and Factory-based dependency injection. Use when Codex needs to build, refactor, debug, or review SwiftUI views, navigation flows, state management, forms, lists, async presentation logic, or dependency wiring in an MVVM SwiftUI codebase.
---

# SwiftUI Implementation Patterns

Use this skill to keep SwiftUI changes composable, state-safe, and aligned with iOS 17+, MVVM, the new Observation APIs, and `Factory` for dependency injection.

## Delivery Workflow

Use the checklist below and track progress:

```
SwiftUI progress:
- [ ] Step 1: Discover project conventions and navigation model
- [ ] Step 2: Map screen state, ViewModel ownership, and Factory dependencies
- [ ] Step 3: Compose views into small reusable units
- [ ] Step 4: Wire Observation-based bindings and async work safely
- [ ] Step 5: Verify accessibility, previews, and tests
```

## Platform Assumptions

- Target iOS 17+ by default.
- Prefer the modern Observation model over legacy `ObservableObject` patterns unless the project still depends on older code paths.
- Do not add compatibility fallbacks for pre-iOS 17 APIs unless the repository explicitly requires them.

## State Management Rules

- Keep `View` types focused on presentation and lightweight interaction wiring.
- Prefer one clear source of truth for screen state.
- Treat the `ViewModel` as the owner of screen business state in MVVM flows.
- Use the project's existing observation model first; do not mix competing patterns without a reason.
- Keep transient UI state local to the view and move shared/business state into an observable `ViewModel`.
- Derive display values from state instead of duplicating them.

### Property Wrapper Guidance

| Use case | Preferred approach |
|---|---|
| View-local ephemeral state | `@State` |
| Child edits parent-owned state | `@Binding` |
| View binds into an observable model | `@Bindable` where binding into Observation-backed state is needed |
| View owns lifecycle of observable model | Instantiate or inject the MVVM `ViewModel` using the project-standard ownership pattern |
| View receives externally owned observable model | Keep ownership upstream and pass the model intentionally |
| Global shared dependencies | `Factory`-backed injection or existing environment pattern only when already established |

## MVVM Boundaries

- Keep SwiftUI `View` types declarative and thin.
- Put business decisions, loading orchestration, and mutation logic in the `ViewModel`.
- Keep the `ViewModel` API intention-revealing: inputs as methods/actions, outputs as observable state.
- Avoid turning the `ViewModel` into a generic service container; inject explicit dependencies instead.

## Observation API Guidance

- Prefer `@Observable` models for screen state on iOS 17+ codepaths.
- Use `@Bindable` when the view needs direct bindings into observable model properties.
- Keep observation granular enough that the screen updates predictably.
- Do not mix legacy Combine-style observation and new Observation patterns inside one feature unless the surrounding architecture forces it.

## Factory Dependency Injection

- Use `Factory` as the default DI mechanism when resolving services, repositories, or coordinators.
- Resolve dependencies at clear boundaries, typically in composition roots or ViewModel initialization, not ad hoc throughout the view tree.
- Keep `Factory` registrations aligned with feature boundaries and environment needs.
- Prefer injecting protocol-shaped collaborators into the `ViewModel` over resolving dependencies repeatedly inside methods.

## View Composition

- Split large screens into focused subviews before a single file becomes hard to scan.
- Extract reusable rows, sections, and controls when they have a stable API.
- Keep modifiers close to the element they affect unless a reusable style abstraction already exists.
- Avoid deep nesting when a helper view or computed subview will make structure clearer.
- Prefer data-driven rendering for repeated content.

## Navigation and Presentation

- Follow the app's existing navigation model exactly.
- Keep navigation intent close to the state that controls it.
- Model sheets, alerts, confirmation dialogs, and destination routing explicitly instead of using scattered booleans.
- Reset temporary presentation state when dismissal should clear stale data.

## Async Work and Side Effects

- Keep side effects out of the `View` where practical; route them through the `ViewModel`.
- Isolate loading, refresh, and mutation states explicitly.
- Prevent duplicate requests from repeated lifecycle triggers.
- Keep async tasks cancellable when the screen can disappear.
- Update UI state on the main actor when required by the project pattern.
- Surface loading, empty, success, and error states intentionally.

## Performance and Rendering

- Avoid expensive derived computations inside `body`.
- Prefer stable identity in `ForEach` and list rendering.
- Limit unnecessary re-renders caused by broad shared state.
- Do not hide architectural problems behind ad hoc memoization.

## Accessibility and UX

- Provide clear labels, values, and hints for interactive elements.
- Preserve logical focus and reading order.
- Ensure tap targets are comfortably usable.
- Support dynamic type and long localized strings.
- Do not encode meaning with color alone.

## SwiftUI Review Checklist

```
Structure:
- [ ] View hierarchy is readable and decomposed appropriately
- [ ] State ownership is clear and non-duplicated
- [ ] Navigation and presentation state are explicit

Behavior:
- [ ] Loading, error, empty, and success states are handled
- [ ] Async work is not triggered redundantly
- [ ] User actions cannot leave stale state behind

Quality:
- [ ] MVVM boundaries remain clear
- [ ] Observation API usage is consistent
- [ ] Factory-based dependencies are resolved intentionally
- [ ] Accessibility is covered
- [ ] Previews or equivalent fast feedback paths exist where appropriate
- [ ] Tests cover critical state transitions and presentation logic
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| One giant screen view | Split into subviews with clear responsibilities |
| Duplicate booleans for the same presentation state | Use one explicit routing/presentation model |
| Business logic in `body` | Move logic into the `ViewModel` or focused helpers |
| Hidden side effects in view builders | Trigger side effects intentionally and visibly |
| Legacy observation added to new iOS 17-only features without reason | Use `@Observable` and `@Bindable` consistently |
| Resolving dependencies all over the feature | Inject collaborators cleanly with `Factory` and clear ownership |
| New app-wide state pattern for one feature | Reuse the project's existing pattern |

## Connected Skills

- `swift-localization` - use when the task involves multilingual strings, String Catalogs, or locale-aware UI behavior
- `technical-context-discovery` - follow project iOS conventions before editing
- `frontend-implementation` - apply UI quality and accessibility rules
- `ui-verification` - verify screen output against approved designs when relevant
