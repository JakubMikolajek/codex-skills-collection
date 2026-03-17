---
name: graphql
description: GraphQL schema design, resolver implementation, and performance patterns. Covers type system design, mutation patterns, N+1 problem with DataLoader, subscriptions, error handling, and security considerations. Use when designing or implementing a GraphQL API, reviewing resolver code, or solving N+1 query problems.
---

# GraphQL

GraphQL's power comes from its type system and client-driven queries. Its most common failure modes come from ignoring what that freedom costs on the server side.

## When to Use

- Designing a new GraphQL API or adding types/resolvers to an existing one
- Reviewing resolver code for N+1 problems or missing authorization
- Implementing subscriptions for real-time data
- A GraphQL endpoint is slow and the cause is unknown
- Migrating from REST to GraphQL or running both in parallel

## When NOT to Use

- Simple CRUD APIs with no complex data relationships — REST is simpler
- File upload endpoints — use a REST endpoint alongside GraphQL
- Public APIs consumed by third parties who need stable versioning — REST with OpenAPI is clearer

## Schema Design

### Types

Use specific scalar types — never fall back to `String` when a purpose-built type exists:

```graphql
scalar DateTime    # ISO 8601 timestamp
scalar UUID        # UUID string with validation
scalar URL         # Valid URL string
scalar JSON        # Untyped JSON — use sparingly, prefer typed objects

type Document {
  id: UUID!
  title: String!
  content: String!
  tags: [String!]!      # Non-null list of non-null strings
  createdAt: DateTime!
  updatedAt: DateTime!
  author: User!         # Nullable only if the author can be deleted
}
```

Nullability rules:
- Default to non-null (`!`) for fields that will always have a value
- Use nullable only when the field genuinely may be absent (optional relationship, lazy-loaded field)
- `[String!]!` — non-null list of non-null strings (most common for arrays)
- `[String]` — nullable list of nullable strings (almost never correct)

Naming conventions:
- Types: `PascalCase`
- Fields and arguments: `camelCase`
- Enum values: `SCREAMING_SNAKE_CASE`
- Queries: describe what is returned (`document`, `documents`, `searchDocuments`)
- Mutations: verb + noun (`createDocument`, `updateDocument`, `deleteDocument`)
- Subscriptions: `on` + event (`onDocumentCreated`, `onCommentAdded`)

### Queries

Design queries for the client's data needs, not the database schema:

```graphql
type Query {
  # Single resource — nullable (returns null if not found, not an error)
  document(id: UUID!): Document

  # Collection with filtering and pagination
  documents(
    filter: DocumentFilter
    pagination: PaginationInput
    orderBy: DocumentOrderBy
  ): DocumentConnection!

  # Search — separate from basic listing
  searchDocuments(query: String!, limit: Int = 10): [Document!]!
}

input DocumentFilter {
  tags: [String!]
  authorId: UUID
  createdAfter: DateTime
}

input PaginationInput {
  first: Int
  after: String    # cursor
  last: Int
  before: String   # cursor
}

type DocumentConnection {
  edges: [DocumentEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type DocumentEdge {
  node: Document!
  cursor: String!
}
```

Use cursor-based pagination (`Connection` pattern) for any collection that can grow unboundedly. Offset pagination becomes inconsistent when items are inserted or deleted between pages.

### Mutations

Mutations should return the mutated object plus any affected related objects:

```graphql
type Mutation {
  createDocument(input: CreateDocumentInput!): CreateDocumentPayload!
  updateDocument(id: UUID!, input: UpdateDocumentInput!): UpdateDocumentPayload!
  deleteDocument(id: UUID!): DeleteDocumentPayload!
}

input CreateDocumentInput {
  title: String!
  content: String!
  tags: [String!]
}

# Mutation payloads — return document + errors
type CreateDocumentPayload {
  document: Document       # null on failure
  errors: [UserError!]!    # empty on success
}

type UserError {
  field: String            # null for non-field errors
  message: String!
  code: String!            # machine-readable: VALIDATION_ERROR, NOT_FOUND
}
```

