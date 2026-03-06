---
name: multi-repo
description: Coordinate changes that span multiple repositories. Use when a task involves API contract changes, shared types, coordinated releases, or any modification that has consumers in other repos.
---

# Multi-Repo Coordination

This skill provides a structured process for coordinating changes that span multiple repositories. It enforces contract-owner-first ordering, cross-repo impact detection, and mandatory handoff documentation.

## When to Use

- Changing an API endpoint, request/response shape, or auth contract
- Modifying shared types, interfaces, or proto definitions
- Updating environment variables or config schema used across repos
- Coordinating a release across frontend, backend, and/or mobile
- Database schema changes with consumers in multiple services

## When NOT to Use

- Changes affect only one repository — use the appropriate domain skill directly
- Task is about reading or analyzing multiple repos without modifying them
- Cross-repo dependency is only a version bump with no contract change

## Core Principles

### Map Before Touching Anything

1. Identify the contract owner (the repo that defines the shared interface)
2. List all consumer repos and their dependency on the contract
3. Determine change propagation order: owner first, consumers after
4. Confirm which repos are accessible in the current session

### Change Propagation Order

- Never modify a consumer repo before the contract owner is updated
- If consumer repos are not accessible, produce a per-repo checklist for manual follow-up
- Each affected repo gets a scoped task description: what changes, why, what to verify

## Multi-Repo Process

Use the checklist below and track your progress:

```
Multi-repo progress:
- [ ] Step 1: Map contract owner and consumers
- [ ] Step 2: Detect cross-repo impact
- [ ] Step 3: Update contract owner first
- [ ] Step 4: Propagate changes to consumers
- [ ] Step 5: Coordinate versioning
- [ ] Step 6: Produce session handoff with per-repo status
```

**Step 1: Map contract owner and consumers**

Identify which repo owns the shared interface. List every consumer repo and how it depends on the contract (import, API call, env var, shared type).

**Step 2: Detect cross-repo impact**

Check for these cross-repo impact signals:

- Exported TypeScript types / Swift protocols / Kotlin interfaces changed
- REST endpoint path, method, or response shape changed
- GraphQL schema changed
- Environment variable added, renamed, or removed
- Database table or column renamed or removed

**Step 3: Update contract owner first**

Make changes in the contract owner repo before touching any consumer. Run `project-context` for the owner repo if not already done.

**Step 4: Propagate changes to consumers**

For each accessible consumer repo:
1. Run `project-context` for the consumer repo
2. Apply the contract change
3. Verify the consumer builds and tests pass

For inaccessible consumer repos, produce a scoped task description for manual follow-up.

**Step 5: Coordinate versioning**

- If repos use independent versioning: bump contract owner first, update consumer dependency references
- If repos release in lockstep: coordinate version bump across all affected repos
- Document version coordination decision in session handoff

**Step 6: Produce session handoff with per-repo status**

Mandatory: always end with `session-handoff` listing per-repo status:

| Repo | Status |
|---|---|
| [contract-owner] | Complete / In Progress / Blocked |
| [consumer-1] | Complete / In Progress / Blocked / Not Accessed |
| [consumer-2] | Complete / In Progress / Blocked / Not Accessed |

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Modifying consumer before contract owner | Always update owner first |
| Marking task complete with inaccessible repos | List as Blocked in handoff with instructions |
| Changing contract without listing consumers | Map all consumers before any change |
| Coordinating release verbally | Document version plan in session handoff |
| Assuming consumer repos use same conventions | Run `project-context` per repo |
| Skipping handoff on multi-repo tasks | Handoff is mandatory — never skip |

## Connected Skills

- `project-context` — run per repo before starting cross-repo work
- `session-handoff` — mandatory at end of every multi-repo task
- `architecture-design` — consult before changing shared contracts
- `sql-and-database` — coordinate when schema changes are involved
