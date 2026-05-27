---
name: express
description: Express.js implementation and review patterns for production TypeScript APIs. Use when Codex needs to build, refactor, debug, or review Express applications, routers, controllers, services, DTO/schema validation, middleware, authentication, authorization, error handling, file uploads, background jobs, database access, or API test coverage.
---

# Express Implementation Patterns

Use this skill to keep Express applications modular, type-safe, secure, testable, and boring in the best possible way.

Express is intentionally minimal. That is not permission to put the entire backend inside `app.ts` and call it architecture.

## Delivery Workflow

Use the checklist below and track progress:

```text
Express progress:
- [ ] Step 1: Discover app structure, routing conventions, and middleware order
- [ ] Step 2: Model request schemas, validation, and authorization boundaries
- [ ] Step 3: Implement router/controller/service/repository responsibilities cleanly
- [ ] Step 4: Handle errors, async flow, side effects, and infrastructure concerns explicitly
- [ ] Step 5: Verify tests, security, observability, and production runtime behavior
```

## Architecture Rules

* Keep `app.ts` focused on app composition only: middleware, routes, error handlers, and infrastructure wiring.
* Keep `server.ts` focused on process startup: config loading, port binding, graceful shutdown, and fatal error handling.
* Keep routers thin: route definitions, middleware composition, controller binding.
* Keep controllers thin: parse validated request data, delegate to services, map responses.
* Put business logic in services or domain collaborators, not routers, middleware, or controllers.
* Isolate database access behind repositories/data-access modules.
* Keep validation, authorization, persistence, mapping, and side effects separate.
* Avoid circular imports by organizing dependencies inward: route → controller → service → repository.
* Reuse project-standard config, logging, validation, and error patterns before introducing new abstractions.

Recommended baseline structure:

```text
src/
  app.ts
  server.ts
  config/
    env.ts
  modules/
    users/
      users.routes.ts
      users.controller.ts
      users.service.ts
      users.repository.ts
      users.schemas.ts
      users.types.ts
      users.test.ts
  middleware/
    auth.middleware.ts
    request-id.middleware.ts
    validate.middleware.ts
  errors/
    app-error.ts
    error-handler.ts
  db/
    client.ts
  shared/
    async-handler.ts
    logger.ts
```

## App Composition

Keep middleware order explicit. Order bugs in Express are not charming, they are production incidents wearing a fake mustache.

Recommended order:

```typescript
export function createApp(): express.Express {
  const app = express();

  app.disable('x-powered-by');

  app.use(requestIdMiddleware);
  app.use(helmet());
  app.use(cors(corsOptions));
  app.use(express.json({ limit: '1mb' }));
  app.use(express.urlencoded({ extended: false, limit: '1mb' }));

  app.get('/health', healthController);

  app.use('/api/users', usersRouter);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
```

Rules:

* Register body parsers before routes that need parsed bodies.
* Register routers before `notFoundHandler`.
* Register the global error handler last.
* Disable `x-powered-by`.
* Set request body limits explicitly.
* Do not start listening from `app.ts`; export an app factory for tests.

## Router, Controller, Service, Repository Boundaries

Use the boundary model below unless the project already has a clear equivalent.

```text
HTTP request
  -> middleware: auth, validation, rate limits, upload parsing
  -> router: route definitions and middleware composition
  -> controller: request/response mapping
  -> service: use case orchestration and business rules
  -> repository: database queries
  -> external clients: storage, queues, APIs
```

Router example:

```typescript
import { Router } from 'express';
import { validateRequest } from '../../middleware/validate.middleware';
import { createUserSchema } from './users.schemas';
import { usersController } from './users.controller';

export const usersRouter = Router();

usersRouter.post(
  '/',
  validateRequest({ body: createUserSchema }),
  usersController.create,
);
```

Controller example:

```typescript
import type { Request, Response } from 'express';
import { asyncHandler } from '../../shared/async-handler';
import { usersService } from './users.service';
import type { CreateUserInput } from './users.schemas';

export const usersController = {
  create: asyncHandler(async (req: Request<unknown, unknown, CreateUserInput>, res: Response) => {
    const user = await usersService.create(req.body);

    res.status(201).json({ data: user });
  }),
};
```

