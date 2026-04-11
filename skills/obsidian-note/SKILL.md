# SKILL: obsidian-note

## Kiedy używać tego skilla

Użyj tego skilla **zawsze** gdy:
- Kończysz sesję pracy nad projektem → twórz `session note`
- Podejmujesz decyzję architektoniczną → twórz `ADR`
- Naprawiasz nietrywialny bug → twórz `debug trace`
- Uczysz się nowego wzorca/technologii → twórz `knowledge note` w `03-skills/domains/`
- Zaczynasz nowy projekt → twórz `project index`

**Nie twórz notatki** dla: trywialnych zmian, formatowania kodu, rutynowych CRUD.

---

## Ścieżki vault

```
VAULT_ROOT/
├── 00-inbox/          # szkice, nieskategoryzowane — czyść co tydzień
├── 01-projects/
│   └── {project-slug}/
│       ├── _index.md          # hub projektu (twórz raz, aktualizuj)
│       └── sessions/
│           └── YYYY-MM-DD.md  # sesja dzienna
├── 02-adr/
│   └── ADR-{NNNN}-{slug}.md   # NNNN = 4-cyfrowy numer, auto-inkrementuj
├── 03-skills/
│   ├── domains/
│   │   └── {technology}.md    # np. rust.md, nestjs.md, swiftui.md
│   └── MOC.md                 # map of content — aktualizuj po każdym nowym skilu
└── 04-debug/
    └── {YYYY-MM-DD}-{slug}.md
```

**VAULT_ROOT** = ~/Desktop/Obsidian/Codex/

---

## Zasady wikilinków [[...]]

### Linkuj zawsze:
- Każda notatka linkuje do **project index**: `[[01-projects/{slug}/_index]]`
- ADR linkuje do powiązanych skillów: `[[03-skills/domains/rust]]`
- Session note linkuje do ADR z tej sesji: `[[ADR-0012-grpc-transport]]`
- Debug trace linkuje do projektu + technologii: `[[FSS-IoT/_index]]` `[[03-skills/domains/redis]]`
- Knowledge note w domains/ linkuje do projektów gdzie technologia jest używana

### Canonical nazwy projektów (używaj dokładnie tych slugów):
- `CodePath` → `01-projects/codepath/_index`
- `FSS-IoT` → `01-projects/fss-iot/_index`
- `NuvLock` → `01-projects/nuvlock/_index`
- `codex-skills` → `01-projects/codex-skills/_index`
- `thesis` → `01-projects/thesis/_index`

### Tagi (#tag) — używaj spójnie:
```
Technologie:  #rust #nestjs #swift #react #python #mqtt #ble #grpc #redis
Typ notatki:  #adr #session #debug #knowledge #project-index
Domena:       #backend #ios #tvos #frontend #iot #ai #infra
Status ADR:   #adr/accepted #adr/proposed #adr/superseded
```

---

## Frontmatter — obowiązkowy

Każda notatka MUSI mieć frontmatter:

```yaml
---
date: YYYY-MM-DD
type: session | adr | debug | knowledge | project-index
project: {canonical-slug}   # pomiń dla knowledge notes
tags: [tag1, tag2]
links:                       # explicit backlinks (uzupełnienie [[wikilinków]])
  - "[[powiązana-notatka]]"
---
```

---

## Szablony — invoke

Wywołaj odpowiedni szablon z `_templates/`:

| Typ | Szablon | Kiedy |
|-----|---------|-------|
| Sesja | `_templates/session.md` | Po każdej sesji roboczej |
| ADR | `_templates/adr.md` | Decyzja arch. z uzasadnieniem |
| Debug | `_templates/debug.md` | Bug wymagał >15min debugowania |
| Knowledge | `_templates/knowledge.md` | Nowy wzorzec / technologia |
| Project index | `_templates/project-index.md` | Nowy projekt |

---

## Algorytm tworzenia notatki

```
1. Określ typ notatki
2. Ustal ścieżkę docelową (patrz: Ścieżki vault)
3. Skopiuj odpowiedni szablon
4. Wypełnij frontmatter (date, type, project, tags)
5. Wypełnij sekcje szablonu — bądź konkretny, nie ogólny
6. Dodaj [[wikilinki]] do:
   - project index projektu
   - powiązanych ADR
   - powiązanych technologii w 03-skills/domains/
   - poprzedniej sesji tego projektu (jeśli istnieje)
7. Zaktualizuj MOC.md jeśli to nowa domena wiedzy
8. Zaktualizuj _index.md projektu (dodaj link do nowej notatki)
9. Zapisz plik pod właściwą ścieżką w vault
```

---

## Jakość notatek — zasady

- **Konkretność ponad ogólność**: zamiast "naprawiono bug MQTT" → "Redis SET NX race condition przy >1 instancji NestJS — fix: prefix klucza o `{instanceId}:`"
- **Decyzje z kontekstem**: ADR zawiera `## Dlaczego NIE {alternatywa}` — to jest najcenniejsza część
- **Linki jako nawigacja**: graf Obsidiana to wartość — im więcej sensownych linków, tym lepszy graph view
- **Aktualizuj, nie duplikuj**: jeśli notatka projektu istnieje, zaktualizuj `_index.md`, nie twórz nowej

---

## Przykład minimalny — sesja

Plik: `01-projects/codepath/sessions/2025-01-15.md`

```markdown
---
date: 2025-01-15
type: session
project: CodePath
tags: [session, rust, lsp]
links:
  - "[[01-projects/codepath/_index]]"
  - "[[03-skills/domains/rust]]"
---

# CodePath — sesja 2025-01-15

## Co zrobiono
- Zaimplementowano PSI node visitor dla Rust LSP
- Naprawiono lifetime issue w `SemanticRuntime::resolve()`

## Decyzje
- Wybrano `Arc<RwLock<T>>` zamiast `Mutex` dla read-heavy cache → patrz [[ADR-0015-lsp-concurrency]]

## Blokery
- `tonic` streaming nie obsługuje graceful shutdown natywnie — do zbadania

## Następna sesja
- [ ] Graceful shutdown w tonic
- [ ] Testy integracyjne dla visitor pattern
```