Return union types for operations that can fail in multiple ways:

```graphql
type Mutation {
  publishDocument(id: UUID!): PublishDocumentResult!
}

union PublishDocumentResult = Document | DocumentNotFoundError | DocumentAlreadyPublishedError | PermissionDeniedError

type DocumentNotFoundError {
  id: UUID!
  message: String!
}
```

## Resolvers

### Resolver Structure

Keep resolvers thin — they are a translation layer, not business logic:

```typescript
// TypeScript with Apollo Server or Pothos
const resolvers = {
  Query: {
    document: async (_, { id }, { dataSources, user }) => {
      // 1. Authorization check
      if (!user) throw new AuthenticationError('Not authenticated');

      // 2. Delegate to service
      const doc = await dataSources.documentService.findById(id);

      // 3. Object-level authorization
      if (doc && !canRead(user, doc)) throw new ForbiddenError('Access denied');

      // 4. Return null for not-found (GraphQL handles this gracefully)
      return doc ?? null;
    },
  },

  Document: {
    // Field-level resolver — only runs when the field is requested
    author: async (document, _, { dataSources }) => {
      return dataSources.userLoader.load(document.authorId); // DataLoader!
    },
  },
};
```

### N+1 Problem — DataLoader

The N+1 problem: a query for 10 documents that each have an `author` field results in 1 query for documents + 10 queries for authors = 11 queries. This is the most common GraphQL performance issue.

**Solution: DataLoader** — batches and caches loads within a single request:

```typescript
import DataLoader from 'dataloader';

// Create per-request (never share across requests — that leaks data)
function createLoaders(db: Database) {
  return {
    userLoader: new DataLoader<string, User>(async (userIds) => {
      // Called once with all requested IDs batched
      const users = await db.query(
        'SELECT * FROM users WHERE id = ANY($1)',
        [userIds],
      );
      // Must return results in same order as input IDs
      const userMap = new Map(users.map(u => [u.id, u]));
      return userIds.map(id => userMap.get(id) ?? new Error(`User ${id} not found`));
    }),

    documentsByTagLoader: new DataLoader<string, Document[]>(async (tags) => {
      const docs = await db.query(
        'SELECT * FROM documents WHERE tags && $1',
        [tags],
      );
      const grouped = groupBy(docs, doc => doc.tags);
      return tags.map(tag => grouped[tag] ?? []);
    }),
  };
}

// Attach to context (new loaders per request)
const server = new ApolloServer({
  context: ({ req }) => ({
    loaders: createLoaders(db),
    user: getUserFromRequest(req),
  }),
});
```

Rules for DataLoader:
- Create new loader instances per request — never share across requests
- Return results in the same order as the input array (DataLoader requires this)
- Return `Error` instances for individual load failures, not throw
- Use the loader cache within a request to avoid duplicate loads of the same ID

### Authorization in Resolvers

Authorization must be checked at both query level and field level where appropriate:

```typescript
// Query-level: can the user access this resource at all?
Query: {
  document: async (_, { id }, { user, loaders }) => {
    if (!user) throw new AuthenticationError();
    const doc = await loaders.documentLoader.load(id);
    if (doc && doc.ownerId !== user.id && !user.isAdmin) {
      throw new ForbiddenError();
    }
    return doc;
  },
},

// Field-level: can the user see this specific field?
Document: {
  privateNotes: (document, _, { user }) => {
    if (user.id !== document.ownerId && !user.isAdmin) return null;
    return document.privateNotes;
  },
},
```

**Never rely on the client not requesting a field** — always enforce authorization server-side.

## Error Handling

Use the two-error pattern:
- **System errors** (unexpected server failures) → throw `ApolloError` subclasses → appear in `errors` array
- **User errors** (validation, business rule failures) → return as `errors` field in mutation payload → not in top-level `errors`