Service example:

```typescript
import { ConflictError } from '../../errors/app-error';
import { usersRepository } from './users.repository';
import type { CreateUserInput } from './users.schemas';

export const usersService = {
  async create(input: CreateUserInput) {
    const existingUser = await usersRepository.findByEmail(input.email);

    if (existingUser) {
      throw new ConflictError('User with this email already exists');
    }

    return usersRepository.create(input);
  },
};
```

## TypeScript Rules

* Use strict TypeScript.
* Avoid `any`; prefer `unknown` plus narrowing.
* Type request params, body, query, and response DTOs.
* Derive input types from validation schemas when possible.
* Do not rely on `Request` generics alone as validation. TypeScript does not protect runtime input, because apparently reality exists.
* Do not mutate `req` with custom properties unless Express types are augmented safely.

Safe request augmentation:

```typescript
declare global {
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
      requestId?: string;
    }
  }
}
```

Rules:

* Keep request augmentation minimal.
* Never attach sensitive tokens, raw passwords, or unfiltered user records to `req`.
* Prefer `req.user` with a safe identity payload: `id`, `role`, `permissions`.

## DTOs, Validation, and Sanitization

Validate external input at the HTTP boundary.

Recommended with Zod:

```typescript
import type { NextFunction, Request, Response } from 'express';
import type { ZodSchema } from 'zod';
import { BadRequestError } from '../errors/app-error';

type RequestSchemas = {
  body?: ZodSchema;
  params?: ZodSchema;
  query?: ZodSchema;
};

export function validateRequest(schemas: RequestSchemas) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    try {
      if (schemas.body) req.body = schemas.body.parse(req.body);
      if (schemas.params) req.params = schemas.params.parse(req.params);
      if (schemas.query) req.query = schemas.query.parse(req.query) as Request['query'];

      next();
    } catch (error) {
      next(BadRequestError.fromValidationError(error));
    }
  };
}
```

Schema example:

```typescript
import { z } from 'zod';

export const createUserSchema = z.object({
  email: z.string().trim().email().max(255),
  name: z.string().trim().min(1).max(100),
  password: z.string().min(12).max(128),
});

export type CreateUserInput = z.infer<typeof createUserSchema>;
```

Validation rules:

* Validate `body`, `params`, `query`, headers, cookies, and uploaded file metadata where relevant.
* Trim and normalize input intentionally.
* Reject unknown fields for sensitive operations when supported by the schema strategy.
* Keep schemas close to module boundaries.
* Do not trust client-provided IDs, roles, prices, ownership flags, or timestamps.
* Do not use validation libraries as business-rule containers.

## Authentication and Authorization

Separate authentication from authorization.

```text
Authentication: Who is this user?
Authorization: Is this user allowed to perform this action on this resource?
```

Rules:

* Authentication middleware should only verify credentials and attach a safe identity payload.
* Authorization middleware/service should check roles, permissions, ownership, or policy rules.
* Resource ownership checks usually belong in services or policy helpers, not generic auth middleware.
* Never trust user IDs from params/body for ownership without checking against authenticated identity.
* Use constant-time comparisons for sensitive token checks when applicable.
* Keep secrets in environment/config, never hardcoded.

Auth middleware pattern:

```typescript
import type { NextFunction, Request, Response } from 'express';
import { UnauthorizedError } from '../errors/app-error';
import { verifyAccessToken } from '../shared/jwt';

export async function authMiddleware(
  req: Request,
  _res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const header = req.header('authorization');
    const token = header?.startsWith('Bearer ') ? header.slice('Bearer '.length) : undefined;

    if (!token) {
      throw new UnauthorizedError('Missing access token');
    }

    req.user = await verifyAccessToken(token);
    next();
  } catch (error) {
    next(error instanceof UnauthorizedError ? error : new UnauthorizedError('Invalid access token'));
  }
}
```

Authorization pattern:

```typescript
import type { NextFunction, Request, Response } from 'express';
import { ForbiddenError, UnauthorizedError } from '../errors/app-error';

export function requireRole(role: string) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.user) {
      next(new UnauthorizedError('Authentication required'));
      return;
    }

    if (req.user.role !== role) {
      next(new ForbiddenError('Insufficient permissions'));
      return;
    }

    next();
  };
}
```

