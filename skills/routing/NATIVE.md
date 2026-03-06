# NATIVE Stack Sub-Branch

## When to enter this branch
- Task involves SwiftUI views, MVVM, Observation API, Factory DI, iOS 17+ UI
- Task involves Swift localization, String Catalogs (`.xcstrings`), `Localizable.strings`
- Task involves locale-aware formatting, pluralization, RTL layout behavior
- Task targets Apple platforms (iOS, macOS, watchOS, tvOS)
- Files being edited are `.swift`, `.xcstrings`, or SwiftUI view files

## When NOT to enter this branch
- Task involves React, Next.js, or web UI — use skills/routing/REACT.md
- Task involves Vue, Nuxt, or web UI — use skills/routing/VUE.md
- Task is framework-agnostic UI guidance or UI verification only — use skills/routing/GENERIC_UI.md
- Task involves Kotlin Android (not Apple platforms) — use skills/routing/BACKEND.md

## Decision tree

For tasks matching this branch, load the appropriate leaf skill(s):

| If the task involves... | Read next |
|-------------------------|-----------|
| SwiftUI views, MVVM, state management, navigation, Observation API, Factory DI | skills/swiftui/SKILL.md |
| Swift localization, String Catalogs, pluralization, locale-aware formatting, RTL | skills/swift-localization/SKILL.md |
| General iOS/Apple platform UI work | skills/swiftui/SKILL.md |

## Combination rules
- `swiftui` and `swift-localization` are always loaded together when the task involves localized SwiftUI screens or multilingual content
- When implementing SwiftUI UI against a design spec, also load `frontend-implementation` and `ui-verification` from GENERIC_UI
- `swiftui` and `swift-localization` are mutually exclusive with `react`, `react-nextjs`, `shadcn-tailwind`, `vue`, `nuxt`, `pinia`, and `vuetify-primevue`
- When the task involves only localization changes (no UI structure changes), load `swift-localization` alone
