---
name: python-ai-ml
description: Python patterns for LLM integration, RAG pipelines, embedding generation, vector database operations, and AI/data preprocessing workflows. Use when building or reviewing code that calls LLM APIs, constructs retrieval-augmented generation systems, manages embedding pipelines, queries vector stores (Qdrant, pgvector), or preprocesses code/text for AI consumption. Always load alongside the base python skill.
---

# Python AI/ML Implementation Patterns

Use this skill for LLM-integrated systems, RAG architectures, and AI-adjacent data pipelines. The bias is toward correctness of data flow, cost awareness, and reproducibility — not toward ML research patterns.

## Delivery Workflow

```
AI/ML progress:
- [ ] Step 1: Discover existing pipeline structure, models in use, and vector store schema
- [ ] Step 2: Define data shapes for chunking, embedding, and retrieval contracts
- [ ] Step 3: Implement with explicit model versioning and token budgeting
- [ ] Step 4: Add error handling for API failures, rate limits, and empty retrievals
- [ ] Step 5: Verify retrieval quality, cost controls, and pipeline observability
```

## LLM API Integration

- Pin the model name as a configuration value, never as a string literal in business logic. Model behavior changes between versions.
- Always set `max_tokens` explicitly — never accept provider defaults that can silently inflate cost.
- Use `temperature=0` for deterministic tasks (classification, extraction, code generation); use higher values only when diversity is intentional.
- Implement retry logic with exponential backoff for rate limit and transient errors — use `tenacity` or equivalent.
- Log token usage per call for cost tracking; surface as metrics in production pipelines.
- Never send raw user input directly to an LLM API in multi-tenant contexts — sanitize or scope prompt injection risks explicitly.

```python
from openai import AsyncOpenAI
from tenacity import retry, stop_after_attempt, wait_exponential

client = AsyncOpenAI()

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=2, max=10))
async def complete(
    prompt: str,
    model: str,
    max_tokens: int,
    temperature: float = 0.0,
) -> str:
    response = await client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        max_tokens=max_tokens,
        temperature=temperature,
    )
    return response.choices[0].message.content or ""
```

## Prompt Engineering

- Store prompts as versioned templates, not as inline f-strings scattered through code.
- Use a `PromptTemplate` abstraction (custom or from a library) that makes variable substitution explicit.
- Keep system prompts and user prompts structurally separate.
- Write prompts that constrain output format explicitly when downstream code parses the response.
- Test prompts against a representative sample before deploying — prompt behavior is not unit-testable with mocks alone.

```python
# Store as versioned template, not inline string
SYSTEM_PROMPT_V2 = """
You are a code documentation assistant. Given a code snippet and its AST context,
produce a concise docstring in the Google style. Return only the docstring content,
no markdown fences or preamble.
""".strip()
```

## Chunking and Document Preprocessing

- Choose chunking strategy based on the retrieval use case: semantic chunking for conceptual search, token-window chunking for context preservation, AST-aware chunking for code.
- Always store chunk metadata: source file, position (start/end offset or line range), model used to embed, chunking strategy version.
- Deduplicate chunks before embedding to avoid wasted API spend and noisy retrieval results.
- Track chunk-to-source provenance so retrieved context can be cited back to the user.
- Reindex when the chunking strategy or embedding model changes — embeddings are not portable across models.

```python
@dataclass
class DocumentChunk:
    chunk_id: str           # stable hash of source + content
    source_path: str
    content: str
    start_line: int
    end_line: int
    chunk_strategy: str     # e.g. "ast-function-v1"
    embedding_model: str    # e.g. "text-embedding-3-small"
    token_count: int
```

## Embedding Pipeline

- Generate embeddings in batches — avoid per-document API calls at scale.
- Respect provider batch size limits and rate limits when processing large corpora.
- Cache embeddings by `chunk_id` (stable content hash) to avoid re-embedding unchanged content.
- Use a consistent embedding model per index — never mix models in the same vector space.
- Normalize embeddings if the vector store or similarity metric requires it (check provider docs).

```python
async def embed_batch(
    chunks: list[DocumentChunk],
    model: str,
    batch_size: int = 100,
) -> list[list[float]]:
    embeddings = []
    for i in range(0, len(chunks), batch_size):
        batch = chunks[i : i + batch_size]
        response = await client.embeddings.create(
            input=[c.content for c in batch],
            model=model,
        )
        embeddings.extend([r.embedding for r in response.data])
    return embeddings
```

## Vector Store Patterns (Qdrant / pgvector)

