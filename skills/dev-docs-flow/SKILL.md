---
name: dev-docs-flow
description: Build structured engineering documentation and execution flow artifacts by composing existing dev skills. Use when the user asks for docs + flow outputs, asks for `/docs-flow`, explicitly names `dev-docs-flow`, or needs one consolidated artifact from research/planning/implementation/review context.
---

# Dev Docs Flow

Generate a consistent docs package and execution flow by orchestrating existing skills. Do not duplicate guidance that already exists in other skills.

## Process

Use the checklist below and track progress:

```
Docs-flow progress:
- [ ] Step 1: Confirm input and target output
- [ ] Step 2: Discover technical context
- [ ] Step 3: Run implementation gap analysis
- [ ] Step 4: Build docs artifact
- [ ] Step 5: Build flow artifact
- [ ] Step 6: Validate quality gates
```

### Step 1: Confirm input and target output

- Parse the user request or command.
- If command is `/docs-flow`, treat it as a request for both artifacts:
  - Structured documentation artifact
  - Execution flow artifact
- If the user asks only for one artifact, produce only that artifact.

### Step 2: Discover technical context

- Use `technical-context-discovery` to identify project instructions and existing patterns.
- Reuse repository conventions from `AGENTS.md`, existing `skills/*`, and local templates.
- Avoid inventing new workflow phases unless explicitly requested.

### Step 3: Run implementation gap analysis

- Use `implementation-gap-analysis` to classify scope into:
  - To be implemented
  - To be modified
  - To be reused
- Use this classification as the core of planning and flow ordering.

### Step 4: Build docs artifact

- Use `references/docs-template.md` as the default structure.
- Fill sections with repository-backed facts, assumptions, gaps, and acceptance criteria.
- Keep output concise and directly actionable.

### Step 5: Build flow artifact

- Use `references/flow-template.md` as the default structure.
- Provide:
  - Mermaid flowchart
  - Ordered phase checklist
  - Decision gates and dependencies
- Ensure flow is runnable phase-by-phase.

### Step 6: Validate quality gates

- Confirm every task in the docs has a matching element in the flow.
- Confirm each phase has explicit quality gates.
- Confirm output is aligned with current workflow:
  - Research
  - Plan
  - Implement
  - Review

## Output Rules

- Prefer inline output unless the user explicitly asks to write files.
- Use absolute file references when pointing to repository files.
- Mark assumptions clearly and keep open questions explicit.
- If critical context is missing, ask focused clarification questions before finalizing.

## Connected Skills

- `technical-context-discovery` - establish conventions before generating docs/flow
- `implementation-gap-analysis` - map created/modified/reused scope
- `architecture-design` - structure phase-based solution and quality gates
- `task-analysis` - expand requirements and identify missing task context
- `code-review` - define final review gate and residual risk reporting

## References

- Docs template: `references/docs-template.md`
- Flow template: `references/flow-template.md`
