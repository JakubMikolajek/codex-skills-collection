---
name: python
description: Python implementation and review patterns for idiomatic, typed, and maintainable Python code. Use when Codex needs to build, refactor, debug, or review Python modules, async code, type-annotated APIs, CLI tools, or shared library logic. For FastAPI/backend services use python-fastapi. For ML/AI pipelines, RAG systems, or data processing use python-ai-ml. For test writing use python-testing.
---

# Python Implementation Patterns

Use this skill for idiomatic, modern Python (3.11+) with a bias toward correctness, explicit typing, and maintainability. This skill covers core language patterns; sub-skills handle domain-specific concerns.

## Delivery Workflow

Use the checklist below and track progress:

```
Python progress:
- [ ] Step 1: Discover project conventions, Python version, and dependency management
- [ ] Step 2: Model data shapes and error types explicitly
- [ ] Step 3: Implement with proper typing and async discipline
- [ ] Step 4: Handle errors, logging, and side effects explicitly
- [ ] Step 5: Verify with tests, type checking, and linting
```

## Platform Assumptions

- Target Python 3.11+ by default.
- Use `uv` for dependency and environment management when available; fall back to `poetry` if the project already uses it.
- Do not add compatibility shims for Python 3.9 or earlier unless the project explicitly requires it.
- Prefer standard library solutions before reaching for third-party packages.

## Typing and Data Modeling

- Annotate all function signatures — parameters and return types.
- Use `Pydantic v2` for data validation and serialization at system boundaries (API input, config, external data).
- Use dataclasses for internal data carriers that do not need validation logic.
- Use `TypedDict` for typed dict shapes that are not instantiated as classes.
- Use `Protocol` for structural typing instead of ABC when duck typing is the right model.
- Avoid `Any` except at explicit untyped boundaries; document why when used.
- Use `NewType` or domain-specific aliases to prevent primitive obsession in critical paths.

```python
# Prefer explicit types at boundaries
from pydantic import BaseModel

class DocumentChunk(BaseModel):
    chunk_id: str
    content: str
    embedding_model: str
    token_count: int

# Not this
def process(data: dict) -> dict: ...
```

## Async and Concurrency

- Use `asyncio` for I/O-bound work; use `concurrent.futures.ProcessPoolExecutor` for CPU-bound work.
- Never call blocking I/O inside an async function — use `asyncio.to_thread` or a thread executor.
- Keep async context managers explicit for resources that require teardown.
- Prefer structured concurrency with `asyncio.TaskGroup` (Python 3.11+) over bare `asyncio.gather` when error propagation matters.
- Do not use `asyncio.create_task` fire-and-forget without a way to observe failure.

```python
# Prefer TaskGroup for structured concurrency
async def process_batch(items: list[Item]) -> list[Result]:
    async with asyncio.TaskGroup() as tg:
        tasks = [tg.create_task(process_item(item)) for item in items]
    return [t.result() for t in tasks]
```

## Error Handling

- Define domain error hierarchies explicitly using custom exception classes.
- Catch narrow exceptions; avoid bare `except Exception` in library code.
- Use `contextlib.suppress` only for genuinely ignorable errors, not to silence unexpected ones.
- Surface errors at the right abstraction layer — do not let infrastructure exceptions leak into domain code.
- Use `logging` with structured fields; never use `print` for observability in production code.

```python
class DocumentProcessingError(Exception):
    """Base class for document processing failures."""

class ChunkingError(DocumentProcessingError):
    def __init__(self, source: str, reason: str) -> None:
        super().__init__(f"Chunking failed for '{source}': {reason}")
        self.source = source
        self.reason = reason
```

## Module and Package Hygiene

- Keep modules focused on a single cohesive responsibility.
- Use `__init__.py` to define a clean public API; do not re-export everything.
- Keep circular imports impossible by design — organize in layers (models → services → routes).
- Use absolute imports everywhere; avoid relative imports except in tightly coupled subpackages.
- Pin transitive dependencies in `uv.lock` or `poetry.lock`; do not commit unpinned lockfiles.

## Configuration and Environment

- Use `pydantic-settings` (`BaseSettings`) for application configuration loaded from environment variables.
- Never hardcode secrets, ports, or environment-specific values in source code.
- Validate configuration at startup; fail fast with a clear error if required variables are missing.

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    qdrant_host: str = "localhost"
    qdrant_port: int = 6333
    embedding_model: str = "text-embedding-3-small"

    model_config = {"env_file": ".env"}
```

## Code Quality Rules

- Format with `ruff format`; lint with `ruff check`.
- Type-check with `mypy --strict` or `pyright` — whichever the project uses.
- Never commit with `# type: ignore` without a comment explaining the suppression.
- Keep functions under 40 lines; extract helpers with intention-revealing names.
- Prefer `pathlib.Path` over `os.path` for filesystem operations.

## Python Review Checklist

```
Correctness:
- [ ] All public functions are fully type-annotated
- [ ] Async/blocking boundary is respected
- [ ] Error types are explicit and meaningful

Architecture:
- [ ] Module has a single cohesive responsibility
- [ ] No circular imports
- [ ] Configuration loaded via BaseSettings

Quality:
- [ ] ruff format + ruff check pass
- [ ] mypy/pyright passes without suppressed errors
- [ ] Tests cover critical paths and error cases
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| `except Exception: pass` | Catch narrow exceptions; log or re-raise |
| `dict` as a data carrier across boundaries | Use Pydantic model or TypedDict |
| Blocking I/O inside `async def` | Use `asyncio.to_thread` or async client |
| `os.environ["KEY"]` sprinkled throughout | Centralize in `BaseSettings` |
| `print()` for observability | Use `logging` with structured context |
| Star imports (`from module import *`) | Explicit imports only |
| Mutable default arguments | Use `None` sentinel and create inside function |

## Sub-Skills

Load the appropriate sub-skill for domain-specific work:

| If the task involves... | Load next |
|---|---|
| FastAPI routes, dependency injection, middleware, HTTP APIs | `python-fastapi` |
| LLM pipelines, RAG, embeddings, vector databases, ML preprocessing | `python-ai-ml` |
| pytest, fixtures, mocking, test coverage, CI test patterns | `python-testing` |

## Connected Skills

- `python-fastapi` — use for FastAPI-specific API implementation patterns
- `python-ai-ml` — use for LLM, RAG, embedding, and data pipeline work
- `python-testing` — use when writing or reviewing Python tests
- `sql-and-database` — use when the task involves database queries or migrations
- `docker` — use when containerizing Python services
- `technical-context-discovery` — follow project Python conventions before editing
- `code-review` — validate correctness and idioms
