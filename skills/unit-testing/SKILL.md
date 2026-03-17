---
name: unit-testing
description: Unit and integration testing patterns for TypeScript/JavaScript using Vitest and Jest. Covers test structure, mocking strategies, testing async code, React Testing Library for component tests, and coverage configuration. Use when writing or reviewing unit tests, integration tests, or component tests in a TypeScript/JavaScript/React codebase.
---

# Unit Testing (TypeScript / JavaScript)

This skill covers unit and component testing in the TypeScript/JavaScript ecosystem. It is the counterpart to `e2e-testing` (Playwright, full browser) and `python-testing` (pytest).

## When to Use

- Writing unit tests for service logic, utility functions, or domain models
- Writing component tests with React Testing Library
- Reviewing test code for quality, coverage gaps, or brittle patterns
- Setting up a test framework from scratch in a new project
- Debugging a test that passes locally but fails in CI

## When NOT to Use

- E2E tests covering full user journeys in a browser — use `e2e-testing`
- Python tests — use `python-testing`
- Visual regression testing — different toolchain (Chromatic, Percy)

## Framework Choice

**Vitest** — preferred for new projects (especially Vite, Next.js App Router, Turborepo):
- Same config as Vite (no separate babel/transform setup)
- Faster than Jest in watch mode
- Native ESM support
- Drop-in Jest API compatibility

**Jest** — preferred when:
- Existing project already uses Jest
- CRA, some NestJS setups, older React Native

This skill uses Vitest syntax. Jest equivalents are identical except for `vi.*` → `jest.*`.

## Test Structure

```
src/
├── services/
│   ├── document.service.ts
│   └── document.service.test.ts    # co-located with source
├── components/
│   ├── DocumentCard.tsx
│   └── DocumentCard.test.tsx
└── utils/
    ├── slug.ts
    └── slug.test.ts
```

Co-location (test next to source) is preferred over a separate `__tests__` directory — easier to find, easier to maintain.

Test file naming: `*.test.ts` or `*.spec.ts` — choose one convention and apply it consistently.

## Test Anatomy

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { DocumentService } from './document.service';

describe('DocumentService', () => {
  let service: DocumentService;

  beforeEach(() => {
    // Fresh instance per test — no shared state between tests
    service = new DocumentService(mockDb);
  });

  describe('create', () => {
    it('returns created document with generated id', async () => {
      // Arrange
      const input = { title: 'Test', content: 'Hello' };

      // Act
      const result = await service.create(input);

      // Assert
      expect(result.id).toBeDefined();
      expect(result.title).toBe('Test');
      expect(result.content).toBe('Hello');
    });

    it('throws ValidationError when title is empty', async () => {
      await expect(service.create({ title: '', content: 'x' }))
        .rejects.toThrow(ValidationError);
    });
  });
});
```

Test naming rules:
- `it('does X when Y')` — describes behavior, not implementation
- `it('returns null when document is not found')` not `it('test findById null case')`
- Use `describe` to group by unit and by scenario

`beforeEach` vs `beforeAll`:
- `beforeEach` — for anything with mutable state (services, mock reset)
- `beforeAll` — for expensive setup that is truly shared and stateless (DB connection, large fixture)

## Mocking

### Module Mocks

```typescript
// Mock an entire module
vi.mock('../lib/email', () => ({
  sendEmail: vi.fn().mockResolvedValue({ id: 'msg_123' }),
}));

// Mock with factory (for classes)
vi.mock('../repositories/document.repository', () => ({
  DocumentRepository: vi.fn().mockImplementation(() => ({
    findById: vi.fn(),
    create: vi.fn(),
    update: vi.fn(),
  })),
}));
```

### Spy and Mock Functions

```typescript
import { vi, expect } from 'vitest';

const mockFn = vi.fn();
mockFn.mockReturnValue(42);                       // sync return
mockFn.mockResolvedValue({ id: '1' });            // async return
mockFn.mockRejectedValue(new Error('failed'));    // async throw
mockFn.mockReturnValueOnce(1).mockReturnValue(2); // different values per call

