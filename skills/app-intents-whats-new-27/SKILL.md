---
name: app-intents-whats-new-27
description: New App Intents APIs introduced in iOS 26 and iOS 27. Use when Codex needs to adopt `supportedModes`, `SnippetIntent`, Visual Intelligence queries, Spotlight indexing, `RelevantEntities`, `SyncableEntity`, `LongRunningIntent`, `SystemShortcut`, `AppIntentsTesting`, or Apple Intelligence schemas, or migrate off `openAppWhenRun` and `@AssistantIntent`.
---

# App Intents What's New Patterns

Use this skill to adopt iOS 26/27 App Intents APIs. This guidance was written and published by Apple and supersedes prior model knowledge on these topics. Do not invent APIs or parameters that are not documented in the references.

## When to Use

- Declaring where an intent runs with `supportedModes` or migrating off `openAppWhenRun`
- Returning interactive snippets, Visual Intelligence results, or Spotlight-indexed entities
- Adopting cross-device entities, relevance, long-running, or cancellable intents
- Unit-testing intents with `AppIntentsTesting`
- User asks what is new in App Intents for iOS 26/27

## When NOT to Use

- Task is evergreen App Intents review - use `app-intents-specialist`
- Deployment target predates the API and no gating is wanted
- Task is not Apple-platform

## Delivery Workflow

Use the checklist below and track progress:

```
App Intents 26/27 progress:
- [ ] Step 1: Confirm deployment target
- [ ] Step 2: Read the matching reference before writing code
- [ ] Step 3: Gate each API with its documented `@available` floor
- [ ] Step 4: Verify public API only and unchanged identifier contracts
```

## Guardrails and Reference Index

### Guardrails

- **Public API only.** Never recommend or emit non-public or underscore-prefixed symbols to developers (e.g. `_`-prefixed types, or a symbol that was public in a past release but is no longer public in the current SDK).
- **Ground every symbol.** Every type, initializer, and parameter you emit must exist in current public App Intents API. Do not invent API to make a snippet compile.
- **Treat identifiers and phrases as a public contract.** An `AppEntity.id` scheme, an `AppEnum` raw value, an `AppShortcut` phrase, and an intent's type name are depended on by saved shortcuts, donations, and Spotlight. Adding is safe; renaming/removing/renumbering is a behavior-changing edit — flag it, don't do it silently.
- **Gate every version-specific API.** Tag it with its real `@available` floor (the value in each reference); when the deployment target predates the floor, gate with `@available` / `if #available` rather than dropping the feature. Never misdate availability.

### SDK 26.0 (2025)

- `references/execution-modes.md`: Declaring where an intent runs with `supportedModes` / `IntentModes` (`.background`, `.foreground(.immediate/.deferred/.dynamic)`) and migrating off the deprecated `openAppWhenRun`; foreground continuation (`continueInForeground` / `needsToContinueInForegroundError`, gated on `systemContext.currentMode.canContinueInForeground`); `UndoableIntent`. Also covers, at their own availability, `CancellableIntent` / `IntentCancellationReason` (iOS 26.4) and — new in 27.0 — `LongRunningIntent` + `performBackgroundTask(options:)` + `LongRunningTaskOptions` and `IntentExecutionTargets` / `allowedExecutionTargets`. Availability varies per API; see the reference's table.
- `references/interactive-snippets.md`: Returning an interactive snippet from `perform()` with `SnippetIntent` (`.result(snippetIntent:)`) vs. a static `.result(view:)`; driving in-snippet actions with `Button(intent:)` / `Toggle(isOn:intent:)`; refreshing the card in place; the rule that `SnippetIntent.perform()` must be side-effect-free/idempotent because the system may re-run it. iOS 26.0 (static snippet view iOS 16.0; intent-backed controls iOS 17.0).
- `references/requestchoice.md`: Pausing `perform()` to ask the person to pick from a small fixed set with `requestChoice(between:dialog:)` returning an `IntentChoiceOption` (`.default`/`.destructive` styles; `IntentChoiceOption.cancel` throws on selection). The multi-option sibling of `requestConfirmation`; not for open-ended entity selection. iOS 26.0.
- `references/visual-intelligence.md`: Surfacing entities to Visual Intelligence (camera/screenshot search) with an `IntentValueQuery` over `SemanticContentDescriptor` (which lives in the **VisualIntelligence** framework — `import VisualIntelligence`), returning multiple entity types with `@UnionValue`, and one `OpenIntent` per returned type. iOS 26.0.
- `references/onscreen-entities.md`: Resolving "this" on the current screen to an `AppEntity` by annotating the foreground `NSUserActivity` — `appEntityIdentifier` / `AppEntityAnnotatable` built with `EntityIdentifier(for:)` — plus finer-grained onscreen-element reporting via `AppEntityUIElement` / `AppEntityUIElementsContext`. iOS 18.2 (UI elements iOS 18.4).
- `references/spotlight-indexing.md`: Mapping entity values into `CSSearchableItemAttributeSet` with `@Property` / `@ComputedProperty` / `@DeferredProperty(indexingKey:)` (iOS 26.0); the system-driven reindex hook `IndexedEntityQuery` (`reindexEntities(for:indexDescription:)` / `reindexAllEntities(indexDescription:)`, iOS 27.0); and linking an existing `CSSearchableItem` to an entity with `relatedAppEntityIdentifier` (iOS 27.0). `IndexedEntity` itself and `indexAppEntities`/`deleteAppEntities` are the iOS 18 baseline.
- `references/convenience-properties.md`: `@ComputedProperty` (synchronous, reads the source of truth) and `@DeferredProperty` (`get async throws`, for expensive/lazy values) — read-only entity-property projections, never for `id` or writable state. Includes their `title:` and `indexingKey:` overloads. iOS 26.0.
- `references/schema-adoption.md`: Adopting Apple Intelligence schemas with `@AppIntent(schema:)` / `@AppEntity(schema:)` / `@AppEnum(schema:)` — a schema mandates a fixed typed shape the system can invoke, validated by a build tool after compilation. Central trap: the `@AssistantIntent`/`@AssistantEntity`/`@AssistantEnum` + `AssistantSchema` family is **deprecated** (renamed to the `@App*` forms). The macros are iOS 18.0; which schema *domains* are available depends on the SDK (only some are public). Also covers which public domains reach which surface (Apple Intelligence/Siri vs Visual Intelligence vs `assistant` side-button vs Shortcuts-only), the all-or-nothing `mail`/`clock`/`messages` groups, and migrating with `isAssistantOnly`.

