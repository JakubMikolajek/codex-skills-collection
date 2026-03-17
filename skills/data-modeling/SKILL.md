---
name: data-modeling
description: Domain-driven data modeling patterns covering aggregate design, entity boundaries, value objects, and event sourcing fundamentals. Use when designing the domain model for a new service, reviewing existing data structures for DDD correctness, or deciding how to structure complex business logic around data.
---

# Data Modeling

This skill covers the architectural side of data design — how to model a domain so that business rules are enforced by structure, not by discipline.

## When to Use

- Designing the domain model for a new service with non-trivial business rules
- Existing code has business logic scattered across services with no clear ownership
- Deciding how to partition a domain into aggregates and services
- Reviewing data structures for consistency, invariant enforcement, and boundary clarity

## When NOT to Use

- Simple CRUD with no business rules — a flat table is fine
- Physical schema design (column types, indexes) — use `sql-and-database`
- API request/response shapes — use `api-contract`

## Core Concepts

### Ubiquitous Language

Every concept in the domain model uses the same name as the business uses. If the business calls it a "Document Request" and the code calls it a `DocReq`, you have two models — and they will diverge.

- Name classes, methods, and variables after the business concept they represent
- When a business concept has no name yet, invent one with the domain experts
- Resist mapping business concepts to generic technical names (`Manager`, `Handler`, `Processor`)

### Entities vs Value Objects

**Entity** — has identity that persists over time. Two entities with identical attributes are still distinct.
```typescript
class Document {
  constructor(
    readonly id: DocumentId,  // identity
    private title: string,
    private content: string,
  ) {}
}
// Two documents with same title and content are different documents
```

**Value Object** — defined entirely by its attributes. Two value objects with identical attributes are interchangeable. Immutable by definition.
```typescript
class DocumentId {
  constructor(readonly value: string) {
    if (!isUUID(value)) throw new Error('DocumentId must be a UUID');
  }
  equals(other: DocumentId): boolean {
    return this.value === other.value;
  }
}

class Tag {
  constructor(readonly value: string) {
    if (!value.trim()) throw new Error('Tag cannot be empty');
    if (value.length > 50) throw new Error('Tag too long');
  }
}
```

Use value objects to:
- Enforce validation at construction time (invalid state is unrepresentable)
- Replace primitive obsession (`string` → `EmailAddress`, `number` → `Money`)
- Make method signatures self-documenting

### Aggregates

An aggregate is a cluster of entities and value objects with a defined boundary. The **aggregate root** is the only object external code may reference. All modifications to the aggregate go through the root.

Rules:
1. External objects hold references only to the aggregate root, never to internal entities
2. The aggregate root enforces all invariants for the entire cluster
3. Aggregates are the unit of transactional consistency — one transaction modifies one aggregate
4. Aggregates reference other aggregates by ID only (not by object reference)

```typescript
// Aggregate root
class Project {
  private members: ProjectMember[] = [];  // internal entity — not exposed directly
  private tags: Tag[] = [];               // value objects

  constructor(
    readonly id: ProjectId,
    private name: string,
    private ownerId: UserId,             // reference by ID, not User object
  ) {}

  // All mutations go through the root
  addMember(userId: UserId, role: MemberRole): void {
    if (this.members.some(m => m.userId.equals(userId))) {
      throw new DomainError('User is already a member');
    }
    if (this.members.length >= 50) {
      throw new DomainError('Project member limit reached');
    }
    this.members.push(new ProjectMember(userId, role));
  }

  removeMember(userId: UserId): void {
    if (userId.equals(this.ownerId)) {
      throw new DomainError('Cannot remove the project owner');
    }
    this.members = this.members.filter(m => !m.userId.equals(userId));
  }

  // Read access through the root
  getMember(userId: UserId): ProjectMember | undefined {
    return this.members.find(m => m.userId.equals(userId));
  }

  // Invariant: owner must always be a member
  private assertOwnerIsMember(): void {
    if (!this.members.some(m => m.userId.equals(this.ownerId))) {
      throw new Error('Invariant violation: owner must be a member');
    }
  }
}
```

### Aggregate Size

Keep aggregates small. Large aggregates cause:
- Transaction contention — two operations on the same project fight for the lock
- Performance problems — loading 1000 members to add one
- Unclear boundaries — everything becomes part of one giant aggregate

Signs an aggregate is too large:
- More than 5-10 internal entities
- Many unrelated operations on the same root
- Frequent optimistic lock conflicts
- Operations that only touch a small subset of the aggregate

**Split large aggregates by invariant.** Ask: "Which attributes must be consistent with which others?" Only cluster things that must change together in a single transaction.

```typescript
// Too large — Project has both metadata and all documents
class Project {
  members: Member[];
  documents: Document[];  // ← documents could be a separate aggregate
  settings: Settings;
  tags: Tag[];
}

// Better — separate aggregates, cross-reference by ID
class Project {        // aggregate: project metadata, membership
  members: Member[];
  settings: Settings;
  tags: Tag[];
}

class Document {       // aggregate: document content, its own lifecycle
  readonly projectId: ProjectId;  // reference by ID
  content: string;
  version: number;
}
```

## Repository Pattern

The repository abstracts persistence. The domain model has no knowledge of SQL, ORMs, or databases.

