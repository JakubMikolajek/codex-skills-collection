---
name: message-queue
description: Message queue patterns for RabbitMQ and AMQP-based systems. Covers exchange and queue topology design, consumer patterns, idempotency, dead-letter queues, retry strategies, and message durability. Use when implementing async task processing, event-driven communication between services, or reliable background job execution.
---

# Message Queue (RabbitMQ / AMQP)

A message queue decouples producers from consumers and provides durability for async work. The patterns in this skill apply to RabbitMQ — the most common AMQP broker — and generally to any AMQP-compatible system.

## When to Use

- Processing work asynchronously without blocking an HTTP request (document indexing, email sending, report generation)
- Communicating between services without tight coupling (service A publishes an event, service B consumes it)
- Ensuring a task is processed at least once even if the consumer crashes mid-processing
- Rate-limiting work against an external API by controlling consumer concurrency
- Your thesis: RabbitMQ for the document processing pipeline (chunking, embedding, indexing)

## When NOT to Use

- Synchronous request-response — use HTTP or gRPC
- Simple background jobs that can run in the same process — use `setImmediate` or `asyncio.create_task`
- Real-time bidirectional communication — use WebSocket (see `websocket-realtime`)
- Pub/sub for WebSocket fan-out — Redis pub/sub is simpler for that use case

## Core Concepts

**Exchange types:**

| Type | Routing | Use case |
|---|---|---|
| `direct` | Exact routing key match | Task queue — route jobs to specific worker type |
| `topic` | Pattern match (`*.error`, `docs.#`) | Event routing by category |
| `fanout` | All bound queues | Broadcast to all consumers (notifications) |
| `headers` | Message header attributes | Rarely needed; prefer topic |

**Message acknowledgment modes:**
- `ack` — message successfully processed, remove from queue
- `nack` (requeue: true) — processing failed, return to queue for retry
- `nack` (requeue: false) — processing failed permanently, route to dead-letter queue
- `reject` — equivalent to `nack` for a single message

Never use `autoAck: true` in production — if the consumer crashes after receiving but before processing, the message is lost.

## Queue Topology Design

Design topology before writing code. The topology is infrastructure — changing it in production requires careful migration.

**Standard task queue topology:**
```
Producer → [direct exchange: docs.tasks] → [queue: docs.index] → Consumer
                                          ↘ [queue: docs.email] → Consumer
```

**Event fan-out topology:**
```
Producer → [fanout exchange: docs.events] → [queue: docs.events.search-indexer]  → Consumer A
                                           → [queue: docs.events.notification-svc] → Consumer B
                                           → [queue: docs.events.audit-log]        → Consumer C
```

**Dead-letter topology (always include):**
```
[queue: docs.index] → on nack(requeue:false) → [exchange: dlx] → [queue: docs.index.dlq]
```

Declaration (Node.js `amqplib`):
```typescript
// Declare exchange
await channel.assertExchange('docs.tasks', 'direct', { durable: true });

// Declare queue with dead-letter config
await channel.assertQueue('docs.index', {
  durable: true,
  arguments: {
    'x-dead-letter-exchange': 'dlx',
    'x-dead-letter-routing-key': 'docs.index.dead',
    'x-message-ttl': 24 * 60 * 60 * 1000, // 1 day max TTL
  },
});

// Bind queue to exchange
await channel.bindQueue('docs.index', 'docs.tasks', 'index');

// Dead-letter exchange and queue
await channel.assertExchange('dlx', 'direct', { durable: true });
await channel.assertQueue('docs.index.dlq', { durable: true });
await channel.bindQueue('docs.index.dlq', 'dlx', 'docs.index.dead');
```

## Producer Patterns

```typescript
async function publishTask(task: IndexTask): Promise<void> {
  const message = Buffer.from(JSON.stringify({
    id: crypto.randomUUID(),          // stable message ID for idempotency
    type: 'index',
    payload: task,
    timestamp: new Date().toISOString(),
    version: 1,
  }));

  const published = channel.publish(
    'docs.tasks',
    'index',
    message,
    {
      persistent: true,               // survive broker restart
      contentType: 'application/json',
      messageId: task.documentId,     // deduplication key
    },
  );

  if (!published) {
    // Channel write buffer is full — wait for drain
    await new Promise<void>((resolve) => channel.once('drain', resolve));
  }
}
```

**Publisher confirms** — guarantee messages reach the broker:
```typescript
await channel.confirmChannel(); // switch to confirm mode

channel.publish('docs.tasks', 'index', message, { persistent: true });

// Wait for broker acknowledgment
await new Promise<void>((resolve, reject) => {
  channel.waitForConfirms((err) => err ? reject(err) : resolve());
});
```

Without publisher confirms, a network failure between publish and broker receipt loses the message silently.

## Consumer Patterns

```typescript
async function startConsumer() {
  // Prefetch: process N messages concurrently, don't send more until acked
  await channel.prefetch(5);

  await channel.consume('docs.index', async (msg) => {
    if (!msg) return; // consumer cancelled

    const body = JSON.parse(msg.content.toString());

    try {
      await processTask(body);
      channel.ack(msg);
    } catch (err) {
      const retryCount = (msg.properties.headers?.['x-retry-count'] ?? 0) as number;

      if (retryCount < 3 && isRetryable(err)) {
        // Republish with retry count — delay handled by TTL + DLQ pattern
        channel.nack(msg, false, false); // send to DLQ
        await publishWithDelay(body, retryCount + 1);
      } else {
        // Permanent failure — send to DLQ
        logger.error('Message failed permanently', { messageId: body.id, error: err.message });
        channel.nack(msg, false, false);
      }
    }
  });
}
```

