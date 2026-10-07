---
name: app-intents-specialist
description: Apple-authored App Intents best practices. Use when Codex needs to write, review, refactor, or extend App Intents code involving intents, `AppEntity`, queries, `AppEnum`, parameters, App Shortcuts phrases, donation, `@Dependency`, results and errors, or widget/control configuration intents.
---

# App Intents Specialist Patterns

Use this skill for evergreen App Intents correctness. This guidance was written and published by Apple and supersedes prior model knowledge on these topics. Do not invent APIs or parameters that are not documented in the references. For iOS 26/27 APIs use `app-intents-whats-new-27`.

## When to Use

- Writing or reviewing any `AppIntent`, `AppEntity`, `EntityQuery`, or `AppEnum`
- Defining App Shortcuts phrases or parameter summaries
- Reviewing intent execution, errors, donation, or dependency registration
- Doing a codebase-wide App Intents review
- Adding widget or control configuration intents

## When NOT to Use

- Task adopts iOS 26/27-only App Intents APIs - use `app-intents-whats-new-27`
- Task is general SwiftUI UI work - use `swiftui`
- Task is not Apple-platform

## Delivery Workflow

Use the checklist below and track progress:

```
App Intents progress:
- [ ] Step 1: Identify which reference topics apply
- [ ] Step 2: Read each applicable reference before writing or judging code
- [ ] Step 3: Treat intent type names, entity ids, enum raw values, and phrases as a public contract
- [ ] Step 4: Verify only public API is used
```

## Guardrails and Reference Index

Review App Intents code following these references to help you follow best practices and idiomatic patterns. Use the references also when writing new App Intents code.

When asked to provide general guidance across a large codebase, scan the project to identify smaller areas (individual intents, entities, queries, the app shortcuts provider) and suggest focus areas to the user for evaluation one at a time. Provide multiple choices where applicable. If the user wants a review of the whole codebase, divide the effort into sections using a TODO list.

Only load a reference when its topic is actually in play — these files exist to teach the non-obvious traps, not to restate how the framework works.

### Guardrails

- **Public API only.** Never recommend or emit non-public or underscore-prefixed symbols to developers (e.g. `_`-prefixed types). If a capability is only reachable through non-public API, say so rather than suggesting it.
- **Ground every symbol.** Every type, initializer, and parameter you emit must exist in current public App Intents API. Do not invent API to make a snippet compile.
- **Treat identifiers and phrases as a public contract.** Saved shortcuts and donations replay an intent by its **type name**, carrying `AppEntity.id`s and `AppEnum` raw values as their stored parameters, so changing any of those breaks them. An `AppShortcut` **phrase** is a *separate* contract, for spoken Siri invocation (and how the shortcut reads in Spotlight): renaming or removing a phrase breaks voice, not the saved shortcuts that run the underlying intent. Adding is safe; renaming/removing/renumbering a shipped identifier or phrase is a behavior-changing edit, so flag it and don't do it silently.

### References

Ordered by value.

- `references/execution-model.md`: **Anchor.** `perform()` is `async throws`, **not** `@MainActor` (hop for UI state), and **retriable** (`restartPerform` re-runs from the top, no rollback — do irreversible work last, idempotently). Return via `.result(...)` factories, never a bare struct.
- `references/entities-and-queries.md`: `AppEntity.id` must be stable across launches/devices; `entities(for:)` (required, batched — no N+1) vs empty-default `suggestedEntities()`; `EntityStringQuery.entities(matching:)` isn't auto-filtered; only `@Property` members are system-visible; `EnumerableEntityQuery` loads everything.
- `references/entity-property-queries.md`: `EntityPropertyQuery` for Shortcuts "Find X where…" — declare `properties`/`sortingOptions`, implement `entities(matching:mode:sortedBy:limit:)`; the framework parses the predicate, *you* execute it.
- `references/app-enum.md`: `AppEnum` raw values are **persisted by string** (never renumber/reorder — assign stable values, only append); every case needs a `caseDisplayRepresentations` entry or it's a runtime `fatalError`.
- `references/parameters.md`: prefer `requestValue(_:)` / `needsValueError(_:)` (old `-> Error` spelling deprecated); non-optional `AppEnum` auto-disambiguates; only params in `Summary(...)` appear in the editor.
- `references/parameter-summaries.md`: `Summary("…\(\.$x)…") { \.$y }` sets which params show and in what order (summary order, not declaration); `When`/`Switch`/`Case` show/hide by another param's value.
- `references/dependencies.md`: unregistered `@Dependency` is a `fatalError` (register at `App.init()`); works on `AppIntent`/`EntityQuery`, **not** on `AppEntity`/`AppEnum`; value must be `Sendable` (a plain `@Observable` store isn't — isolate to `@MainActor` or make it an `actor`).
- `references/results-and-errors.md`: only `CustomLocalizedStringResourceConvertible` errors surface a real message; conform your error, or throw the prebuilt `PermissionRequired`/`UserActionRequired`/`Unrecoverable` (iOS 18+).
- `references/donation.md`: in-app actions are **not** auto-donated — call `IntentDonationManager.shared.donate(intent:)`; `PredictableIntent` supplies descriptions, not donations.
- `references/localization.md`: user-facing strings must be **literal** `LocalizedStringResource` (a runtime `String` yields no extractable key); interpolate into a localized template.
- `references/app-shortcut-phrases.md`: provide `shortTitle` + `systemImageName` (no-metadata init deprecated iOS 17); include `\(.applicationName)` or the runtime index silently drops the phrase.
- `references/factoring.md`: `AppEnum` = fixed set; `AppEntity` + `EntityQuery` = dynamic/queryable; plain `@Parameter` = free-form. Prefer one intent per atomic task over a mega-intent.
- `references/url-representation.md`: `OpenIntent` (its `target` is what opens), `OpenURLIntent`, and `URLRepresentableIntent`/`URLRepresentableEntity`/`URLRepresentableEnum` with the `urlRepresentation` builder; keep the URL mapping stable like an id/phrase contract.
- `references/configuration-intents.md`: `WidgetConfigurationIntent` (iOS 17) / `ControlConfigurationIntent` (iOS 18) are parameter-only — **no** `perform()` (the framework supplies a throwing default); `SetValueIntent` is the toggle control.

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Renaming or renumbering shipped intent names, entity ids, enum raw values, or phrases silently | Flag it as behavior-changing |
| `@MainActor` `perform()` or irreversible work before the end | See `references/execution-model.md` |
| Emitting underscore-prefixed or invented API | Use public API only |

## Connected Skills

- `app-intents-whats-new-27` - iOS 26/27 APIs
- `swiftui` - UI around intents
- `technical-context-discovery` - project conventions
