---
name: modernize-tests
description: Swift Testing migration and modernization. Use when Codex needs to migrate XCTest suites to Swift Testing or update existing Swift Testing tests to recommended patterns such as `#expect`, `#require`, `confirmation`, traits, and parameterized `@Test(arguments:)`.
---

# Modernize Tests Patterns

Use this skill to migrate XCTest to Swift Testing and to modernize existing Swift Testing code. Assertion mappings, error and async patterns, setUp/tearDown conversion, and guidelines live in `references/migration-reference.md`; read it before editing.

## When to Use

- User asks to migrate XCTest to Swift Testing
- Existing Swift Testing tests use outdated patterns or loop over inputs instead of parameterized tests
- Converting `XCTestExpectation`, `XCTSkip`, `XCTExpectFailure`, or `XCTAttachment`
- Converting `setUp`/`tearDown` to `init`/`deinit`

## When NOT to Use

- UI tests using XCUIAutomation - they must remain XCTest
- XCTests using `measure { ... }` performance APIs - they cannot migrate (other methods in the same class can)
- Task is web or Python testing - use `unit-testing` or `python-testing` via WORKFLOW routing

## Delivery Workflow

Use the checklist below and track progress:

```
Test modernization progress:
- [ ] Step 1: List XCTest classes and classify migratable vs. must-stay XCTest
- [ ] Step 2: Migrate one test class at a time using the reference mappings
- [ ] Step 3: Preserve `continueAfterFailure` semantics with `try #require`
- [ ] Step 4: Build and run tests; confirm no test was dropped
```

## Core Rules

- Migrate one test class at a time; a file may hold both XCTest and Swift Testing during migration.
- Prefer `struct` suites; use `actor` or `final class` only when `deinit` is needed.
- Do not turn `try #require` into `#expect`; that changes behavior.
- Add `@MainActor` only where XCTest's implicit main-actor isolation was relied on; add `@Suite(.serialized)` for shared mutable state.
- Use only public API; never introduce underscore-prefixed symbols such as `#_sourceLocation`.
- Convert repeated-logic tests to `@Test(arguments:)`.
- Add `import Foundation` when removing `import XCTest` if Foundation types are used.

Full mappings: `references/migration-reference.md`.

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Migrating UI or `measure {}` tests | Leave them as XCTest |
| Replacing `try #require` with `#expect` | Keep `#require` to preserve early exit |
| Adding `@MainActor` everywhere | Only where isolation was relied on |
| Keeping implicitly-unwrapped properties from `setUp` | Initialize inline or in `init` |

## Connected Skills

- `test-strategy` - decide what to test first
- `swiftui` - SwiftUI code under test
- `technical-context-discovery` - project test conventions