## Async Error Handling

Express 4 does not automatically catch rejected promises from async route handlers. Use a wrapper unless the project is on Express 5 and has confirmed behavior through tests.

```typescript
import type { NextFunction, Request, RequestHandler, Response } from 'express';

export function asyncHandler(handler: RequestHandler): RequestHandler {
  return (req: Request, res: Response, next: NextFunction): void => {
    Promise.resolve(handler(req, res, next)).catch(next);
  };
}
```

Rules:

* Never leave async controller errors unwrapped in Express 4.
* Do not scatter `try/catch` in every controller just to call `next(error)`.
* Use typed domain/application errors and map them in one error handler.
* Avoid `catch` blocks that log and continue after real failures.
* Preserve useful context in logs without leaking sensitive data to clients.

## Error Model and Global Error Handler

Use explicit application errors.

```typescript
export class AppError extends Error {
  constructor(
    message: string,
    readonly statusCode: number,
    readonly code: string,
    readonly details?: unknown,
  ) {
    super(message);
    this.name = new.target.name;
  }
}

export class BadRequestError extends AppError {
  constructor(message = 'Bad request', details?: unknown) {
    super(message, 400, 'BAD_REQUEST', details);
  }

  static fromValidationError(error: unknown): BadRequestError {
    return new BadRequestError('Validation failed', error);
  }
}

export class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized') {
    super(message, 401, 'UNAUTHORIZED');
  }
}

export class ForbiddenError extends AppError {
  constructor(message = 'Forbidden') {
    super(message, 403, 'FORBIDDEN');
  }
}

export class NotFoundError extends AppError {
  constructor(message = 'Resource not found') {
    super(message, 404, 'NOT_FOUND');
  }
}

export class ConflictError extends AppError {
  constructor(message = 'Conflict') {
    super(message, 409, 'CONFLICT');
  }
}
```

Error handler:

```typescript
import type { ErrorRequestHandler } from 'express';
import { AppError } from './app-error';
import { logger } from '../shared/logger';

export const errorHandler: ErrorRequestHandler = (error, req, res, _next) => {
  const requestId = req.requestId;

  if (error instanceof AppError) {
    logger.warn({ error, requestId }, 'Handled request error');

    res.status(error.statusCode).json({
      error: {
        code: error.code,
        message: error.message,
        requestId,
      },
    });
    return;
  }

  logger.error({ error, requestId }, 'Unhandled request error');

  res.status(500).json({
    error: {
      code: 'INTERNAL_SERVER_ERROR',
      message: 'Internal server error',
      requestId,
    },
  });
};
```

Rules:

* Return predictable error shapes.
* Do not expose stack traces, SQL errors, ORM internals, raw validation dumps, or dependency error messages to clients.
* Include `requestId` in responses and logs.
* Log handled client errors at `warn` or lower depending on project convention.
* Log unexpected server errors at `error`.

## Configuration and Environment

Validate environment variables at startup.

```typescript
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  CORS_ORIGINS: z.string().optional(),
});

export const env = envSchema.parse(process.env);
```

Rules:

* Fail fast on invalid config.
* Keep config parsing centralized.
* Do not read `process.env` throughout the codebase.
* Do not log secrets.
* Parse booleans and numbers explicitly.
* Avoid permissive defaults in production.

## CORS, Cookies, and Headers

Rules:

* Do not use `origin: '*'` with credentials.
* Use an allowlist for production CORS origins.
* Set secure cookie options in production.
* Use `helmet` unless the project has a specific reason not to.
* Set body size limits for JSON and URL-encoded payloads.
* Add rate limits to auth, password reset, public write, and expensive endpoints.

CORS pattern:

```typescript
import type { CorsOptions } from 'cors';
import { env } from './env';

const allowedOrigins = env.CORS_ORIGINS?.split(',').map((origin) => origin.trim()) ?? [];

export const corsOptions: CorsOptions = {
  origin(origin, callback) {
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
      return;
    }

    callback(new Error('Origin not allowed by CORS'));
  },
  credentials: true,
};
```

## Data Access and Transactions

Rules:

