---
name: observability
description: Structured logging, metrics, distributed tracing, and alerting patterns for production services. Covers OpenTelemetry, log schema design, correlation IDs, health endpoints, and alert definition. Use when instrumenting a new service, reviewing observability coverage, debugging production issues, or designing an on-call runbook.
---

# Observability

Observability is the ability to understand what a system is doing from its outputs alone — without modifying the code or attaching a debugger. This skill covers the three pillars: logs, metrics, and traces, plus the patterns that make them useful under production pressure.

## When to Use

- Instrumenting a new service before it ships to production
- A production incident revealed a blind spot (missing logs, no latency metrics)
- Setting up health endpoints, readiness probes, or alerting rules
- Reviewing a service for observability coverage before go-live
- Building an on-call runbook that references metrics and alerts

## When NOT to Use

- Application-level error handling design — see `error-handling`
- CI/CD pipeline monitoring — see `ci-cd`
- Frontend performance monitoring (Core Web Vitals) — different toolchain

## Core Principle

**Instrument for the person who will be paged at 3am.** Every log entry, metric, and alert should answer: what happened, where, when, and who was affected. Abstract observability is useless — every piece of instrumentation should be traceable to a specific operational question it answers.

## Three Pillars

| Pillar | Answers | Tool |
|---|---|---|
| **Logs** | What happened and in what sequence? | Structured JSON → Loki, CloudWatch, Datadog |
| **Metrics** | How much, how often, how fast, how many errors? | Prometheus, OpenTelemetry metrics → Grafana |
| **Traces** | Where did this request spend its time across services? | OpenTelemetry traces → Jaeger, Tempo, Datadog |

These are not alternatives — they complement each other. Logs explain, metrics alert, traces diagnose.

## Observability Process

```
Observability progress:
- [ ] Step 1: Implement structured logging with correlation IDs
- [ ] Step 2: Instrument key metrics (RED method)
- [ ] Step 3: Add distributed tracing
- [ ] Step 4: Implement health and readiness endpoints
- [ ] Step 5: Define alerts on metrics
```

**Step 1: Implement structured logging with correlation IDs**

Log format — always JSON in production, never plain text:

```json
{
  "timestamp": "2025-03-15T14:30:00.123Z",
  "level": "info",
  "message": "Document created",
  "service": "document-service",
  "version": "1.4.2",
  "request_id": "req_abc123",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "span_id": "00f067aa0ba902b7",
  "user_id": "usr_xyz789",
  "document_id": "doc_def456",
  "duration_ms": 42
}
```

Required fields on every log entry:
- `timestamp`: ISO 8601 with milliseconds, UTC
- `level`: `debug` | `info` | `warn` | `error` | `critical`
- `message`: human-readable, describes what happened (past tense, active voice)
- `service`: service name — constant, not hostname
- `request_id`: correlation ID injected from HTTP header or generated at request entry point
- `trace_id` / `span_id`: OpenTelemetry trace context when tracing is enabled

Correlation ID propagation:
- Generate `X-Request-ID` at the API gateway or first service if not present
- Forward `X-Request-ID` in all downstream HTTP requests
- Include `X-Request-ID` in all API error responses
- Log `request_id` on every entry related to that request

Log levels — use precisely:
| Level | When |
|---|---|
| `debug` | Detailed execution flow, disabled in production by default |
| `info` | Business-meaningful events: request received, document created, job started |
| `warn` | Unexpected but handled: fallback triggered, retry attempt, deprecated usage |
| `error` | Operational failures: request failed, dependency returned 5xx |
| `critical` | System-level failures: database unreachable, out of memory, data corruption suspected |

Never log: passwords, tokens, API keys, full credit card numbers, SSNs, session cookies. Log IDs, not values.

**Step 2: Instrument key metrics (RED method)**

RED method for every service endpoint and background job:
- **Rate**: requests per second
- **Errors**: error rate (count and percentage)
- **Duration**: latency distribution (p50, p95, p99)

Prometheus metric naming convention:
```
<service_name>_<unit>_<suffix>
http_requests_total              # counter
http_request_duration_seconds    # histogram
http_requests_in_flight          # gauge
queue_messages_processed_total   # counter
queue_processing_duration_seconds # histogram
```

Essential metrics to instrument:

HTTP services:
```typescript
// Counter — increments, never decrements
httpRequestsTotal.inc({
  method: req.method,
  route: req.route.path,   // template, not actual path (avoids high cardinality)
  status_code: res.statusCode,
});

// Histogram — captures latency distribution
httpRequestDuration.observe(
  { method: req.method, route: req.route.path },
  durationSeconds,
);
```

Background jobs / queues:
- `jobs_processed_total{status: success|failure}`
- `job_processing_duration_seconds{job_type}`
- `queue_depth{queue_name}` — gauge of pending messages
- `queue_consumer_lag_seconds{queue_name}` — how far behind consumers are

Business metrics (pick based on the service):
- `documents_created_total`, `documents_deleted_total`
- `active_sessions_total`
- `cache_hit_ratio` — gauge, updated periodically
- `external_api_calls_total{service, status}`

Avoid high-cardinality labels (user_id, document_id in labels will break Prometheus). Labels should be bounded: method, route template, status code, job type.

**Step 3: Add distributed tracing**

Use OpenTelemetry SDK — it is vendor-neutral and supported by every major backend:

```typescript
// Node.js — initialize before all other imports
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({ url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT }),
  instrumentations: [getNodeAutoInstrumentations()],
});
sdk.start();
```

