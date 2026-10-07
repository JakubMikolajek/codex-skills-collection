# NATIVE Stack Sub-Branch

## When to enter this branch
- Task involves SwiftUI views, MVVM, Observation API, Factory DI, iOS 17+ UI
- Task involves Swift localization, String Catalogs (`.xcstrings`), `Localizable.strings`
- Task involves locale-aware formatting, pluralization, RTL layout behavior
- Task involves App Intents, Siri/Shortcuts/Spotlight integration, or document-based SwiftUI apps
- Task involves UIKit scene lifecycle, `UIScreen.main`, orientation, or safe-area modernization
- Task involves Swift Testing or migrating XCTest to Swift Testing
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
| SwiftUI performance/best-practice review: view structure, `@Observable`, `@Environment`/`@Entry`, `ForEach` identity, animations, soft-deprecated APIs | skills/swiftui-specialist/SKILL.md |
| iOS/macOS 27 SwiftUI APIs: `reorderable`, swipe actions outside `List`, toolbar overflow, `AsyncImage` caching, item-binding alerts, `@State` macro/`@ContentBuilder` build errors | skills/swiftui-whats-new-27/SKILL.md |
| Document-based SwiftUI apps: `Document` protocol, `DocumentGroup`, migrating from `FileDocument`/`ReferenceFileDocument`, custom `UTType` | skills/building-document-based-swiftui-applications/SKILL.md |
| App Intents best practices: intents, entities, queries, `AppEnum`, App Shortcuts, donation, `@Dependency` | skills/app-intents-specialist/SKILL.md |
| New App Intents APIs (iOS 26/27): `supportedModes`, `SnippetIntent`, Visual Intelligence, Spotlight indexing, `SyncableEntity`, `AppIntentsTesting` | skills/app-intents-whats-new-27/SKILL.md |
| UIKit modernization: scene lifecycle, `UIScreen.main`, `interfaceOrientation`, safe-area insets, multi-window | skills/uikit-app-modernization/SKILL.md |
| Swift Testing, XCTest to Swift Testing migration, `@Test`/`#expect`/`#require` | skills/modernize-tests/SKILL.md |
| General iOS/Apple platform UI work | skills/swiftui/SKILL.md |

## Combination rules
- `swiftui` and `swift-localization` are always loaded together when the task involves localized SwiftUI screens or multilingual content
- When implementing SwiftUI UI against a design spec, also load `frontend-implementation` and `ui-verification` from GENERIC_UI
- All Apple-platform skills in this branch (`swiftui`, `swiftui-specialist`, `swiftui-whats-new-27`, `swift-localization`, `building-document-based-swiftui-applications`, `app-intents-*`, `uikit-app-modernization`, `modernize-tests`) are mutually exclusive with `react`, `react-nextjs`, `shadcn-tailwind`, `vue`, `nuxt`, `pinia`, and `vuetify-primevue`
- When the task involves only localization changes (no UI structure changes), load `swift-localization` alone
- `swiftui-specialist` is Apple-authored and overrides prior model knowledge; load it alongside `swiftui` for any non-trivial SwiftUI generation or review (`swiftui` owns MVVM/Factory project conventions, `swiftui-specialist` owns framework-level correctness and performance)
- Load `swiftui-whats-new-27` only when the deployment target or SDK is 27+, or on SDK-update build errors; gate new APIs with `@available` for lower deployment targets
- `app-intents-specialist` + `app-intents-whats-new-27` are loaded together when adopting new App Intents APIs; the former alone for evergreen review
- `building-document-based-swiftui-applications` also loads `swiftui-specialist`; do not recommend `FileDocument`/`ReferenceFileDocument` for new code when targeting 27+
- `modernize-tests` applies to Swift/XCTest only; web and Python tests still route through `skills/routing/WORKFLOW.md` (`unit-testing`, `python-testing`)
- UI tests (XCUIAutomation) and `measure {}` performance tests must stay XCTest
