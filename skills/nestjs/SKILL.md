---
name: nestjs
description: NestJS implementation and review patterns for modular backend systems and microservices. Use when Codex needs to build, refactor, debug, or review NestJS modules, controllers, services, DTOs, validation, guards, interceptors, background processing, dependency injection, microservice transports (TCP, RabbitMQ, Redis), message and event patterns, or test coverage for API and microservice behavior.
---

# NestJS Implementation Patterns

Use this skill to keep NestJS code modular, testable, and aligned with clear request-to-domain boundaries.

## Delivery Workflow

Use the checklist below and track progress:

```
NestJS progress:
- [ ] Step 1: Discover module boundaries and framework conventions
- [ ] Step 2: Model DTOs, validation, and authorization boundaries
- [ ] Step 3: Implement controller/service/repository responsibilities cleanly
- [ ] Step 4: Handle errors, side effects, and infrastructure concerns explicitly
- [ ] Step 5: Verify tests, security, and observability paths
```

## Architecture Rules

- Keep controllers thin: accept requests, delegate work, return mapped responses.
- Put business logic in services or dedicated domain collaborators, not decorators or controllers.
- Keep modules cohesive and avoid circular dependencies.
- Make provider ownership clear; do not register the same concern in multiple modules casually.
- Reuse project-standard patterns for config, logging, and cross-cutting concerns.

## DTOs, Validation, and Transformation

- Validate external input at the boundary.
- Keep DTOs focused on transport shape, not internal domain behavior.
- Map DTOs to domain/service inputs explicitly when complexity grows.
- Avoid leaking persistence entities directly through controller responses unless the project already standardizes that pattern.
- Treat parsing, defaults, and coercion as explicit choices.

## Security and Request Pipeline

- Apply guards, roles, and authorization checks where the project expects them.
- Keep authentication, authorization, validation, and business rules as separate concerns.
- Use interceptors, pipes, and filters intentionally for cross-cutting behavior.
- Return predictable error shapes and status codes.
- Do not expose internal exception details or persistence internals to clients.

## Services and Data Access

- Keep service methods focused on one business use case.
- Isolate database access behind the project's existing repository/data-access pattern.
- Make transactions explicit when a use case spans multiple writes.
- Keep external API calls and message publishing visible in orchestration code.
- Avoid mixing persistence, authorization, validation, and mapping logic in one method.

## Testing Checklist

```
HTTP/API:
- [ ] Request validation and status codes are covered
- [ ] Auth and authorization branches are covered where critical
- [ ] Error mapping is asserted explicitly

Service layer:
- [ ] Core business rules are tested directly
- [ ] Side effects and integration boundaries are isolated or mocked intentionally

Design:
- [ ] Controllers remain thin
- [ ] Module boundaries stay cohesive
```

## Microservices

NestJS has first-class support for microservice transport layers. Use this section when the service communicates via message broker or TCP rather than (or in addition to) HTTP.

### Transport Selection

| Transport | Use case |
|---|---|
| `TCP` | Internal service-to-service RPC within a trusted network |
| `RabbitMQ` | Async event-driven communication, durable queues, dead-letter support |
| `Redis` | Low-latency pub/sub, ephemeral messages where loss is acceptable |
| `Kafka` | High-throughput event streaming, replay, ordered processing |

For your stack (thesis + CodePath): RabbitMQ is the right choice for document processing pipelines. Redis transport for low-latency IDE service communication.

### Hybrid Application (HTTP + Microservice)

The most common pattern — one service exposes both an HTTP API and a microservice interface:

```typescript
// main.ts — hybrid app
async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Add microservice transport alongside HTTP
  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.RMQ,
    options: {
      urls: [process.env.RABBITMQ_URL],
      queue: 'documents_queue',
      queueOptions: { durable: true },
      prefetchCount: 5,
      noAck: false,  // explicit ack — never autoAck in production
    },
  });

  await app.startAllMicroservices();
  await app.listen(3000);
}
```

### Message Patterns vs Event Patterns

```typescript
// @MessagePattern — request/response (expects a reply)
@Controller()
export class DocumentController {
  @MessagePattern('get_document')
  async getDocument(@Payload() data: { id: string }): Promise<DocumentDto> {
    return this.documentService.findById(data.id);
  }
}

// @EventPattern — fire-and-forget (no reply expected)
@Controller()
export class DocumentController {
  @EventPattern('document.created')
  async onDocumentCreated(@Payload() data: DocumentCreatedEvent): Promise<void> {
    await this.indexingService.index(data.documentId);
    // No return value — this is a side effect handler
  }
}
```

Use `@MessagePattern` when the caller needs a result. Use `@EventPattern` for side effects triggered by domain events.

### Sending Messages from a Service (ClientProxy)

