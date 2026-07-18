---
date: {{date}}
type: experiment
status: seed
scope: {{global | project-slug}}
confidence: {{low | medium | high}}
source: experiment
last_verified: {{date}}
technologies: [{{tech-1}}]
agent_priority: normal
supersedes: []
tags: [experiment, {{tech-tags}}]
links:
  - "[[01-projects/{{project-slug}}/_index]]"
---

# {{What was measured}}

## Hypothesis
<!-- what you expected to observe, and why -->

## Method
<!-- exactly how this was measured — concrete enough to repeat -->

## Result
```
{{raw data / numbers}}
```

## Conclusion
<!-- did the hypothesis hold, and what follows from it -->

## Threats to validity
<!-- what could have skewed the result -->
-

## Related
<!-- [[ADR-NNNN-slug]] if this result drove a decision -->
-
