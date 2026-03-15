---
name: error-handling
description: Cross-cutting error handling patterns for production backend systems. Covers error boundary design, retry strategies, circuit breakers, graceful degradation, and error observability. Use when designing error handling for new services, reviewing error propagation across system boundaries, or hardening a service against external failures.
---

# Error Handling

This skill covers the architecture of error handling — not just try/catch placement, but how errors are designed, propagated, recovered from, and observed across a system.

## When to Use

- Designing a new service that calls external APIs, databases, or message queues
- Reviewing code where error handling is implicit, missing, or inconsistent
- A service is experiencing cascading failures when a dependency goes down
- Adding retry logic to a flaky integration
- Designing the error response contract for an API

## When NOT to Use

- Language-specific error handling syntax reference — see the relevant language skill (`python`, `nestjs`, `rust`)
- Frontend error boundaries — partially covered in `react` and `vue` skills
- Database-specific error handling — see `sql-and-database`

## Core Principles

### Errors are First-Class Domain Objects

An error is not an exception to be caught and discarded — it is information about what went wrong, at what level, and whether the caller can recover. Design error types with the same intentionality as domain models.

### Fail Fast, Recover Intentionally

Fail immediately when a precondition is violated. Recover only from errors where you know how to recover correctly. Unknown recovery is worse than explicit failure — it produces systems that appear to work while silently degrading.

### Error Propagation Has a Direction

Infrastructure errors (database down, network timeout) should not surface as-is to API consumers. Map errors at boundaries: infrastructure errors → service errors → API errors. Each layer translates, not just forwards.

## Error Taxonomy

Classify every error before handling it:

| Class | Description | Default Action |
|---|---|---|
| **Transient** | Temporary condition that may resolve on retry: network blip, rate limit, brief DB overload | Retry with backoff |
| **Permanent** | Will not resolve on retry: invalid input, resource not found, auth failure | Fail immediately, surface to caller |
| **Dependency** | A downstream service is unavailable or degraded | Circuit break, degrade gracefully |
| **Programming** | Bug in the code: null pointer, assertion failure, type error | Log with full context, fail loudly |
| **Resource** | Exhaustion: disk full, connection pool saturated, memory OOM | Alert immediately, do not retry silently |

## Error Handling Process

```
Error handling progress:
- [ ] Step 1: Define error hierarchy for the service
- [ ] Step 2: Map error propagation across boundaries
- [ ] Step 3: Implement retry strategy for transient errors
- [ ] Step 4: Implement circuit breaker for dependency errors
- [ ] Step 5: Define graceful degradation paths
- [ ] Step 6: Ensure error observability
```

**Step 1: Define error hierarchy for the service**

Create a domain error hierarchy. Do not use generic `Error` subclasses or string error codes for cross-boundary errors.

```typescript
// TypeScript example
export abstract class AppError extends Error {
  abstract readonly statusCode: number;
  abstract readonly code: string;
  readonly isOperational: boolean = true; // operational = expected, non-operational = bug
}

export class NotFoundError extends AppError {
  readonly statusCode = 404;
  readonly code = 'NOT_FOUND';
  constructor(resource: string, id: string) {
    super(`${resource} '${id}' not found`);
  }
}

export class ValidationError extends AppError {
  readonly statusCode = 422;
  readonly code = 'VALIDATION_ERROR';
  constructor(
    readonly fields: Array<{ field: string; message: string }>,
  ) {
    super('Request validation failed');
  }
}

export class DependencyError extends AppError {
  readonly statusCode = 503;
  readonly code = 'DEPENDENCY_UNAVAILABLE';
  readonly isOperational = false; // triggers alert
}
```

Rules:
- `isOperational: true` — expected failure, log as warning, return to client
- `isOperational: false` — unexpected failure or infrastructure error, log as error/critical, alert
- Never catch and re-throw without adding context
- Never catch `Error` base class and discard it silently

**Step 2: Map error propagation across boundaries**

At every I/O boundary (HTTP call, DB query, message publish), translate infrastructure errors into domain errors:

```typescript
async function getDocument(id: string): Promise<Document> {
  try {
    const row = await db.query('SELECT * FROM documents WHERE id = $1', [id]);
    if (!row) throw new NotFoundError('Document', id);
    return mapRowToDocument(row);
  } catch (err) {
    if (err instanceof NotFoundError) throw err; // already domain error
    if (isConnectionError(err)) throw new DependencyError('Database unavailable');
    // Unknown error — preserve stack, rethrow as-is for global handler
    throw err;
  }
}
```

Boundary translation rules:
- Catch specific infrastructure error types, not generic `Error`
- Re-throw known domain errors unchanged
- Translate known infrastructure errors to appropriate domain errors
- Let unknown errors bubble up for the global handler to log and alert on

**Step 3: Implement retry strategy for transient errors**

Retry policy components:
- **Max attempts**: 3 for most cases; 5 for critical paths
- **Backoff**: exponential with jitter — not fixed delay (avoids thundering herd)
- **Retryable conditions**: explicitly listed, not "retry everything"
- **Timeout per attempt**: set per attempt, not just total

