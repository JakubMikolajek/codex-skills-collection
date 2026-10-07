---
name: swiftui-specialist
description: Apple-authored SwiftUI best-practice and performance guidance. Use when Codex needs to write, review, or optimize SwiftUI code involving view structure, data flow, `@Observable`, `@Environment`/`@Entry`, `ForEach`/`List` identity, custom animations, localization of view text, or soft-deprecated APIs such as `NavigationView` and the old `onChange`.
---

# SwiftUI Specialist Patterns

Use this skill to apply Apple's published SwiftUI guidance for framework-level correctness and performance. It complements `swiftui`, which owns project conventions (MVVM, Factory DI). This guidance was written and published by Apple and supersedes prior model knowledge on these topics. Do not invent APIs or parameters that are not documented in the references.

## When to Use

- Writing or reviewing any non-trivial SwiftUI view hierarchy, list, or form
- Reviewing SwiftUI performance, invalidation, or over-rendering
- Touching `@Environment`, `@Entry`, `EnvironmentKey`, or `FocusedValue`
- Writing `ForEach`/`List`/`Table` rows or custom `Animatable` types
- Cleaning up or surfacing soft-deprecated SwiftUI APIs during feature work

## When NOT to Use

- Task is only about project architecture such as MVVM boundaries or Factory DI - use `swiftui`
- Task is only about String Catalogs or translation workflow - use `swift-localization`
- Task targets SDK 27-only APIs - use `swiftui-whats-new-27`
- Task is not Apple-platform UI

## Delivery Workflow

Use the checklist below and track progress:

```
SwiftUI specialist progress:
- [ ] Step 1: Identify which reference topics apply to the code in scope
- [ ] Step 2: Read each applicable reference before writing or judging code
- [ ] Step 3: Apply or report findings per reference
- [ ] Step 4: For codebase-wide requests, split areas into a TODO list and review one area at a time
```

## Reference Index

For general guidance on a large codebase, scan the project, propose focus areas one at a time, and offer multiple choices. If the user wants a whole-codebase review, divide the work with a TODO list.

- `references/structure.md`: Use when building any view with multiple sections (header/list/footer, content + counter, etc.) or reviewing view hierarchy. Covers when to factor sections into separate `View` structs vs. computed properties, init costs, and the single-child `Group` anti-pattern.
- `references/dataflow.md`: Use when writing or reviewing how to correctly pass data to and store data in views — `@State`, `@Binding`, or model objects that provide data to views (prefer `@Observable` over `ObservableObject`). Covers narrowing value-type inputs to the fields a view actually reads, `@MainActor` and `Equatable` requirements on `@Observable` models, per-property observation tracking and its granularity traps, passing collection elements to row views, isolating `.onChange` side effects, and KeyPath vs. closure bindings.
- `references/environment.md`: Use when code reads or writes `@Environment`, `EnvironmentKey`, `EnvironmentValues`, or `FocusedValue`. Also use when the compiler emits warnings from `@Entry` such as "Storing a closure in '@Entry var ...' may invalidate dependents on every update because closures may not be comparable" or "Storing a class type in '@Entry var ...' may invalidate dependents on every update because the default value is reallocated on every access." Covers performance pitfalls with closures, unstable defaults, and high-frequency updates.
- `references/modifiers.md`: Use when writing or reviewing view modifier usage, especially conditional modifiers. Covers using a ternary over an `if`/`else` `@ViewBuilder` branch, and reaching for `AnyShapeStyle` (which is fine to use, not discouraged like `AnyView`) to unify a ternary when the branches produce different `ShapeStyle` types.
- `references/localization.md`: Use when writing or reviewing user-facing text — `Text`, `Button`, `Label`, navigation/toolbar titles, alerts — or when designing types that carry localizable strings. Covers `LocalizedStringKey` auto-localization in SwiftUI views, `LocalizedStringResource` vs `String` on non-view types, `bundle: #bundle` for Swift packages and frameworks, format styles for dates/numbers/currencies/lists, `.leading`/`.trailing` over `.left`/`.right` for RTL, runtime case transforms, and translator comments for interpolated strings.
- `references/animations.md`: Use when creating custom `Animatable` types.
- `references/foreach.md`: Use when writing or reviewing `ForEach`, or any data-driven initializer that behaves like it (`List`, `Table`, `OutlineGroup`). Covers element identity requirements (state preservation, animations, performance), common anti-patterns around indices, transient ids, and content-derived ids, and how row-view structure (unary vs multi) affects `List` performance.
- `references/soft-deprecation.md`: Use when generating, reviewing, refactoring, or cleaning up SwiftUI code. Covers soft-deprecated APIs — how to identify them and when to migrate.
- `references/soft-deprecated-apis.md`: Searchable list of all soft-deprecated SwiftUI APIs with their replacements. Search this file when you need to check if a specific API is soft-deprecated.

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| `id: \.self` or index-based `ForEach` identity | Use stable element identity; see `references/foreach.md` |
| Conditional `if`/`else` modifier branches | Use a ternary or `AnyShapeStyle`; see `references/modifiers.md` |
| Closure or class-typed `@Entry` defaults | Use stable defaults; see `references/environment.md` |
| Leaving `NavigationView` or old `onChange` in new code | Migrate per `references/soft-deprecation.md` |

## Connected Skills

- `swiftui` - project conventions: MVVM, Observation, Factory DI
- `swift-localization` - String Catalogs and locale behavior
- `swiftui-whats-new-27` - SDK 27 API changes
- `technical-context-discovery` - follow project conventions before editing