// Assertions on calls
expect(mockFn).toHaveBeenCalledTimes(1);
expect(mockFn).toHaveBeenCalledWith('arg1', expect.objectContaining({ id: '1' }));
expect(mockFn).not.toHaveBeenCalled();

// Reset between tests
vi.clearAllMocks();   // in afterEach, or use clearMocks: true in config
```

### Spying Without Replacing

```typescript
// Spy on a method but keep original implementation
const spy = vi.spyOn(documentService, 'findById');
spy.mockResolvedValueOnce(mockDocument); // override for one call

// After test
spy.mockRestore();
```

### What to Mock vs What Not to Mock

Mock:
- External API calls (HTTP clients, third-party SDKs)
- Database layer when testing service logic
- Time (`vi.useFakeTimers()`) when testing time-dependent behavior
- File system for tests that should not touch disk

Do not mock:
- The unit under test
- Pure utility functions without side effects
- Value objects and domain models
- Your own service interfaces when integration is the point

```typescript
// Use real implementations where possible
import { slugify } from '../utils/slug'; // pure function — no mock needed

// Mock at the I/O boundary — not at the service layer
vi.mock('../db/client', () => ({ db: mockPrismaClient }));
// NOT: vi.mock('./document.repository') — that removes the integration you want to test
```

## Testing Async Code

```typescript
// Async/await — most readable
it('loads document asynchronously', async () => {
  const doc = await service.findById('123');
  expect(doc.title).toBe('Test');
});

// Rejections
it('throws NotFoundError for missing document', async () => {
  await expect(service.findById('nonexistent')).rejects.toThrow(NotFoundError);
  // Or with message check:
  await expect(service.findById('nonexistent'))
    .rejects.toThrow('Document not found');
});

// Fake timers for debounce/throttle/setTimeout
it('debounces search after 300ms', async () => {
  vi.useFakeTimers();
  const search = vi.fn();
  const debounced = debounce(search, 300);

  debounced('a');
  debounced('b');
  expect(search).not.toHaveBeenCalled();

  vi.advanceTimersByTime(300);
  expect(search).toHaveBeenCalledOnce();
  expect(search).toHaveBeenCalledWith('b');

  vi.useRealTimers();
});
```

## React Component Testing

Use `@testing-library/react` — tests from the user's perspective, not implementation details:

```typescript
import { render, screen, userEvent } from '@testing-library/react';
import { DocumentCard } from './DocumentCard';

describe('DocumentCard', () => {
  it('displays document title and author', () => {
    render(<DocumentCard document={mockDocument} />);

    expect(screen.getByRole('heading', { name: 'Test Document' })).toBeInTheDocument();
    expect(screen.getByText('By Alice')).toBeInTheDocument();
  });

  it('calls onDelete when delete button is clicked', async () => {
    const onDelete = vi.fn();
    render(<DocumentCard document={mockDocument} onDelete={onDelete} />);

    await userEvent.click(screen.getByRole('button', { name: 'Delete' }));

    expect(onDelete).toHaveBeenCalledWith(mockDocument.id);
  });

  it('shows confirmation dialog before deleting', async () => {
    render(<DocumentCard document={mockDocument} onDelete={vi.fn()} />);

    await userEvent.click(screen.getByRole('button', { name: 'Delete' }));

    expect(screen.getByRole('dialog')).toBeInTheDocument();
    expect(screen.getByText(/are you sure/i)).toBeInTheDocument();
  });
});
```

Query priority (prefer `getByRole` — it tests accessibility too):
1. `getByRole` — accessible, tests semantic meaning
2. `getByLabelText` — for form elements
3. `getByPlaceholderText` — acceptable fallback for inputs
4. `getByText` — for non-interactive content
5. `getByTestId` — last resort only; `data-testid` couples test to implementation

Never query by: class name, CSS selector, element type.

`userEvent` vs `fireEvent`:
- `userEvent.click()` / `userEvent.type()` — simulates real user behavior (fires all events in sequence)
- `fireEvent.click()` — fires a single DOM event; use only when `userEvent` is insufficient

### Testing with Providers

```typescript
// Wrap components that need context providers
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

