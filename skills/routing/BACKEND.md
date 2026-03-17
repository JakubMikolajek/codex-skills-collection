# BACKEND Branch

## When to enter this branch
- Task involves server-side logic, APIs, services, or backend modules
- Task targets a backend framework or language: NestJS, Kotlin, Rust, Python, FastAPI
- Task involves controllers, services, DTOs, guards, interceptors (NestJS)
- Task involves domain modeling, coroutines, null-safety (Kotlin)
- Task involves ownership, async workflows, Tauri commands, system-level logic (Rust)
- Task involves Python backend services, async APIs, LLM pipelines, RAG, or data processing
- Task involves WebSocket or SSE server implementation
- Task involves RabbitMQ producers, consumers, or queue topology
- Files being edited are `.ts` (NestJS), `.kt`, `.rs`, `.py`, or backend module files

## When NOT to enter this branch
- Task is about frontend UI, components, or styling — use FRONTEND
- Task is about Dockerfiles or Kubernetes manifests — use INFRA
- Task is about database schemas or SQL — use DATA (but often combined with BACKEND)
- Task is about code review, architecture, or testing without a specific backend scope — use WORKFLOW
- Task is about React, Vue, or SwiftUI code — use FRONTEND even if it involves TypeScript

## Decision tree

| If the task involves... | Read next |
|---|---|
| NestJS, Node.js API, TypeScript backend services, modules, controllers | skills/nestjs/SKILL.md |
| Kotlin, Android business logic, JVM services, coroutines | skills/kotlin/SKILL.md |
| Rust, Tauri, systems programming, ownership, desktop backend services | skills/rust/SKILL.md |
| Python core patterns, typing, async, config, shared library logic | skills/python/SKILL.md |
| Python + FastAPI: routes, DI, middleware, HTTP API | skills/python/SKILL.md + skills/python-fastapi/SKILL.md |
| Python + LLM/RAG/embeddings/vector stores/AI pipelines | skills/python/SKILL.md + skills/python-ai-ml/SKILL.md |
| WebSocket server, SSE streaming, real-time connections, presence | skills/websocket-realtime/SKILL.md |
| RabbitMQ, AMQP, message queue topology, consumers, dead-letter | skills/message-queue/SKILL.md |
| Unclear / cross-cutting backend task | skills/nestjs/SKILL.md (most common backend stack) |

## Combination rules
- When a backend task involves database work, also load `sql-and-database` from DATA
- `technical-context-discovery` always loaded before implementing backend features
- `code-review` + `security-hardening` loaded when reviewing backend code
- Backend language skills are mutually exclusive — do not load `nestjs` and `python-fastapi` for the same service
- Python sub-skills (`python-fastapi`, `python-ai-ml`, `python-testing`) always load alongside base `python`
- `websocket-realtime` + `message-queue` when combining real-time delivery with durable async processing
- `message-queue` + `python` for thesis RabbitMQ pipeline (aio_pika)
- When containerizing a backend service, load `docker` from INFRA
- `observability` loaded when adding logging, metrics, or health probes to a backend service
- `error-handling` loaded when designing error propagation, retry, or circuit-breaker for a backend service
