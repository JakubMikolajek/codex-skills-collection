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

# Debug: {{krótki tytuł — technologia + objaw}}

## Objaw
<!-- Co było widać? Stack trace, logi, zachowanie — konkretnie -->
```
{wklej error / log}
```

## Środowisko
- Technologia:
- Wersja:
- Kontekst (prod/dev/test):

## Hipotezy (w kolejności testowania)
1. [ ] {{hipoteza-1}} → wynik:
2. [ ] {{hipoteza-2}} → wynik:

## Przyczyna źródłowa
<!-- Jedno zdanie — co DOKŁADNIE to spowodowało -->

## Fix
```typescript
// przed

// po
```

## Dlaczego tak się stało
<!-- Głębsze zrozumienie — co w architekturze / bibliotece na to pozwoliło -->

## Jak zapobiec w przyszłości
-

## Czas debugowania
<!-- np. 45 min — pomaga kalibrować przyszłe estymaty -->

## Powiązane
-