* Keep SQL/ORM query logic out of controllers.
* Use repositories or query modules for persistence.
* Make transactions explicit when a use case spans multiple writes.
* Avoid N+1 queries; batch or join intentionally.
* Use pagination for list endpoints.
* Validate sorting/filtering fields against allowlists.
* Never concatenate raw user input into SQL.
* Keep database errors mapped to application errors at service/repository boundaries.

Pagination input pattern:

```typescript
import { z } from 'zod';

export const paginationQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});
```

## File Uploads

Rules:

* Validate file size, MIME type, extension, and content when possible.
* Do not trust `originalname`.
* Generate server-side object keys.
* Store files outside the web root unless intentionally public.
* Virus scan where risk requires it.
* Keep upload parsing middleware route-scoped, not global.
* Clean up partially uploaded files on failure.

## Background Jobs and Side Effects

Rules:

* Do not perform slow side effects inline if they can be queued.
* Use idempotency keys for retryable operations.
* Make external API timeouts explicit.
* Log side effects with correlation/request IDs.
* Keep queue producers visible in service orchestration.
* Never hide critical side effect failure behind a silent `catch`.

## Observability

Rules:

* Use structured logging.
* Add request IDs and propagate them through logs.
* Log route, method, status code, duration, and request ID.
* Redact tokens, cookies, passwords, and secrets.
* Add health checks for app liveness and dependency readiness.
* Keep metrics around request latency, error rates, and critical external dependencies when the project supports it.

Request ID middleware:

```typescript
import crypto from 'node:crypto';
import type { NextFunction, Request, Response } from 'express';

export function requestIdMiddleware(req: Request, res: Response, next: NextFunction): void {
  const incomingRequestId = req.header('x-request-id');
  const requestId = incomingRequestId && incomingRequestId.length <= 128
    ? incomingRequestId
    : crypto.randomUUID();

  req.requestId = requestId;
  res.setHeader('x-request-id', requestId);

  next();
}
```

## Graceful Startup and Shutdown

`server.ts` should own runtime lifecycle.

```typescript
import http from 'node:http';
import { createApp } from './app';
import { env } from './config/env';
import { logger } from './shared/logger';

const app = createApp();
const server = http.createServer(app);

server.listen(env.PORT, () => {
  logger.info({ port: env.PORT }, 'HTTP server started');
});

function shutdown(signal: NodeJS.Signals): void {
  logger.info({ signal }, 'Shutting down HTTP server');

  server.close((error) => {
    if (error) {
      logger.error({ error }, 'HTTP server shutdown failed');
      process.exit(1);
    }

    process.exit(0);
  });
}

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
```

Rules:

* Keep app creation testable.
* Close the HTTP server on shutdown.
* Close DB, Redis, queue, and external clients where used.
* Handle unhandled fatal startup errors explicitly.

## Testing Checklist

```text
HTTP/API:
- [ ] Request validation, status codes, and response shapes are covered
- [ ] Auth and authorization branches are covered where critical
- [ ] Error mapping is asserted explicitly
- [ ] Not-found route behavior is covered
- [ ] Body size / malformed JSON behavior is considered for public APIs

Service layer:
- [ ] Core business rules are tested directly
- [ ] Side effects and integration boundaries are isolated or mocked intentionally
- [ ] Duplicate/conflict cases are tested
- [ ] Authorization/ownership decisions are tested where they live

Data access:
- [ ] Queries are covered where complex or risky
- [ ] Transactions are tested for rollback behavior
- [ ] Pagination/filter/sort behavior is covered

Design:
- [ ] `app.ts` remains composition-only
- [ ] Routers remain route/middleware-only
- [ ] Controllers remain thin
- [ ] Services own use cases
- [ ] Repositories own persistence details

Runtime:
- [ ] Environment validation fails fast on invalid config
- [ ] Global error handler is registered last
- [ ] Async route errors reach the global error handler
- [ ] Graceful shutdown closes external resources
```

Supertest pattern:

```typescript
import request from 'supertest';
import { createApp } from '../../app';

const app = createApp();

describe('POST /api/users', () => {
  it('returns 400 for invalid body', async () => {
    await request(app)
      .post('/api/users')
      .send({ email: 'invalid' })
      .expect(400)
      .expect((response) => {
        expect(response.body.error.code).toBe('BAD_REQUEST');
      });
  });
});
```

