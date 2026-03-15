---
name: python-testing
description: Python testing patterns using pytest — fixtures, mocking, async tests, integration tests with databases and HTTP clients, and CI-ready test organization. Use when writing, reviewing, or debugging Python tests at any level (unit, integration, contract). Always load alongside the base python skill.
---

# Python Testing Patterns

Use this skill for writing tests that are deterministic, fast, and maintainable. The bias is toward testing behavior, not implementation — tests should survive refactoring.

## Delivery Workflow

```
Python Testing progress:
- [ ] Step 1: Discover existing test structure, fixtures, and conventions
- [ ] Step 2: Identify what to test — behavior, not internals
- [ ] Step 3: Write fixtures for shared setup and teardown
- [ ] Step 4: Implement tests with clear arrange/act/assert structure
- [ ] Step 5: Verify coverage of happy path, error cases, and edge cases
```

## Test Organization

- Mirror the source package structure: `src/app/services/doc.py` → `tests/services/test_doc.py`.
- Use `conftest.py` for shared fixtures scoped to the directory they serve.
- Keep test files focused on one module or class.
- Name tests after the behavior they verify: `test_create_document_returns_201` not `test_route`.
- Group related tests in a class only when they share fixture setup; otherwise use top-level functions.

## Fixtures

- Prefer function-scoped fixtures (the default) unless shared setup is genuinely expensive.
- Use `session`-scoped fixtures for external connections (DB, Docker containers) to avoid repeated startup cost.
- Use `yield` fixtures for resources requiring teardown.
- Use `pytest-factoryboy` or manual factory functions for domain object creation — avoid duplicating object construction in every test.

```python
import pytest
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine

@pytest.fixture(scope="session")
def engine():
    return create_async_engine("postgresql+asyncpg://test:test@localhost/testdb")

@pytest.fixture
async def db(engine) -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSession(engine) as session:
        yield session
        await session.rollback()
```

## Async Tests

- Use `pytest-asyncio` with `asyncio_mode = "auto"` in `pytest.ini` or `pyproject.toml` to avoid per-test `@pytest.mark.asyncio` decoration.
- Do not mix sync and async fixtures carelessly — use `anyio` backend fixtures when both are needed.
- Never use `asyncio.run()` inside test functions — let pytest-asyncio handle the event loop.

```toml
# pyproject.toml
[tool.pytest.ini_options]
asyncio_mode = "auto"
```

## Mocking and Patching

- Use `pytest-mock` (`mocker` fixture) over `unittest.mock` directly for cleaner fixture integration.
- Patch at the point of use, not at the definition: patch `app.services.doc.openai_client` not `openai.AsyncOpenAI`.
- Use `AsyncMock` for patching async callables.
- Prefer dependency injection over patching when possible — code designed for DI is easier to test without patching.
- Do not assert on mock call counts unless the call count is the explicit behavior under test.

```python
async def test_create_document_calls_embedding_service(
    mocker: MockerFixture,
    db: AsyncSession,
) -> None:
    mock_embed = mocker.patch(
        "app.services.doc.embedding_service.embed",
        new_callable=AsyncMock,
        return_value=[0.1] * 1536,
    )
    
    service = DocumentService(db=db)
    await service.create(CreateDocumentRequest(title="Test", content="Hello"))
    
    mock_embed.assert_called_once()
```

## FastAPI Integration Tests

- Use `httpx.AsyncClient` with `ASGITransport` for async integration tests — not `TestClient` (sync).
- Test the full request/response cycle including request validation and error handler behavior.
- Override dependencies with `app.dependency_overrides` for test-specific implementations.
- Use a real test database for integration tests, not mocked sessions.

```python
import pytest
import httpx
from fastapi.testclient import TestClient

@pytest.fixture
async def client(app: FastAPI) -> AsyncGenerator[httpx.AsyncClient, None]:
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app),
        base_url="http://test",
    ) as c:
        yield c

async def test_create_document_returns_201(client: httpx.AsyncClient) -> None:
    response = await client.post("/documents/", json={"title": "T", "content": "C"})
    assert response.status_code == 201
    assert response.json()["title"] == "T"
```

## Testing LLM / AI Pipeline Code

- Do not make real LLM API calls in tests — mock the client at the service boundary.
- Use fixture-based test data for embeddings (pre-generated fixed vectors) instead of computing them.
- Test pipeline stages independently: retrieval, augmentation, and generation as separate units.
- Use `pytest-recording` or `vcrpy` for snapshot testing of LLM responses when the prompt is stable.
- Test error paths explicitly: rate limit response, empty retrieval, malformed LLM output.

```python
@pytest.fixture
def mock_qdrant(mocker: MockerFixture) -> AsyncMock:
    return mocker.patch(
        "app.pipelines.rag.qdrant_client.search",
        new_callable=AsyncMock,
        return_value=[],  # Test empty retrieval case
    )

async def test_rag_returns_fallback_on_empty_retrieval(
    mock_qdrant: AsyncMock,
) -> None:
    result = await rag_query("What does this do?", query_embedding=[0.0] * 1536, repo="test")
    assert result.answer == FALLBACK_NO_CONTEXT
    assert result.sources == []
```

## Coverage and CI

- Target 80%+ line coverage as a floor, not a ceiling — coverage is a smell detector, not a quality metric.
- Configure `pytest-cov` in CI: `pytest --cov=app --cov-report=term-missing --cov-fail-under=80`.
- Exclude `__init__.py`, migration files, and config from coverage reporting.
- Mark slow integration tests with `@pytest.mark.integration` and skip them in fast CI runs.
- Never write tests whose only purpose is to hit coverage numbers — write tests that document behavior.

```toml
# pyproject.toml
[tool.coverage.run]
omit = ["*/migrations/*", "*/config.py", "*/__init__.py"]

[tool.pytest.ini_options]
markers = ["integration: marks tests as requiring external services"]
```

## Python Testing Review Checklist

```
Structure:
- [ ] Test file mirrors source module structure
- [ ] Fixtures have appropriate scope
- [ ] No test-only logic mixed into production code

Behavior:
- [ ] Happy path covered
- [ ] Error paths covered (invalid input, external failure, empty results)
- [ ] Edge cases identified and tested

Quality:
- [ ] No real external API calls in unit/integration tests
- [ ] Async tests use pytest-asyncio correctly
- [ ] Mocks patch at point of use, not at definition
- [ ] Tests pass in isolation (no implicit ordering dependency)
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Real LLM/embedding API calls in tests | Mock at the client boundary |
| Patching at import definition site | Patch at the point of use in target module |
| Shared mutable state between tests | Use function-scoped fixtures |
| Testing implementation details | Test observable behavior |
| `asyncio.run()` inside test functions | Use pytest-asyncio with auto mode |
| Coverage-padding tests with no assertions | Write tests that document a real behavior |
| Hardcoded test data inline in every test | Factory fixtures for domain objects |

## Connected Skills

- `python` — always load for core Python patterns
- `python-fastapi` — load when testing FastAPI routes and middleware
- `python-ai-ml` — load when testing LLM and RAG pipeline stages
- `technical-context-discovery` — follow existing test conventions before adding new test infrastructure