```typescript
// Register client in module
@Module({
  imports: [
    ClientsModule.registerAsync([{
      name: 'DOCUMENT_SERVICE',
      useFactory: (config: ConfigService) => ({
        transport: Transport.RMQ,
        options: {
          urls: [config.get('RABBITMQ_URL')],
          queue: 'documents_queue',
          queueOptions: { durable: true },
        },
      }),
      inject: [ConfigService],
    }]),
  ],
})

// Inject and use
@Injectable()
export class SearchService {
  constructor(
    @Inject('DOCUMENT_SERVICE') private readonly client: ClientProxy,
  ) {}

  async getDocument(id: string): Promise<DocumentDto> {
    // send() — request/response, returns Observable
    return firstValueFrom(
      this.client.send<DocumentDto>('get_document', { id }).pipe(
        timeout(5000),   // always set a timeout
        catchError((err) => {
          if (err instanceof TimeoutError) throw new ServiceUnavailableException();
          throw err;
        }),
      ),
    );
  }

  async notifyCreated(event: DocumentCreatedEvent): Promise<void> {
    // emit() — fire-and-forget, returns Observable<void>
    this.client.emit('document.created', event);
    // Note: emit() does not guarantee delivery without publisher confirms
  }
}
```

### Acknowledgment and Error Handling

With `noAck: false`, messages must be explicitly acknowledged:

```typescript
@EventPattern('document.index')
async indexDocument(
  @Payload() data: IndexDocumentPayload,
  @Ctx() context: RmqContext,
): Promise<void> {
  const channel = context.getChannelRef();
  const message = context.getMessage();

  try {
    await this.indexingService.index(data);
    channel.ack(message);  // success — remove from queue
  } catch (err) {
    if (isRetryable(err)) {
      channel.nack(message, false, true);   // requeue for retry
    } else {
      channel.nack(message, false, false);  // send to dead-letter queue
      this.logger.error('Permanent indexing failure', { documentId: data.id });
    }
  }
}
```

### Microservice Testing

```typescript
// Test with a mock ClientProxy
const mockClient = {
  send: jest.fn().mockReturnValue(of(mockDocument)),
  emit: jest.fn().mockReturnValue(of(undefined)),
};

const module = await Test.createTestingModule({
  providers: [
    SearchService,
    { provide: 'DOCUMENT_SERVICE', useValue: mockClient },
  ],
}).compile();

// Verify message pattern handler directly
it('indexes document on document.created event', async () => {
  const channel = { ack: jest.fn(), nack: jest.fn() };
  const context = { getChannelRef: () => channel, getMessage: () => ({}) } as RmqContext;

  await controller.indexDocument({ documentId: 'doc-1' }, context);

  expect(mockIndexingService.index).toHaveBeenCalledWith('doc-1');
  expect(channel.ack).toHaveBeenCalled();
});
```

### Microservice Checklist

```
Transport:
- [ ] noAck: false — explicit acknowledgment
- [ ] prefetchCount set (not unlimited)
- [ ] Timeout set on all send() calls
- [ ] Dead-letter queue configured in broker

Patterns:
- [ ] @MessagePattern for request/response
- [ ] @EventPattern for fire-and-forget side effects
- [ ] Payload validated with class-validator DTO

Error handling:
- [ ] Retryable errors: nack with requeue: true
- [ ] Permanent errors: nack with requeue: false → DLQ
- [ ] Timeout errors mapped to ServiceUnavailableException

Testing:
- [ ] ClientProxy mocked in unit tests
- [ ] Message handler tested with mock RmqContext
- [ ] Ack/nack called correctly in all branches
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Fat controller with business logic | Delegate to service/domain layer |
| DTO reused as domain model everywhere | Separate transport and domain concerns |
| Ad hoc validation inside service methods | Validate at the framework boundary first |
| Circular module/provider wiring | Reshape boundaries or extract shared concern |
| Generic catch-and-log-everything blocks | Map errors intentionally and preserve useful context |
| `noAck: true` on microservice consumer | Explicit ack/nack — message loss on crash |
| No timeout on `client.send()` | `pipe(timeout(5000))` — always set a deadline |
| Business logic in `@EventPattern` handler | Delegate to service; handler only acks/nacks |
| Shared `ClientProxy` instance across tests | Mock per test — `{ provide: 'SERVICE', useValue: mockClient }` |

## Connected Skills

- `technical-context-discovery` - follow established NestJS and repo conventions before editing
- `sql-and-database` - use when persistence, migrations, or query design are involved
- `code-review` - validate architecture, security, and testing quality
- `message-queue` - for RabbitMQ topology design, exchange/queue config, and dead-letter patterns outside NestJS
- `error-handling` - retry strategy and circuit breaker patterns for microservice client calls
- `observability` - structured logging and metrics for microservice message processing
