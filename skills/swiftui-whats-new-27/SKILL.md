---
name: swiftui-whats-new-27
description: New SwiftUI APIs, behaviors, and deprecations in the 2027 OS releases (iOS 27 and aligned platforms). Use when Codex needs to adopt or review `reorderable`, swipe actions outside `List`, toolbar overflow, `AsyncImage` caching, item-binding `alert`/`confirmationDialog`, or to fix `@State` macro and `@ContentBuilder` build errors after an SDK update.
---

# SwiftUI What's New (SDK 27) Patterns

Use this skill to adopt SDK 27 SwiftUI APIs correctly. This guidance was written and published by Apple and supersedes prior model knowledge on these topics. Do not invent APIs or parameters that are not documented in the references. Several APIs have closely named overloads; read the relevant reference before writing code.

## When to Use

- Deployment target or SDK is iOS/macOS/watchOS/visionOS 27 or later
- SwiftUI build errors appear after an SDK update (`@State` used before initialized, invalid redeclaration, ambiguous `ShapeStyle` overloads)
- Adding drag-to-reorder, swipe actions in `ScrollView`/lazy stacks, or toolbar overflow behavior
- User asks what is new in SwiftUI 27

## When NOT to Use

- Deployment target predates 27 and no gating is wanted - use `swiftui` and `swiftui-specialist`
- Task is evergreen SwiftUI correctness - use `swiftui-specialist`
- Task is about App Intents - use `app-intents-whats-new-27`

## Delivery Workflow

Use the checklist below and track progress:

```
SDK 27 progress:
- [ ] Step 1: Confirm SDK and deployment target
- [ ] Step 2: Read the matching reference before writing code
- [ ] Step 3: Gate APIs with `@available` / `if #available` when the target predates 27
- [ ] Step 4: Build and verify; for `@State` errors follow `references/state-macro.md`, never just reorder init assignments
```

## Reference Index

- `references/reorderable.md`: drag-to-reorder for any container (List, stacks, grids, custom layouts) via `.reorderable()` on `ForEach` plus `.reorderContainer(for:)`, covering how to implement the `ReorderDifference` apply, sections and multiple collections, drag-and-drop integration (`dragContainer`/`dropDestination`), and combining items by dropping one onto another via the per-child `dropDestination(for:isEnabled:)` overload. Available on iOS/macOS/watchOS/visionOS 27; tvOS unavailable.
- `references/async-image.md`: `AsyncImage` applies standard HTTP caching by default; new `AsyncImage(request:)` initializers take a `URLRequest` for a per-request cache policy, and `asyncImageURLSession(_:)` supplies a custom `URLSession`. Available on iOS/macOS/watchOS/tvOS/visionOS 27.
- `references/toolbar.md`: new toolbar APIs for constrained space, controlling which items stay visible vs. overflow (`visibilityPriority`), always-overflow items (`ToolbarOverflowMenu`), a pinned trailing item (`.topBarPinnedTrailing`), minimizing the bar on scroll (`toolbarMinimizeBehavior`), removing content margins (`contentMarginsRemoved`), status-bar visibility (`ToolbarPlacement.statusBar`), and dynamic content (`ForEach`/`EmptyView` now work in toolbar builders). Availability varies per API; see the reference's table.
- `references/item-binding.md`: `confirmationDialog` and `alert` overloads that take an `item: Binding<T?>` (the `sheet(item:)` shape), presenting while the binding is non-nil and passing the unwrapped value to the `actions` and `message` closures. Available on iOS/macOS/watchOS/tvOS/visionOS 27.
- `references/swipe-actions.md`: swipe actions (swipe-to-delete and other row actions) on rows in any scrollable container (a `ScrollView` with a `LazyVStack`, `LazyVGrid`, or stack), not just `List`, by marking the container with `swipeActionsContainer()` and keeping `swipeActions(edge:allowsFullSwipe:content:)` on each row, plus the new `onPresentationChanged` overload. Available on iOS/macOS/watchOS/visionOS 27; tvOS unavailable.
- `references/state-macro.md`: `@State` migrated from a property wrapper to a macro. Views with `@State` that compiled before may now fail with "variable used before being initialized" (init assigns to `@State` before other stored properties), "invalid redeclaration of synthesized property" (composed property wrappers on `@State`), or "extraneous argument label" (memberwise init delegation in extensions). The fix is NOT to reorder assignments; consult this reference.
- `references/content-builder.md`: Unified result builders under `@ContentBuilder`. Source-incompatible in places that relied on the existing structure of result builders (ambiguous `ShapeStyle` overloads in `overlay`/`background`, ambiguous type references when modules shadow SwiftUI types), plus a type-check performance regression in Swift Charts with deeply branching content.

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Reordering init assignments to fix an `@State` macro error | Follow `references/state-macro.md` |
| Picking an overload from training memory | Read the reference first; overloads differ in closure signature and behavior |
| Using 27 APIs without availability gating | Gate with `@available` when the deployment target is lower |

## Connected Skills

- `swiftui` - project conventions
- `swiftui-specialist` - evergreen SwiftUI guidance
- `technical-context-discovery` - confirm SDK and deployment target
