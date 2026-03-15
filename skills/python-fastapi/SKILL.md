---
name: python-fastapi
description: FastAPI implementation and review patterns for building typed, async HTTP APIs with dependency injection, middleware, and structured error handling. Use when building or reviewing FastAPI routes, dependencies, request/response models, background tasks, or OpenAPI documentation. Always load alongside the base python skill.
---

# FastAPI Implementation Patterns

Use this skill for idiomatic FastAPI development. FastAPI's design rewards explicit typing, proper dependency injection, and clean separation of routing from business logic.

## Delivery Workflow

```
FastAPI progress:
- [ ] Step 1: Discover project router structure, middleware, and DI conventions
- [ ] Step 2: Define request/response models and route contracts
- [ ] Step 3: Implement route handlers — thin, delegating to services
- [ ] Step 4: Wire dependencies, auth, and middleware correctly
- [ ] Step 5: Verify OpenAPI docs, error responses, and integration tests
```

## Route Design

- Keep route handlers thin: parse input, call a service, return a response. No business logic in handlers.
- Use `APIRouter` to group routes by domain; mount routers in `main.py` with a clear prefix.
- Define explicit response models with `response_model=` on every route — never return raw dicts.
- Use `status_code=` explicitly; do not accept FastAPI's implicit 200 for non-GET routes.
- Annotate path and query parameters with types and `Field(...)` for validation and documentation.

```python
from fastapi import APIRouter, status
from app.schemas.document import DocumentResponse, CreateDocumentRequest
from app.services.document_service import DocumentService

router = APIRouter(prefix="/documents", tags=["documents"])

@router.post(
    "/",
    response_model=DocumentResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_document(
    payload: CreateDocumentRequest,
    service: DocumentService = Depends(get_document_service),
) -> DocumentResponse:
    return await service.create(payload)
```

## Request and Response Models

- Use Pydantic v2 `BaseModel` for all request and response schemas.
- Keep request models (input validation) separate from response models (output shaping) and domain models (business logic).
- Use `model_config = {"from_attributes": True}` on response models that map from ORM objects.
- Use `Field(...)` for documentation, validation constraints, and aliases.
- Never expose internal domain model fields in response schemas — map explicitly.

```python
class CreateDocumentRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    content: str = Field(..., min_length=1)
    tags: list[str] = Field(default_factory=list)

class DocumentResponse(BaseModel):
    id: str
    title: str
    created_at: datetime
    model_config = {"from_attributes": True}
```

## Dependency Injection

- Use `Depends()` for all shared dependencies: database sessions, service instances, auth, config.
- Keep dependency functions short and single-purpose.
- Use generator dependencies (`yield`) for resources that need teardown (DB sessions, HTTP clients).
- Scope heavy dependencies to the request lifecycle, not application lifecycle, unless they are truly stateless and thread-safe.
- Use `Annotated` for reusable dependency aliases to avoid repetitive `Depends()` inline.

```python
from typing import Annotated
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_factory() as session:
        yield session

DB = Annotated[AsyncSession, Depends(get_db)]

# Usage in routes
async def get_document(doc_id: str, db: DB) -> DocumentResponse:
    ...
```

## Error Handling

- Define application-level exception classes inheriting from a base `AppError`.
- Register exception handlers with `@app.exception_handler` to map domain errors to HTTP responses.
- Return structured error responses with a consistent shape across all endpoints.
- Never let unhandled exceptions reach the client in production — register a catch-all handler with a generic 500 response and logging.

```python
class AppError(Exception):
    def __init__(self, message: str, status_code: int = 400) -> None:
        self.message = message
        self.status_code = status_code

class DocumentNotFoundError(AppError):
    def __init__(self, doc_id: str) -> None:
        super().__init__(f"Document '{doc_id}' not found", status_code=404)

@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": exc.message},
    )
```

## Authentication and Authorization

- Implement auth as a FastAPI dependency — inject the current user via `Depends(get_current_user)`.
- Use `Annotated` to create `CurrentUser` type alias for cleaner route signatures.
- Keep auth logic in a dedicated `auth/` module, not inline in route files.
- Validate JWT claims (expiry, issuer, audience) explicitly — do not trust unsigned or unverified tokens.

## Background Tasks

- Use `BackgroundTasks` for fire-and-forget work that should not block the response.
- For durable, retryable, or observable background work, use a proper task queue (Celery, ARQ, RQ, or RabbitMQ/AMQP).
- Never use `asyncio.create_task` in route handlers without proper lifecycle management.
- Document which operations are synchronous vs. deferred in the OpenAPI description.

## Middleware and Lifecycle

- Register middleware for cross-cutting concerns: CORS, request ID injection, timing headers, structured logging.
- Use `@app.on_event("startup")` / `lifespan` context manager for initializing DB pools, HTTP clients, and caches.
- Use `lifespan` (the modern approach) over deprecated `on_event` for startup/shutdown logic.

```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await db_pool.connect()
    yield
    # Shutdown
    await db_pool.disconnect()

app = FastAPI(lifespan=lifespan)
```

## FastAPI Review Checklist

```
Routes:
- [ ] Handlers are thin — no business logic inline
- [ ] response_model and status_code set on every route
- [ ] Request/response models are separate from domain models

Dependencies:
- [ ] DB sessions use generator Depends with yield
- [ ] Auth implemented as a dependency, not middleware intercepting manually
- [ ] Heavy resources scoped correctly

Error handling:
- [ ] Domain errors mapped to HTTP via exception handlers
- [ ] No unhandled exceptions reaching the client
- [ ] Error responses have consistent structure

Quality:
- [ ] OpenAPI docs generated correctly (check /docs)
- [ ] Integration tests cover happy path and error cases
- [ ] Typing passes mypy/pyright
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Business logic in route handlers | Delegate to service layer |
| Returning raw `dict` instead of response model | Always use `response_model=` |
| DB session as global variable | Use generator `Depends` with `yield` |
| `try/except` inside every handler | Use registered exception handlers |
| Auth logic repeated per-route | Auth as a shared `Depends` |
| `on_event` for startup/shutdown | Use `lifespan` context manager |

## Connected Skills

- `python` — always load for core Python patterns and typing discipline
- `python-testing` — load for writing FastAPI integration tests with `TestClient` or `httpx`
- `sql-and-database` — load when the API persists to a database
- `technical-context-discovery` — follow existing API and DI conventions before editing