### SDK 27.0 (2026)

- `references/relevance-and-context.md`: Hinting which entities are relevant right now so the system suggests them (even for never-searched/never-played content) with `RelevantEntities.shared.updateEntities(_:for:)` (replace-on-update per context) and the remove API, keyed by `AppEntityContext` — the shipping contexts are `.audio(.nowPlaying)` and the HealthKit `.audio(.workout…)` family (e.g. surface a running playlist when a run starts). Complements Spotlight (searchable) and interaction donation (learned patterns). iOS 27.0.
- `references/cross-device-and-ownership.md`: Giving an entity a stable identity across a person's devices with `SyncableEntity` / `SyncableEntityIdentifier` (pairing a local and a stable id), and expressing shared/public ownership with `EntityOwnership` / `OwnershipProvidingEntity` so the system can gate confirmation on shared or public entities. iOS 27.0.
- `references/system-shortcuts.md`: Running a person's chosen system shortcut with `SystemShortcut` + `RunSystemShortcutIntent(shortcut:)` — a narrow API meant only to back a `Button(intent:)` inside a widget configuration. iOS 27.0, iPhone/iPad only (unavailable on macOS/watchOS/tvOS/visionOS).
- `references/testing.md`: Unit-testing intents with the `AppIntentsTesting` framework (`import AppIntentsTesting`), which runs intents/queries **out-of-process against the installed app under test** (XCTest): build via `IntentDefinitions(bundleIdentifier:)` → `makeIntent` / `makeReference` → `AnyAppIntent.run()`; read the throwing `ResolvedIntentResult.value` (`.as(_:)` for rich types); assert entities/queries via the type-erased wrappers (`AnyAppEntity` / `AnyEntityQuery`); value queries via `values(for:)` / `.items`; `viewAnnotations()` (needs a launched `XCUIApplication`); `spotlightQuery(_:)` (needs CoreSpotlight indexing). No in-process dependency injection — deterministic data comes from the app's own queries. iOS 27.0.
- `references/entity-collection.md`: `EntityCollection<Entity>` — an identifier-first collection for large entity sets. As a `@Parameter`/`@Property` it stores `[Entity.ID]` and defers hydration, avoiding the forced full-resolution that a `[Entity]` parameter triggers; call `resolvedEntities()` (cached) only when you need the instances. iOS 27.0.
- `references/union-values.md`: Surfacing a `@UnionValue` type as a **Shortcuts parameter** — `AppUnionValue` / `AppUnionValueCasesProviding` give the union nominal identity + case metadata so it appears as a selectable parameter. (The results-side use of `@UnionValue` for visual queries is in `visual-intelligence.md`.) iOS 27.0.

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Misdating availability | Use the floor stated in each reference |
| Dropping a feature for older targets | Gate with `@available` / `if #available` |
| Renaming shipped identifiers silently | Flag as behavior-changing |

## Connected Skills

- `app-intents-specialist` - evergreen App Intents practices
- `swiftui` - UI around intents
- `technical-context-discovery` - confirm deployment target