**Prefetch** is the most important consumer setting. Without it, RabbitMQ sends all queued messages to the consumer at once, causing memory exhaustion. Set to the number of concurrent tasks you want to process.

### Delayed Retry (RabbitMQ Delayed Message Plugin)

```typescript
// Using rabbitmq_delayed_message_exchange plugin
await channel.assertExchange('docs.tasks.delayed', 'x-delayed-message', {
  durable: true,
  arguments: { 'x-delayed-type': 'direct' },
});

async function publishWithDelay(body: unknown, retryCount: number) {
  const delayMs = Math.min(1000 * Math.pow(2, retryCount), 60_000); // exponential, max 1min
  channel.publish(
    'docs.tasks.delayed',
    'index',
    Buffer.from(JSON.stringify(body)),
    {
      persistent: true,
      headers: {
        'x-delay': delayMs,
        'x-retry-count': retryCount,
      },
    },
  );
}
```

## Idempotency

Consumers must handle duplicate message delivery. RabbitMQ guarantees at-least-once delivery — a message can be delivered more than once if the consumer fails after processing but before acking.

**Idempotency key pattern:**
```typescript
async function processTask(body: TaskMessage): Promise<void> {
  const key = `processed:${body.id}`;

  // Check if already processed (Redis or DB)
  const alreadyProcessed = await redis.get(key);
  if (alreadyProcessed) {
    logger.info('Skipping duplicate message', { messageId: body.id });
    return;
  }

  // Process
  await doWork(body.payload);

  // Mark as processed with TTL longer than max retry window
  await redis.set(key, '1', 'EX', 86400); // 24 hours
}
```

For database-backed idempotency, use an `INSERT ... ON CONFLICT DO NOTHING` with the message ID as a unique key.

## Python Consumer (for thesis pipeline)

```python
import asyncio
import aio_pika
import json
from typing import Any

async def start_consumer():
    connection = await aio_pika.connect_robust(
        os.environ["RABBITMQ_URL"],
        reconnect_interval=5,
    )

    async with connection:
        channel = await connection.channel()
        await channel.set_qos(prefetch_count=5)

        queue = await channel.declare_queue(
            "docs.index",
            durable=True,
            arguments={
                "x-dead-letter-exchange": "dlx",
                "x-message-ttl": 86_400_000,
            },
        )

        async with queue.iterator() as queue_iter:
            async for message in queue_iter:
                async with message.process(requeue=False):
                    body = json.loads(message.body)
                    try:
                        await process_document(body)
                        # ack is automatic on successful context exit
                    except RetryableError:
                        raise  # triggers requeue=False → DLQ, then republish with delay
                    except Exception as e:
                        logger.error("Permanent failure", message_id=body["id"], error=str(e))
                        # context exit with exception → nack, no requeue → DLQ
```

`aio_pika.connect_robust` handles reconnection automatically — do not implement your own reconnect loop.

## Monitoring

Key metrics to expose:

```
rabbitmq_queue_messages_ready       # messages waiting to be consumed
rabbitmq_queue_messages_unacked     # messages in-flight (being processed)
rabbitmq_queue_consumers            # active consumer count
```

Alerts:
- `messages_ready > 1000 for 5min` → consumers are behind, scale up or investigate
- `messages_ready growing monotonically` → consumer is stopped or failing
- `DLQ messages_ready > 0` → permanent failures occurring, requires investigation

RabbitMQ Management Plugin exposes these via HTTP API and Prometheus scrape endpoint.

## Message Queue Checklist

```
Topology:
- [ ] Exchange type matches routing need (direct/topic/fanout)
- [ ] All queues are durable
- [ ] Dead-letter exchange and DLQ configured on every queue
- [ ] Message TTL set to prevent unbounded queue growth

Producer:
- [ ] Messages marked persistent
- [ ] Publisher confirms enabled for critical messages
- [ ] Message ID set for idempotency tracking

Consumer:
- [ ] prefetch set (not unlimited)
- [ ] Never autoAck — always explicit ack/nack
- [ ] Idempotency check before processing
- [ ] Retry with exponential backoff before DLQ
- [ ] aio_pika.connect_robust or equivalent for auto-reconnect

Operations:
- [ ] Queue depth monitored with alerts
- [ ] DLQ monitored (non-zero = investigation needed)
- [ ] Consumer lag defined as SLO
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| `autoAck: true` | Explicit ack after successful processing |
| No prefetch — consumer receives all messages at once | `channel.prefetch(N)` — limits in-flight |
| `nack(requeue: true)` on permanent errors | `nack(requeue: false)` → DLQ |
| No dead-letter queue | Always configure DLQ at topology creation |
| No idempotency check | Track processed message IDs in Redis or DB |
| Non-durable queues | `durable: true` — survives broker restart |
| Blocking I/O in consumer handler | Use async consumer with `aio_pika` or promises |

## Connected Skills

- `python-ai-ml` — thesis document processing pipeline publishes to and consumes from RabbitMQ
- `observability` — queue depth, consumer lag, and DLQ alerts
- `error-handling` — retry strategy and dead-letter handling follow error-handling principles
- `docker` — RabbitMQ runs as a Docker container; management plugin enables metrics scraping
