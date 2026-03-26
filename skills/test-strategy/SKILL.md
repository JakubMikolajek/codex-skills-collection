---
name: test-strategy
description: Define the testing strategy for a project, module, or feature before writing any tests. Establishes what to test, at what level (unit / integration / e2e), with what priority, and why. Use before unit-testing, e2e-testing, or python-testing when no testing strategy exists or when the existing approach is not producing reliable results.
---

# Test Strategy

This skill sits one level above the testing implementation skills (`unit-testing`, `e2e-testing`, `python-testing`). It answers the question "what should we test and how" before any test code is written.

Use this skill when starting a new project, onboarding a new module with no tests, or when the current test suite is fragile, slow, or missing coverage in the wrong places.

## When to Use

- Starting a new project or module with no existing tests
- Existing test suite is slow, flaky, or producing false confidence
- Team is debating whether to write unit tests, integration tests, or E2E tests for a feature
- `/plan` output includes a testing phase but no test strategy has been defined
- Implementation-gap-analysis reveals test coverage exists but tests are testing the wrong things
- After a production incident where no test caught the regression

## When NOT to Use

- Test strategy already exists and is documented — go directly to `unit-testing`, `e2e-testing`, or `python-testing`
- Task is adding one test to an established, well-structured suite — no strategy needed
- User explicitly says "I know what tests I need, help me write them"

## Core Principles

### Test at the Right Level

The most common testing mistake is testing at the wrong level of the pyramid. This skill forces an explicit decision before any test is written.

```
         /\
        /  \   E2E (few, slow, high confidence on full flows)
       /----\
      /      \  Integration (moderate, test boundaries and contracts)
     /--------\
    /          \  Unit (many, fast, test logic in isolation)
   /____________\
```

**Rule**: Push tests as low in the pyramid as they can go while still catching real bugs. Do not write E2E tests for logic that can be verified at unit level. Do not write unit tests for behavior that only matters at integration level.

### Confidence Over Coverage

100% line coverage with tests that mock everything is worse than 60% coverage with tests that catch real regressions. This skill prioritises **confidence** — the probability that a failing test means something is actually broken — over raw coverage numbers.

### Risk-Weighted Prioritisation

Not all code deserves the same testing investment. High-risk areas get more coverage, more levels of testing, and stricter quality gates.

Risk factors:
- **User-facing**: any code a user directly interacts with
- **Data-mutating**: any code that writes, deletes, or transforms persistent data
- **Integration boundary**: any code that calls external services, databases, or message queues
- **Business-critical path**: any code that handles payments, auth, or core domain logic
- **Recently broken**: any area that has caused production incidents

Low-risk areas (utilities, formatting, pure transformations) need unit tests only, with no special treatment.

### Test Ownership Is Explicit

Every module in the test strategy has a named level and a named owner. "Someone should write tests" is not a strategy.

---

## Test Strategy Process

```
Test Strategy progress:
- [ ] Step 1: Inventory the system under test
- [ ] Step 2: Identify risk zones
- [ ] Step 3: Assign test levels per zone
- [ ] Step 4: Define coverage targets per zone
- [ ] Step 5: Select tooling
- [ ] Step 6: Define quality gates
- [ ] Step 7: Produce test-strategy.md output
```

**Step 1: Inventory the system under test**

List all modules, layers, and boundaries in scope:
- UI components / screens
- Business logic / domain services
- API handlers / controllers
- Data access layer / repositories
- External integrations (third-party APIs, queues, BLE, etc.)
- Infrastructure / config code

**Step 2: Identify risk zones**

For each item in the inventory, assess risk using the factors above (user-facing, data-mutating, integration boundary, business-critical, recently broken). Assign: `HIGH` / `MEDIUM` / `LOW`.

**Step 3: Assign test levels per zone**

For each zone, decide which test levels apply:

| Risk | Recommended levels |
|---|---|
| HIGH | Unit + Integration + E2E (for critical user flows) |
| MEDIUM | Unit + Integration |
| LOW | Unit only |

