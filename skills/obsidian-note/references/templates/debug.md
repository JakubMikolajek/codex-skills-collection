---
date: {{date}}
type: debug
project: {{project-slug}}
severity: low | medium | high
tags: [debug, {{tech-tags}}]
links:
  - "[[01-projects/{{project-slug}}/_index]]"
  - "[[03-skills/domains/{{primary-tech}}]]"
---

# Debug: {{short title — technology + symptom}}

## Symptom
<!-- What did you see? Stack trace, logs, behavior — be concrete -->
```
{paste error / log}
```

## Environment
- Technology:
- Version:
- Context (prod/dev/test):

## Hypotheses (in testing order)
1. [ ] {{hypothesis-1}} → result:
2. [ ] {{hypothesis-2}} → result:

## Root cause
<!-- One line — what EXACTLY caused it -->

## Fix
```typescript
// before

// after
```

## Why this happened
<!-- Deeper understanding — what in the architecture / library allowed this -->

## How to prevent in the future
-

## Debugging time
<!-- e.g. 45 min — helps calibrate future estimates -->

## Related
-