function renderWithProviders(ui: ReactElement) {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } }, // disable retries in tests
  });
  return render(
    <QueryClientProvider client={queryClient}>
      {ui}
    </QueryClientProvider>
  );
}
```

### Testing Custom Hooks

```typescript
import { renderHook, act } from '@testing-library/react';
import { useDocumentSearch } from './useDocumentSearch';

it('returns filtered results when query changes', async () => {
  const { result } = renderHook(() => useDocumentSearch());

  act(() => { result.current.setQuery('typescript'); });

  await waitFor(() => {
    expect(result.current.results).toHaveLength(3);
  });
});
```

## Vitest Configuration

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',           // for DOM/React tests
    globals: true,                  // no need to import describe/it/expect
    setupFiles: ['./src/test/setup.ts'],
    clearMocks: true,               // clear mock state between tests
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov'],
      exclude: ['**/*.test.ts', '**/*.d.ts', '**/index.ts'],
      thresholds: {
        lines: 80,
        functions: 80,
      },
    },
  },
});
```

`src/test/setup.ts`:
```typescript
import '@testing-library/jest-dom'; // adds toBeInTheDocument(), etc.
import { server } from './mocks/server'; // MSW for HTTP mocking

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

### Mock Service Worker (MSW) for HTTP

Use MSW for tests that involve HTTP calls — better than mocking `fetch` or `axios` directly:

```typescript
// src/test/mocks/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/api/documents', () => {
    return HttpResponse.json([{ id: '1', title: 'Test' }]);
  }),
  http.post('/api/documents', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json({ id: '2', ...body }, { status: 201 });
  }),
];

// Override in a specific test
server.use(
  http.get('/api/documents', () => {
    return new HttpResponse(null, { status: 500 });
  }),
);
```

## Coverage

Coverage is a tool for finding untested paths — not a quality metric:

```bash
vitest run --coverage
```

Interpret coverage output:
- **Line coverage** — was this line executed? Most basic measure.
- **Branch coverage** — were all branches of `if`/`ternary`/`switch` taken? More valuable.
- **Function coverage** — was this function called at all?

Do not write tests to hit coverage numbers. Write tests to document behavior. If coverage reveals a gap, ask: is this path important? If yes, write the test. If no, mark with `/* v8 ignore next */`.

## Unit Testing Checklist

```
Structure:
- [ ] Tests co-located with source files
- [ ] One describe block per unit, nested describes per scenario
- [ ] Fresh state per test (beforeEach, not beforeAll for mutable state)
- [ ] Test names describe behavior, not implementation

Mocking:
- [ ] Mocked at I/O boundary, not at service layer
- [ ] Mocks cleared between tests (clearMocks: true)
- [ ] No over-mocking — pure functions tested with real implementation

Assertions:
- [ ] Happy path covered
- [ ] Error paths covered (throw, reject, invalid input)
- [ ] Edge cases covered (empty, null, boundary values)

React (if applicable):
- [ ] getByRole used as primary query strategy
- [ ] userEvent used (not fireEvent) for user interactions
- [ ] Providers wrapped in a helper, not duplicated per test
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| `it('test1')` — meaningless test name | `it('returns null when document not found')` |
| Testing implementation (`toHaveBeenCalledWith(internalHelper)`) | Test behavior (output given input) |
| `getByTestId('submit-btn')` | `getByRole('button', { name: 'Submit' })` |
| `fireEvent.click()` for user actions | `userEvent.click()` — simulates real behavior |
| Shared mock state between tests | `clearMocks: true` + `beforeEach` for fresh instances |
| Mocking your own service layer | Mock at I/O boundary; test service integration |
| Coverage-driven test writing | Test important behaviors; coverage reveals gaps |

## Connected Skills

- `e2e-testing` — complements unit tests with full user journey coverage
- `python-testing` — equivalent skill for pytest / Python ecosystem
- `react` — React component patterns that affect testability (composition, prop injection)
- `nestjs` — NestJS testing utilities (`@nestjs/testing`, `TestingModule`)
- `ci-cd` — test coverage thresholds as quality gates in CI pipeline