```typescript
import { ApolloError, UserInputError, AuthenticationError, ForbiddenError } from 'apollo-server';

// System errors — unexpected failures
throw new ApolloError('Database unavailable', 'INTERNAL_SERVER_ERROR');

// User input error — appears in top-level errors[] with GRAPHQL_VALIDATION_FAILED
throw new UserInputError('Invalid email format', {
  invalidArgs: { email: 'must be a valid email' },
});

// Mutation payload user errors — returned in the payload, not thrown
return {
  document: null,
  errors: [{ field: 'title', message: 'Title is too long', code: 'VALIDATION_ERROR' }],
};
```

## Subscriptions

Subscriptions require a pub/sub mechanism — do not use in-memory pub/sub in multi-instance deployments:

```typescript
import { PubSub } from 'graphql-subscriptions';
// For production: use graphql-redis-subscriptions with Redis

const pubsub = new PubSub();

const resolvers = {
  Subscription: {
    documentUpdated: {
      subscribe: (_, { documentId }, { user }) => {
        if (!user) throw new AuthenticationError();
        // Filter to only emit events for the subscribed document
        return pubsub.asyncIterator(`DOCUMENT_UPDATED:${documentId}`);
      },
    },
  },

  Mutation: {
    updateDocument: async (_, { id, input }, { dataSources }) => {
      const doc = await dataSources.documentService.update(id, input);
      // Publish after successful mutation
      await pubsub.publish(`DOCUMENT_UPDATED:${doc.id}`, { documentUpdated: doc });
      return { document: doc, errors: [] };
    },
  },
};
```

For multi-instance production: use `graphql-redis-subscriptions` with Redis pub/sub.

## Security

- **Query depth limiting**: prevent deeply nested queries that can cause exponential resolver calls
- **Query complexity limiting**: assign cost to fields, reject queries over threshold
- **Introspection**: disable in production for external APIs
- **Rate limiting**: apply per-user, not just per-IP (users can send expensive queries)

```typescript
import depthLimit from 'graphql-depth-limit';
import { createComplexityLimitRule } from 'graphql-validation-complexity';

const server = new ApolloServer({
  validationRules: [
    depthLimit(7),                    // reject queries deeper than 7 levels
    createComplexityLimitRule(1000),  // reject queries with complexity > 1000
  ],
  introspection: process.env.NODE_ENV !== 'production',
});
```

## GraphQL Review Checklist

```
Schema:
- [ ] Non-null (!) used for fields that are always present
- [ ] Cursor-based pagination for unbounded collections
- [ ] Mutations return payload with document + errors[]
- [ ] Enums in SCREAMING_SNAKE_CASE

Resolvers:
- [ ] Authorization checked in every resolver accessing user data
- [ ] N+1 problem addressed with DataLoader for all relationship fields
- [ ] DataLoader instances created per-request, not shared
- [ ] Business logic in service layer, not resolvers

Security:
- [ ] Query depth limiting configured
- [ ] Query complexity limiting configured
- [ ] Introspection disabled in production

Subscriptions:
- [ ] Redis pub/sub used (not in-memory) for multi-instance deployments
- [ ] Subscription-level authorization implemented
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| `author: User` resolved with a DB query per document | DataLoader for all relationship fields |
| Shared DataLoader instance across requests | New DataLoader per request (fresh per context) |
| Authorization only at the query resolver | Also enforce at field level for sensitive fields |
| Introspection enabled in production | `introspection: process.env.NODE_ENV !== 'production'` |
| No query depth or complexity limits | `depthLimit` + `createComplexityLimitRule` |
| Throwing errors for user-facing validation failures | Return errors in mutation payload |
| Offset pagination for large collections | Cursor-based Connection pattern |
| `JSON` scalar everywhere | Typed objects — use `JSON` only for truly unstructured data |

## Connected Skills

- `sql-and-database` — DataLoader batching translates to `WHERE id = ANY($1)` query pattern
- `security-hardening` — GraphQL authorization, introspection, and DoS protection
- `observability` — log query complexity, resolver timing, and N+1 detection
- `nestjs` — `@nestjs/graphql` with code-first schema generation
- `error-handling` — system vs user error distinction maps directly to GraphQL error handling