```typescript
async function withRetry<T>(
  fn: () => Promise<T>,
  options: {
    maxAttempts: number;
    baseDelayMs: number;
    retryOn: (err: unknown) => boolean;
  },
): Promise<T> {
  let lastError: unknown;
  for (let attempt = 1; attempt <= options.maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (err) {
      lastError = err;
      if (!options.retryOn(err) || attempt === options.maxAttempts) throw err;
      const jitter = Math.random() * options.baseDelayMs;
      const delay = options.baseDelayMs * Math.pow(2, attempt - 1) + jitter;
      await sleep(delay);
    }
  }
  throw lastError;
}

// Usage
const result = await withRetry(
  () => httpClient.get('/api/data'),
  {
    maxAttempts: 3,
    baseDelayMs: 100,
    retryOn: (err) => isRateLimitError(err) || isNetworkError(err),
  },
);
```

Do not retry:
- 400, 401, 403, 404, 422 — these will not resolve on retry
- Mutations (POST, DELETE) unless the operation is idempotent and you can verify non-partial completion

**Step 4: Implement circuit breaker for dependency errors**

A circuit breaker prevents a struggling dependency from taking down your service through cascading failures.

States:
- **Closed** (normal): requests pass through. Failures increment counter.
- **Open** (tripped): requests fail immediately without calling the dependency. Opens when failure threshold is exceeded.
- **Half-open** (testing): after a cooldown period, one request is allowed through. If it succeeds, close the circuit. If it fails, reopen.

```typescript
// Use a library (opossum for Node, resilience4j-circuitbreaker for JVM,
// circuitbreaker from tenacity for Python) rather than implementing from scratch.

import CircuitBreaker from 'opossum';

const breaker = new CircuitBreaker(callExternalService, {
  timeout: 3000,           // request timeout
  errorThresholdPercentage: 50,  // open when 50% of requests fail
  resetTimeout: 30000,     // attempt half-open after 30s
  volumeThreshold: 10,     // min requests before calculating error rate
});

breaker.on('open', () => logger.error('Circuit breaker opened', { service: 'external-api' }));
breaker.on('halfOpen', () => logger.info('Circuit breaker testing recovery'));
breaker.on('close', () => logger.info('Circuit breaker closed'));
```

**Step 5: Define graceful degradation paths**

For every dependency, define what the service does when the dependency is unavailable:

| Dependency unavailable | Degradation strategy |
|---|---|
| Cache (Redis) | Fall back to database; log cache miss; continue serving |
| Recommendation service | Return empty recommendations; do not fail the page load |
| Email provider | Queue the email for retry; return success to the user |
| Payment provider | Return 503 with `Retry-After`; do not lose the transaction |
| Search service | Fall back to basic filtering; disable advanced search UI |
| Analytics/logging | Continue serving; drop analytics silently |

Degradation must be explicit — define it per dependency at design time. "We'll handle it if it happens" is not a degradation strategy.

**Step 6: Ensure error observability**

Every unhandled or operational error must be logged with structured fields:

```typescript
logger.error('Document fetch failed', {
  error_code: err.code,
  error_message: err.message,
  document_id: id,
  user_id: context.userId,
  request_id: context.requestId,
  stack: err.stack,        // only for non-operational / unexpected errors
  duration_ms: Date.now() - startTime,
});
```

Required fields on every error log:
- `error_code`: machine-readable string constant
- `error_message`: human-readable, no secrets
- `request_id`: correlation ID from the request context
- `stack`: for programming errors and unexpected failures only
- Domain context: IDs, user context, operation name

Never log:
- Passwords, tokens, API keys, PII beyond what is necessary for debugging
- Full request bodies (may contain credentials)
- Full SQL query text with parameter values in high-volume paths

## Error Handling Checklist

```
Design:
- [ ] Error hierarchy defined with isOperational flag
- [ ] Error classes cover: validation, not found, auth, dependency, unexpected
- [ ] Error propagation direction is clear (infra → domain → API)

Resilience:
- [ ] Retry strategy defined for all transient-failure paths
- [ ] Circuit breaker in place for all external service dependencies
- [ ] Graceful degradation path defined per dependency

Observability:
- [ ] All errors logged with structured fields + request_id
- [ ] Operational vs non-operational errors routed differently
- [ ] Non-operational errors trigger alerts, not just logs

API surface:
- [ ] Error responses follow consistent schema (see api-contract)
- [ ] Stack traces never exposed to API consumers
- [ ] Error codes are stable machine-readable strings
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| `catch (err) { console.log(err) }` — catch and discard | Re-throw or translate with context |
| Retrying non-idempotent mutations blindly | Only retry explicitly idempotent operations |
| Generic `throw new Error('something went wrong')` | Domain-typed error with structured context |
| Catching `Error` base class and discarding unknown errors | Let unknowns propagate to global handler |
| No timeout on external calls | Set explicit per-request timeouts everywhere |
| Cascading failure when one dependency is slow | Circuit breaker + timeout + fallback |
| Logging sensitive data in error context | Sanitize: log IDs, not values |
| Treating all 5xx as retryable | Classify first: 503 may be retryable, 500 usually is not |

## Connected Skills

- `observability` — structured error logging feeds into distributed tracing and alerting
- `api-contract` — error response schema design
- `nestjs` — NestJS exception filters implement this skill's boundary translation
- `python-fastapi` — FastAPI exception handlers implement boundary translation
- `rust` — Rust `Result`/`?` operator as the type-safe version of these patterns
- `debug-trace` — when production errors need root cause analysis
