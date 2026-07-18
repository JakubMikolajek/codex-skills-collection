---
date: {{date}}
type: playbook
status: seed
scope: {{global | project-slug}}
confidence: {{low | medium | high}}
source: {{code | docs | experiment | conversation}}
last_verified: {{date}}
technologies: [{{tech-1}}]
agent_priority: normal
supersedes: []
tags: [playbook, {{tech-tags}}]
links:
  - "[[01-projects/{{project-slug}}/_index]]"
---

# {{Situation this playbook handles}}

## When to run this
<!-- the concrete symptom/situation that tells you this is the case -->

## Steps
1. {{step 1}}
2. {{step 2}}
3. {{step 3}}

## How to verify it worked
-

## If this doesn't work
<!-- next step / escalation -->

## Related incidents
<!-- [[04-debug/...]] -->
-
