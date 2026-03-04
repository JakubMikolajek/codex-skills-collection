---
name: swift-localization
description: Swift localization and internationalization patterns for multilingual Apple-platform apps. Use when Codex needs to build, refactor, debug, or review String Catalogs, localized SwiftUI text, `String(localized:)` usage, pluralization, locale-aware formatting, right-to-left behavior, or translation workflows across many languages in a Swift or SwiftUI codebase.
---

# Swift Localization Patterns

Use this skill for multilingual Swift and SwiftUI work with a bias toward modern Apple localization workflows. Assume the goal is not only translating strings, but keeping keys, formatting, grammar, and UI behavior correct across many locales.

## Delivery Workflow

Use the checklist below and track progress:

```
Swift localization progress:
- [ ] Step 1: Discover the current localization assets and project convention
- [ ] Step 2: Define key strategy and translator context
- [ ] Step 3: Implement localized strings, pluralization, and formatting
- [ ] Step 4: Verify multi-locale UI behavior
- [ ] Step 5: Review missing translations, fallbacks, and regressions
```

## Project Assumptions

- Prefer the repository's existing localization mechanism first.
- If the project is already on modern Apple localization workflows, prefer String Catalogs (`.xcstrings`).
- If the project still uses `Localizable.strings` or related legacy resources, stay consistent unless the task explicitly includes migration.
- Do not mix multiple localization strategies inside one feature without a reason.

## Keys and Source Strategy

- Keep one clear convention for how translatable content is identified.
- Reuse the project's existing key style:
  - semantic keys if the codebase uses them
  - source-string keys if the codebase already relies on them
- Keep keys stable; changing them casually creates unnecessary translation churn.
- Add translator-facing context when the meaning is ambiguous.
- Keep domain-specific strings grouped coherently by feature, screen, or table where the project pattern supports it.

## Localized Access Patterns

- Use localized APIs intentionally instead of hardcoding user-facing copy.
- Distinguish localized text from verbatim/debug/internal strings.
- Keep the UI layer declarative: localized display strings in views, business meaning in models and services.
- Prefer explicit localized resources for non-UI strings that are reused or passed across layers.
- Avoid hiding localization lookups inside random helpers where call sites lose meaning.

## Interpolation, Plurals, and Grammar

- Do not build sentences by concatenating translated fragments.
- Prefer placeholders and localized templates that allow word order to change across languages.
- Model pluralization explicitly; do not fake it with simple singular/plural conditionals when the language rules are richer.
- Keep gender, case, and grammar-sensitive phrases explicit when the product domain requires them.
- Preserve translator context for placeholders so the sentence can be translated correctly.

## Locale-Aware Formatting

- Use locale-aware formatting for dates, numbers, currency, measurements, and lists.
- Prefer system format styles or established project helpers over manual string formatting.
- Keep locale-sensitive formatting close to the presentation layer unless a shared formatter abstraction already exists.
- Ensure placeholder values remain compatible with the locale in which they are shown.

## Multi-Locale UI Verification

- Verify long strings, truncated text, and wrapped layouts.
- Check right-to-left behavior when the app supports RTL languages.
- Validate Dynamic Type together with localization because long strings amplify layout weaknesses.
- Use previews, runtime locale switching, or test fixtures to verify multiple locales intentionally.
- Watch for clipped buttons, collapsed rows, misaligned icons, and broken navigation titles.

## SwiftUI and Modern Apple Guidance

- Prefer the project's current SwiftUI localization pattern for `Text` and related UI labels.
- Use `Text(verbatim:)` only for truly non-localized content.
- For preview and verification flows, test representative locales such as:
  - source language
  - one long-text language
  - one RTL language if supported
- Keep localized resources compatible with the iOS 17+ stack already assumed in this repository.

## Translation Review Checklist

```
Coverage:
- [ ] New user-facing strings are localizable
- [ ] Existing keys are reused where appropriate
- [ ] Missing translations and accidental hardcoded strings are checked

Correctness:
- [ ] Plurals and placeholders are modeled intentionally
- [ ] Dates, numbers, and similar values are locale-aware
- [ ] Translator context exists where meaning is ambiguous

UX:
- [ ] Long strings and RTL behavior are verified where relevant
- [ ] Layout survives localization and Dynamic Type together
- [ ] Fallback behavior is understood and acceptable
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Hardcoded user-facing copy in Swift code | Route it through the project's localization system |
| Concatenating translated fragments into sentences | Use localized templates with placeholders |
| Changing key style per screen | Follow one project-wide convention |
| Manual date/number formatting for UI | Use locale-aware formatting |
| Treating localization as string replacement only | Verify grammar, layout, RTL, and fallback behavior |
| Using non-localized text APIs for translatable content | Use explicit localized APIs and reserve verbatim text for true literals |

## Connected Skills

- `swiftui` - use for SwiftUI view structure, MVVM, Observation, and UI verification context
- `technical-context-discovery` - follow project localization and iOS conventions before editing
- `ui-verification` - validate layout and visual behavior across locales when UI output matters