State the rationale explicitly. If you deviate from this table, document why.

**Step 4: Define coverage targets per zone**

Set realistic, risk-weighted targets. Do not use a single project-wide percentage.

Example:
```
auth/        → 90% line coverage, all error paths tested
payments/    → 95% line coverage, property-based tests on edge cases
ui/forms/    → component tests on all interactive states; no line % target
utils/       → 70% line coverage sufficient
```

**Step 5: Select tooling**

Choose the test runner and assertion library per layer. Prefer consistency within a stack layer. Document version and any known limitations.

Common defaults:
- TypeScript/JS unit+component: Vitest (preferred) or Jest + React Testing Library
- TypeScript/JS E2E: Playwright
- Python: pytest + pytest-asyncio for async
- Swift: XCTest + Swift Testing (SE-0439)
- Rust: built-in `#[test]` + `tokio::test` for async

If the project already has a test runner in use, default to it unless there is a strong reason to switch.

**Step 6: Define quality gates**

Quality gates are pass/fail conditions enforced in CI. Define them explicitly:

```
Quality gates:
- No merge if any unit test fails
- No merge if coverage drops below target for HIGH risk zones
- No merge if E2E suite fails on staging (not just local)
- Flaky test policy: [quarantine after N failures / fail immediately / skip with ticket]
```

**Step 7: Produce test-strategy.md output**

Write `test-strategy.md` in the repo root or the module root. This is the reference document for all subsequent test implementation work.

---

## Output Template

```markdown
# Test Strategy — [project or module name]

## Scope
[What is covered by this strategy. What is explicitly out of scope.]

## Risk Map

| Zone | Risk | Rationale |
|---|---|---|
| auth/ | HIGH | Handles tokens, session state, all user-facing login flows |
| utils/ | LOW | Pure transformations, no side effects |
| ... | ... | ... |

## Test Levels Per Zone

| Zone | Unit | Integration | E2E | Notes |
|---|---|---|---|---|
| auth/ | ✓ | ✓ | ✓ (login flow) | ... |
| utils/ | ✓ | — | — | ... |

## Coverage Targets

| Zone | Target | Measurement |
|---|---|---|
| auth/ | 90% lines, all error paths | Vitest coverage |
| ... | ... | ... |

## Tooling

| Layer | Tool | Version | Notes |
|---|---|---|---|
| Unit / component | Vitest | 2.x | ... |
| E2E | Playwright | 1.x | ... |

## Quality Gates

- [ ] No merge if any unit test fails
- [ ] No merge if HIGH zone coverage drops below target
- [ ] ...

## Anti-Goals
[What this strategy explicitly does NOT cover, and why.]
```

---

## Combination Rules

- `test-strategy` BEFORE `unit-testing`, `e2e-testing`, `python-testing` — strategy defines what to build; implementation skills define how
- `test-strategy` AFTER `architecture-design` — test level decisions depend on the system's layer boundaries
- `test-strategy` BEFORE any new service ships — quality gates must be defined before CI is wired
- When `implementation-gap-analysis` finds coverage missing in a HIGH risk zone, run `test-strategy` to reassess before writing more tests

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| One coverage % target for the whole project | Risk-weighted targets per zone |
| Mocking everything in unit tests to hit 100% | Test real behavior; mock only at boundaries |
| Writing E2E tests for logic testable at unit level | Push tests down the pyramid |
| No quality gates defined | Define gates before writing the first test |
| Strategy lives only in someone's head | Always write test-strategy.md |
| Skipping strategy because "we'll add tests later" | Strategy is fastest to write before any code exists |

## Connected Skills

- `unit-testing` — implementation counterpart for TS/JS unit and component tests
- `e2e-testing` — implementation counterpart for full-flow browser tests
- `python-testing` — implementation counterpart for pytest-based stacks
- `architecture-design` — system layer boundaries inform test level decisions
- `ci-cd` — quality gates from test-strategy feed CI pipeline configuration
- `code-review` — reviewers should verify tests match the strategy's risk map