Async error smoke test:

```typescript
it('routes async controller failures to the global error handler', async () => {
  const app = createApp();

  await request(app)
    .get('/api/test/throws-async')
    .expect(500)
    .expect((response) => {
      expect(response.body.error.code).toBe('INTERNAL_SERVER_ERROR');
    });
});
```

Use this pattern whenever:

* controllers are converted to async functions
* route wrappers/middleware are refactored
* error handler shape changes
* Express major version changes

## Review Checklist

```text
Security:
- [ ] Input is validated at route boundaries
- [ ] Auth and authorization are separate
- [ ] Sensitive fields are never returned or logged
- [ ] CORS, cookies, headers, and body limits are production-safe
- [ ] SQL/user input is parameterized or safely handled by ORM/query builder

Architecture:
- [ ] App/server composition is separated
- [ ] Router/controller/service/repository boundaries are respected
- [ ] No business logic lives in middleware unless it is truly cross-cutting
- [ ] No route imports infrastructure clients directly unless project convention allows it
- [ ] No circular imports or duplicate singleton construction

Errors:
- [ ] Async errors are caught
- [ ] Error responses are predictable
- [ ] Internal error details are not exposed
- [ ] Logs include request context and redact sensitive data

Performance:
- [ ] List endpoints use pagination
- [ ] Expensive endpoints have caching/rate limits where needed
- [ ] External calls have timeouts
- [ ] Query patterns avoid obvious N+1 behavior

Testing:
- [ ] API contract tests cover critical routes
- [ ] Service tests cover business rules
- [ ] Error branches are tested
- [ ] Test app does not bind a real network port
```

## Anti-Patterns to Avoid

| Anti-Pattern                                       | Instead Do                                                             |
|----------------------------------------------------|------------------------------------------------------------------------|
| Entire app implemented in `app.ts`                 | Compose app in `app.ts`, move routes/controllers/services into modules |
| Starting server inside app factory                 | Export `createApp()` and start in `server.ts`                          |
| Fat router with business logic                     | Route only wires middleware and controller                             |
| Fat controller with persistence and business rules | Delegate to services and repositories                                  |
| Validation inside service methods only             | Validate at HTTP boundary, keep service checks for business rules      |
| Trusting `req.body` because TypeScript says so     | Runtime validation with Zod/Yup/Joi/class-validator                    |
| Async controllers without wrapper in Express 4     | Use `asyncHandler` or migrate and test Express 5 behavior              |
| Returning raw ORM entities                         | Map to response DTOs and remove sensitive fields                       |
| Logging full request bodies                        | Log safe metadata only, redact sensitive fields                        |
| `cors({ origin: '*', credentials: true })`         | Use production allowlist                                               |
| No body size limit                                 | Set explicit JSON/urlencoded limits                                    |
| Global upload middleware                           | Use route-scoped upload middleware                                     |
| Dynamic SQL from request strings                   | Parameterize and allowlist filter/sort fields                          |
| Catching errors and returning `null`               | Throw explicit application errors                                      |
| Swallowing external API failures                   | Use timeouts, retries where appropriate, and explicit error mapping    |
| Tests binding real ports                           | Use Supertest against app instance                                     |
| No graceful shutdown                               | Close server and external resources on `SIGTERM` / `SIGINT`            |

## Express 4 vs. Express 5 Notes

* Express 4 requires explicit async error forwarding with wrappers or `next(error)`.
* Express 5 improves promise rejection forwarding but confirms a project version before relying on it.
* When upgrading Express major versions, run API tests and specifically verify error middleware behavior.
* Avoid mixing assumptions from both versions in the same codebase.

## Connected Skills

* `technical-context-discovery` - follow established Express and repo conventions before editing
* `sql-and-database` - use when persistence, migrations, indexes, transactions, or query design are involved
* `code-review` - validate architecture, security, performance, and testing quality
* `docker` - use when runtime packaging, Compose, Dockerfile, or container health checks are involved
* `error-handling` - use for retry strategy, typed error mapping, and external dependency failures
* `observability` - use for logging, metrics, tracing, request IDs, and health checks
* `test-strategy` - use before adding or refactoring critical API behavior
