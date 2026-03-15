# BACKEND Branch

## When to enter this branch
- Task involves server-side logic, APIs, services, or backend modules
- Task targets a backend framework or language: NestJS, Kotlin, Rust, Python, FastAPI
- Task involves controllers, services, DTOs, guards, interceptors (NestJS)
- Task involves domain modeling, coroutines, null-safety (Kotlin)
- Task involves ownership, async workflows, Tauri commands, system-level logic (Rust)
- Task involves Python backend services, async APIs, LLM pipelines, RAG systems, or data processing
- Files being edited are `.ts` (NestJS service/controller), `.kt`, `.rs`, `.py`, or backend module files

## When NOT to enter this branch
- Task is about frontend UI, components, or styling — use FRONTEND
- Task is about Dockerfiles or deployment — use INFRA
- Task is about database schemas or SQL queries — use DATA (but often combined with a backend skill)
- Task is about code review, architecture, or testing patterns without a specific backend scope — use WORKFLOW
- Task is about React, Vue, or SwiftUI code — use FRONTEND even if it involves TypeScript

## Decision tree

For tasks matching this branch, read the next level:

| If the task involves... | Read next |
|-------------------------|-----------| 
| NestJS, Node.js API, TypeScript backend services, modules, controllers | skills/nestjs/SKILL.md |
| Kotlin, Android business logic, JVM services, coroutines | skills/kotlin/SKILL.md |
| Rust, Tauri, systems programming, ownership, desktop backend services | skills/rust/SKILL.md |
| Python core patterns, typing, async, config, shared library logic | skills/python/SKILL.md |
| Python + FastAPI: routes, DI, middleware, HTTP API | skills/python/SKILL.md + skills/python-fastapi/SKILL.md |
| Python + LLM/RAG/embeddings/vector stores/AI pipelines | skills/python/SKILL.md + skills/python-ai-ml/SKILL.md |
| Unclear / cross-cutting backend task | skills/nestjs/SKILL.md (most common backend stack) |

## Combination rules
- When a backend task involves database work, always also read `skills/routing/DATA.md` to load `sql-and-database`
- `technical-context-discovery` should always be loaded before implementing backend features — read it from WORKFLOW branch
- `code-review` should be loaded when the task includes review of backend code — read it from WORKFLOW branch
- Backend skills are mutually exclusive across ecosystems — do not load `nestjs` and `python-fastapi` for the same service
- When containerizing a backend service, also read `skills/routing/INFRA.md` to load `docker`
- Python sub-skills (`python-fastapi`, `python-ai-ml`, `python-testing`) always load alongside the base `python` skill — never alone
- When the Python task involves testing, also load `python-testing` from this branch
- `python-ai-ml` + `sql-and-database` when the AI pipeline uses pgvector