Auto-instrumentation covers: HTTP incoming/outgoing, database queries (pg, mysql, redis), message queues, gRPC. Manual spans for business logic:

```typescript
import { trace } from '@opentelemetry/api';
const tracer = trace.getTracer('document-service');

async function processDocument(id: string) {
  return tracer.startActiveSpan('processDocument', async (span) => {
    span.setAttribute('document.id', id);
    try {
      const result = await doWork(id);
      span.setStatus({ code: SpanStatusCode.OK });
      return result;
    } catch (err) {
      span.recordException(err);
      span.setStatus({ code: SpanStatusCode.ERROR, message: err.message });
      throw err;
    } finally {
      span.end();
    }
  });
}
```

Span naming conventions:
- HTTP: `GET /documents/{id}` (use route template, not actual path)
- DB: `SELECT documents` (operation + table, no query parameters)
- Custom: `<service>.<operation>` e.g. `embedding.generate`, `rag.retrieve`

**Step 4: Implement health and readiness endpoints**

Every service must expose two endpoints:

`GET /health` — liveness probe (is the process alive?):
```json
{ "status": "ok", "version": "1.4.2", "uptime_seconds": 3600 }
```
- Always returns 200 if the process can serve HTTP
- Failure causes the orchestrator to restart the pod/container
- Does NOT check dependencies — a database being down should not cause a restart

`GET /ready` — readiness probe (is the service ready to accept traffic?):
```json
{
  "status": "ok",
  "checks": {
    "database": { "status": "ok", "latency_ms": 4 },
    "cache": { "status": "ok", "latency_ms": 1 },
    "queue": { "status": "degraded", "message": "high lag: 500ms" }
  }
}
```
- Returns 200 only when all critical dependencies are healthy
- Returns 503 if a critical dependency is unavailable — removes service from load balancer
- Failure does NOT restart the container, only removes it from traffic rotation
- Run dependency checks with a timeout (500ms max) — never block indefinitely

**Step 5: Define alerts on metrics**

Alert philosophy: alert on symptoms (user-visible impact), not causes (CPU high). A high CPU alert that doesn't affect users creates noise. A high error rate that does affect users requires immediate action.

Core alert set:

| Alert | Condition | Severity | Action |
|---|---|---|---|
| High error rate | `error_rate > 5% for 5min` | critical | Page on-call |
| High latency | `p99 > 2s for 5min` | warning | Notify team |
| Service down | `up == 0 for 1min` | critical | Page on-call |
| Queue consumer lag | `lag > 60s for 10min` | warning | Notify team |
| Disk space | `disk_used > 85%` | warning | Notify team |

Alert quality rules:
- Every alert must have a runbook link
- Every page-worthy alert must be actionable within 5 minutes (otherwise: lower severity)
- Alerts should be silent during planned maintenance windows
- Review and tune alert thresholds after every false-positive page

Runbook template per alert:
```markdown
## Alert: High error rate on document-service

### What it means
More than 5% of requests are returning 5xx errors.

### Immediate triage
1. Check error logs: `service=document-service level=error`
2. Check recent deployments in the last 30 minutes
3. Check database health: `GET /ready` on database-service

### Common causes
- Failed database migration (check migration status)
- External API dependency down (check circuit breaker metrics)
- Memory leak after recent deploy (check memory metrics)

### Escalation
If not resolved in 15 minutes, escalate to [team lead]
```

## Observability Checklist

```
Logging:
- [ ] JSON structured logging in production
- [ ] request_id on every log entry
- [ ] Correlation ID propagated across service calls
- [ ] Log levels used precisely
- [ ] No secrets or PII in logs

Metrics:
- [ ] Rate, errors, duration instrumented per endpoint
- [ ] Labels are low-cardinality (no user IDs, document IDs)
- [ ] Business metrics instrumented for key operations
- [ ] Dashboards exist for service health

Tracing:
- [ ] OpenTelemetry SDK initialized
- [ ] Auto-instrumentation enabled (HTTP, DB, queues)
- [ ] Custom spans for business-critical operations
- [ ] Trace context propagated in outgoing HTTP headers

Health:
- [ ] /health endpoint (liveness — no dependency checks)
- [ ] /ready endpoint (readiness — with dependency checks + timeout)
- [ ] Kubernetes probes configured (if applicable)

Alerting:
- [ ] Critical alerts defined for: high error rate, service down, high latency
- [ ] Every alert has a runbook
- [ ] Alerts tested against real thresholds (not just theory)
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Plain text logs (`[ERROR] something failed`) | Structured JSON with context fields |
| Logging user_id or document_id as metric labels | Use them in log fields, not metric labels |
| `/health` checking database (blocks restarts during DB outage) | Split liveness (`/health`) from readiness (`/ready`) |
| Alert: "CPU > 80%" | Alert: "p99 latency > 2s" or "error rate > 5%" |
| Alert with no runbook | Every alert links to a runbook with triage steps |
| Trace sampling at 100% in production | Sample at 10–20%, always sample errors |
| Unique request URL as span name | Route template as span name (avoid high cardinality) |
| Logging secrets, tokens, or full credential payloads | Redact sensitive fields at logger boundary before writing logs |
| Missing `request_id` in error response | Return `request_id` in every error response |

## Connected Skills

- `error-handling` — structured error logging is the output of a good error handling design
- `ci-cd` — deployment events should create a deployment marker in the metrics dashboard
- `api-contract` — `request_id` in error responses is part of the API contract
- `docker` — health and readiness endpoints are used by Docker/Kubernetes orchestration
- `debug-trace` — observability data is the input to production debugging