```typescript
// Domain interface — defined in the domain layer
interface DocumentRepository {
  findById(id: DocumentId): Promise<Document | null>;
  save(document: Document): Promise<void>;
  findByProject(projectId: ProjectId, filter: DocumentFilter): Promise<Document[]>;
  delete(id: DocumentId): Promise<void>;
}

// Infrastructure implementation — defined in the infrastructure layer
class PostgresDocumentRepository implements DocumentRepository {
  async findById(id: DocumentId): Promise<Document | null> {
    const row = await this.db.query(
      'SELECT * FROM documents WHERE id = $1',
      [id.value],
    );
    return row ? DocumentMapper.toDomain(row) : null;
  }

  async save(document: Document): Promise<void> {
    const data = DocumentMapper.toPersistence(document);
    await this.db.query(
      `INSERT INTO documents (id, title, content, project_id, version)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (id) DO UPDATE SET
         title = EXCLUDED.title,
         content = EXCLUDED.content,
         version = EXCLUDED.version`,
      [data.id, data.title, data.content, data.projectId, data.version],
    );
  }
}
```

The mapper isolates the domain model from the persistence model:
```typescript
class DocumentMapper {
  static toDomain(row: DocumentRow): Document {
    return new Document(
      new DocumentId(row.id),
      row.title,
      row.content,
      new ProjectId(row.project_id),
      row.version,
    );
  }

  static toPersistence(doc: Document): DocumentRow {
    return {
      id: doc.id.value,
      title: doc.title,
      content: doc.content,
      project_id: doc.projectId.value,
      version: doc.version,
    };
  }
}
```

## Domain Events

Domain events record that something happened. They are facts about the past.

```typescript
// Base event type
abstract class DomainEvent {
  readonly occurredAt: Date = new Date();
  abstract readonly type: string;
}

class DocumentPublished extends DomainEvent {
  readonly type = 'document.published';
  constructor(
    readonly documentId: DocumentId,
    readonly projectId: ProjectId,
    readonly publishedBy: UserId,
  ) { super(); }
}

// Aggregate collects events (outbox pattern)
class Document {
  private _events: DomainEvent[] = [];

  get events(): DomainEvent[] { return [...this._events]; }
  clearEvents(): void { this._events = []; }

  publish(by: UserId): void {
    if (this.status === 'published') throw new DomainError('Already published');
    this.status = 'published';
    this._events.push(new DocumentPublished(this.id, this.projectId, by));
  }
}

// Application service saves aggregate and dispatches events
async function publishDocument(id: DocumentId, userId: UserId): Promise<void> {
  const doc = await documentRepo.findById(id);
  if (!doc) throw new NotFoundError('Document', id.value);

  doc.publish(new UserId(userId));

  await documentRepo.save(doc);
  // Dispatch events after successful save (outbox pattern for reliability)
  await eventBus.publish(doc.events);
  doc.clearEvents();
}
```

## Event Sourcing (Fundamentals)

Event sourcing stores events as the source of truth — not the current state. Current state is derived by replaying events.

When to consider it:
- Full audit trail is required (financial, medical, legal)
- Time-travel queries ("what did this look like last Tuesday?")
- Complex undo/redo requirements

When NOT to use it:
- Simple CRUD — the event sourcing overhead is not justified
- Most web applications — state-based persistence is simpler and sufficient

Basic structure:
```typescript
// Events are the source of truth
type DocumentEvent =
  | { type: 'DocumentCreated'; id: string; title: string; projectId: string }
  | { type: 'DocumentTitleUpdated'; title: string }
  | { type: 'DocumentPublished'; publishedAt: string };

// State is derived by folding events
function applyEvent(state: DocumentState, event: DocumentEvent): DocumentState {
  switch (event.type) {
    case 'DocumentCreated':
      return { id: event.id, title: event.title, status: 'draft' };
    case 'DocumentTitleUpdated':
      return { ...state, title: event.title };
    case 'DocumentPublished':
      return { ...state, status: 'published' };
  }
}

function rehydrate(events: DocumentEvent[]): DocumentState {
  return events.reduce(applyEvent, {} as DocumentState);
}
```

## Data Modeling Checklist

```
Domain language:
- [ ] All concepts named after business terms
- [ ] No generic names (Manager, Handler, Processor) for domain objects

Entities and value objects:
- [ ] Entities have identity; value objects are immutable and structurally equal
- [ ] Primitive obsession replaced with typed value objects
- [ ] Value objects enforce validation at construction

Aggregates:
- [ ] Aggregate root is the only external reference point
- [ ] All mutations go through the aggregate root
- [ ] Aggregates are small (5-10 entities max)
- [ ] Cross-aggregate references are by ID only

Repositories:
- [ ] Repository interface defined in domain layer
- [ ] Implementation in infrastructure layer
- [ ] Domain model has no ORM/SQL knowledge

Invariants:
- [ ] Business rules enforced by domain model, not service layer
- [ ] Invalid state is structurally unrepresentable
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Business rules in service layer / controllers | Push invariants into the aggregate |
| Anemic domain model (data bags, logic in services) | Behavior belongs on entities and aggregates |
| Cross-aggregate object references | Cross-aggregate references by ID only |
| One transaction spanning multiple aggregates | Redesign boundaries or use eventual consistency |
| `class DocumentManager` | `class Document` — name after the concept |
| `string` for every ID | `DocumentId`, `ProjectId` — typed value objects |

## Connected Skills

- `sql-and-database` — physical schema design follows domain model structure
- `migration-strategy` — domain model changes require corresponding schema migrations
- `architecture-design` — aggregate boundaries align with service boundaries
- `nestjs` — NestJS module boundaries map to bounded contexts
- `python-fastapi` — Pydantic models as value objects in the Python domain layer