- Define collections/indexes with explicit vector dimensions matched to the embedding model.
- Use `payload` / metadata fields to store chunk provenance for post-retrieval filtering.
- Apply metadata filters at query time to scope retrieval (e.g., by repo, language, or recency).
- Set `ef` (HNSW search parameter) based on recall vs. latency tradeoff testing, not defaults.
- Handle empty result sets explicitly — retrieval returning zero results is a valid state that must be surfaced.
- For Qdrant: use named vectors when storing multiple embedding models in one collection.

```python
from qdrant_client import AsyncQdrantClient
from qdrant_client.models import Filter, FieldCondition, MatchValue

async def retrieve_relevant_chunks(
    query_embedding: list[float],
    repo_filter: str,
    top_k: int = 5,
) -> list[ScoredChunk]:
    results = await qdrant.search(
        collection_name="codebase",
        query_vector=query_embedding,
        query_filter=Filter(
            must=[FieldCondition(key="repo", match=MatchValue(value=repo_filter))]
        ),
        limit=top_k,
    )
    if not results:
        return []  # Handle explicitly upstream
    return [ScoredChunk.from_qdrant(r) for r in results]
```

## RAG Pipeline Architecture

- Separate the pipeline into distinct stages: retrieve → rerank (optional) → augment → generate.
- Do not conflate retrieval logic with LLM call logic in a single function.
- Pass retrieved context to the LLM with explicit source attribution in the prompt.
- Implement a fallback when retrieval returns insufficient context — do not hallucinate missing information.
- Log which chunks were retrieved for each query to enable retrieval quality analysis.

```python
async def rag_query(
    question: str,
    query_embedding: list[float],
    repo: str,
) -> RAGResponse:
    chunks = await retrieve_relevant_chunks(query_embedding, repo_filter=repo)
    
    if not chunks:
        return RAGResponse(answer=FALLBACK_NO_CONTEXT, sources=[])
    
    context = format_context_for_prompt(chunks)
    answer = await complete(
        prompt=build_rag_prompt(question, context),
        model=settings.chat_model,
        max_tokens=1024,
    )
    return RAGResponse(answer=answer, sources=[c.source_path for c in chunks])
```

## AST-Aware Code Processing

- Use `tree-sitter` for language-agnostic AST parsing — it supports Python, TypeScript, Rust, Swift, and more.
- Extract function/class boundaries from AST for semantically coherent code chunks.
- Preserve import context when chunking — a function without its imports is often unembeddable meaningfully.
- Store the AST node type (function, class, method) in chunk metadata for retrieval filtering.

## Observability and Cost Control

- Track total token usage per pipeline run and surface as a log field or metric.
- Set hard limits on total token spend per user request in production.
- Use structured logging with `pipeline_id`, `model`, `input_tokens`, `output_tokens` on every LLM call.
- Instrument retrieval quality: log top-k scores and chunk IDs to enable offline quality analysis.

## AI/ML Review Checklist

```
Data flow:
- [ ] Chunking strategy is explicit and versioned
- [ ] Embeddings are cached by content hash
- [ ] Embedding model is consistent within a single index

LLM calls:
- [ ] Model pinned in config, not hardcoded
- [ ] max_tokens set explicitly
- [ ] Retry logic handles rate limits and transient failures
- [ ] Token usage is logged

RAG pipeline:
- [ ] Retrieve, augment, and generate are separate stages
- [ ] Empty retrieval handled explicitly (no silent hallucination)
- [ ] Retrieved sources attributed in response

Quality:
- [ ] Prompts stored as versioned templates
- [ ] Pipeline stages are individually testable
- [ ] Cost controls in place for production
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Hardcoded model name in business logic | Pin model in `Settings` |
| No `max_tokens` — let provider decide | Always set `max_tokens` |
| Single-item embedding calls in a loop | Batch embed with backoff |
| Mixing embedding models in one vector index | Reindex when model changes |
| Silent fallback when retrieval returns empty | Explicit fallback response |
| Prompts as inline f-strings | Versioned prompt templates |
| No token usage logging | Log per-call token counts |
| Re-embedding unchanged content | Cache by `chunk_id` hash |

## Connected Skills

- `python` — always load for core Python patterns and typing discipline
- `python-fastapi` — load when the AI pipeline is exposed via an HTTP API
- `python-testing` — load for testing pipeline stages with fixtures and mocks
- `sql-and-database` — load when pipeline state is persisted to PostgreSQL / pgvector
- `technical-context-discovery` — discover existing pipeline conventions before editing
