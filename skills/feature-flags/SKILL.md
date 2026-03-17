---
name: feature-flags
description: Feature flag implementation and lifecycle management patterns. Covers flag types, rollout strategies, kill switches, flag hygiene, and integration patterns for backend and frontend. Use when implementing gradual rollouts, A/B tests, kill switches for risky features, or managing flag lifecycle from creation to cleanup.
---

# Feature Flags

A feature flag is a conditional code path. Done well, it enables safe deployments, gradual rollouts, and instant rollback without a redeploy. Done poorly, it becomes permanent technical debt that nobody dares remove.

## When to Use

- Deploying a risky feature that needs a kill switch
- Rolling out a feature to a percentage of users before full release
- Running an A/B test or experiment
- Separating code deployment from feature activation (deploy dark, enable later)
- Giving ops teams the ability to disable a feature without a code deploy

## When NOT to Use

- Permanent configuration values that will never change — use environment variables
- Access control and authorization — use role/permission systems, not flags
- Features that have been fully rolled out and will never be turned off — remove the flag
- Debugging toggles that only a developer will ever use — use environment variables or log levels

## Flag Taxonomy

Choose the right flag type before implementing:

| Type | Purpose | Lifespan | Owner |
|---|---|---|---|
| **Kill switch** | Disable a feature instantly without deploy | Short — remove after feature is stable | Ops / on-call |
| **Release flag** | Gate a feature during rollout | Short — remove after full rollout | Engineering |
| **Experiment flag** | A/B test or multivariate experiment | Short — remove after analysis | Product |
| **Ops flag** | Tune behavior in production (timeouts, batch sizes) | Long-lived — can be permanent | Ops |
| **Permission flag** | Enable feature for specific users/plans | Long-lived — tied to business model | Product |

**Most flags should be short-lived.** Long-lived flags are acceptable only for ops and permission flags. A release flag that is still in the codebase 3 months after full rollout is flag debt.

## Core Principles

### Flags are Not Free

Every flag adds a branch in the code. Every branch adds cognitive load. Every flag has a removal cost. The answer to "should we flag this?" is not automatically yes — define a flag lifecycle at creation time.

### Default to Off for New Features

New feature flags default to `false` in all environments unless the feature is a kill switch for an existing behavior. Defaulting to `true` means a flag outage enables the feature — the opposite of a kill switch.

### Flags are Infrastructure, Not Application Logic

The flag evaluation mechanism (client, SDK, API call) must be reliable and fast. If the flag service is down, fail open (return the default) — never fail the request because a flag cannot be evaluated.

## Flag Lifecycle

Every flag must have a defined lifecycle at creation:

```markdown
## Flag: enable-new-document-editor
- Type: Release flag
- Created: 2025-03-15
- Owner: @jakub
- Rollout plan: 5% → 25% → 100% over 2 weeks
- Removal date: 2025-04-15 (or after 100% rollout + 1 week stable)
- Removal issue: [link to cleanup ticket]
```

Lifecycle stages:
1. **Created** — flag defined, feature behind flag, deployed to production (feature off)
2. **Ramping** — gradually increasing rollout percentage
3. **Full rollout** — 100% of users, monitoring for issues
4. **Cleanup** — remove flag and dead code path, ship as a cleanup PR

A flag that never reaches cleanup is permanently merged into the codebase — it is no longer a flag, it is a permanent branch that makes the code harder to read.

## Implementation Patterns

### Minimal Abstraction (No External Service)

For simple kill switches and early-stage projects:

```typescript
// flags.ts — single source of truth
export const Flags = {
  enableNewDocumentEditor: process.env.ENABLE_NEW_DOCUMENT_EDITOR === 'true',
  enableAiSearch: process.env.ENABLE_AI_SEARCH === 'true',
  maxUploadSizeMb: parseInt(process.env.MAX_UPLOAD_SIZE_MB ?? '10'),
} as const;

// Usage
if (Flags.enableNewDocumentEditor) {
  return <NewEditor />;
}
return <LegacyEditor />;
```

Limitation: requires redeploy to change. Acceptable for initial kill switches, not for percentage rollouts.

### Percentage Rollout (Without External Service)

```typescript
function isEnabled(flagName: string, userId: string, percentage: number): boolean {
  if (percentage >= 100) return true;
  if (percentage <= 0) return false;
  // Stable hash — same user always gets same result
  const hash = murmurhash3(`${flagName}:${userId}`) % 100;
  return hash < percentage;
}
```

User always gets the same experience (sticky bucketing by `userId`). Never use `Math.random()` — it would flip on every page load.

### External Flag Service (OpenFeature Standard)

Use [OpenFeature](https://openfeature.dev/) — vendor-neutral SDK that works with any backend (Unleash, LaunchDarkly, Flagsmith, GrowthBook, ConfigCat):

```typescript
import { OpenFeature } from '@openfeature/server-sdk';

// Initialize once at startup
const client = OpenFeature.getClient();

// Evaluate a flag with context
const enabled = await client.getBooleanValue(
  'enable-new-document-editor',
  false,               // default value if flag service is unavailable
  {
    targetingKey: userId,
    plan: user.plan,
    region: user.region,
  },
);
```

Context fields for targeting rules:
- `targetingKey` — stable user ID or session ID for percentage rollouts
- Any attribute needed for targeting rules (plan, region, beta tester, internal user)

**Self-hosted options** (no vendor lock-in, relevant for your stack):
- **Unleash** — mature, PostgreSQL-backed, Docker-deployable, great self-hosted option
- **Flagsmith** — simpler, good UI, self-hostable
- **GrowthBook** — includes A/B test analysis, self-hostable

### Backend Flag Service (NestJS / FastAPI)

```typescript
// NestJS — inject flag service as a dependency
@Injectable()
export class FeatureFlagService {
  constructor(private readonly openFeature: OpenFeatureClient) {}

  async isEnabled(flag: string, context: FlagContext): Promise<boolean> {
    try {
      return await this.openFeature.getBooleanValue(flag, false, context);
    } catch {
      return false; // fail open — default off, never throw
    }
  }
}

// Route handler
@Get('documents/:id')
async getDocument(@Param('id') id: string, @CurrentUser() user: User) {
  const useNewRenderer = await this.flags.isEnabled(
    'enable-new-renderer',
    { targetingKey: user.id, plan: user.plan },
  );

  return useNewRenderer
    ? this.documentService.renderV2(id)
    : this.documentService.renderV1(id);
}
```

### Frontend Flag Evaluation

Evaluate flags server-side when possible — avoids layout flash and prevents exposing rollout percentages to clients:

```typescript
// Next.js — evaluate at request time, pass as prop
export async function getServerSideProps({ req }) {
  const userId = getUserIdFromRequest(req);
  const flags = {
    enableNewEditor: await featureFlags.isEnabled('enable-new-editor', { targetingKey: userId }),
  };
  return { props: { flags } };
}
```

Client-side evaluation (acceptable for non-critical UI flags):
```typescript
// React hook — cached, not re-evaluated on every render
function useFlag(flagName: string): boolean {
  const { userId } = useUser();
  return useFlagValue(flagName, { targetingKey: userId });
}
```

Never evaluate flags inside tight loops or re-evaluate on every render — cache the result for the duration of the request or component lifecycle.

## Flag Hygiene

### Naming Conventions

```
enable-<feature-name>          # boolean on/off flag
<feature>-rollout-percentage   # numeric flag
<feature>-variant              # string flag for experiments
max-<resource>-per-<unit>      # ops flag
```

- Use kebab-case
- Use `enable-` prefix for boolean feature flags
- Name describes what is enabled, not the ticket number (`enable-new-search` not `PROJ-1234`)

### Flag Inventory

Maintain a flag registry — a single file or doc listing every active flag:

```markdown
| Flag | Type | Owner | Created | Removal Target | Status |
|---|---|---|---|---|---|
| enable-new-document-editor | Release | @jakub | 2025-03-15 | 2025-04-15 | 45% rollout |
| max-embedding-batch-size | Ops | @jakub | 2025-01-10 | Permanent | active |
| enable-ai-search-v2 | Release | @jakub | 2025-03-01 | 2025-03-22 | **cleanup needed** |
```

Flag debt alert: if a release flag is still in the registry more than 30 days after full rollout, create a cleanup ticket immediately.

### Cleanup PR Pattern

When removing a flag that is fully rolled out:
1. Pick the winning branch — the `true` path
2. Remove the flag evaluation call
3. Remove the `false` path (old code)
4. Remove the flag from the registry and flag service
5. The diff should be pure deletion + minor restructuring

```typescript
// Before
if (await flags.isEnabled('enable-new-editor', ctx)) {
  return renderNewEditor(doc);
} else {
  return renderLegacyEditor(doc);
}

// After cleanup (flag removed, new editor is the only path)
return renderNewEditor(doc);
```

## Feature Flag Checklist

```
Creation:
- [ ] Flag type chosen (kill switch / release / experiment / ops / permission)
- [ ] Default value is false for new features
- [ ] Lifecycle defined: removal date or permanent justification
- [ ] Cleanup ticket created in issue tracker
- [ ] Flag added to registry

Implementation:
- [ ] Flag evaluated with stable targeting key (userId, not random)
- [ ] Flag service failure returns default (fail open)
- [ ] Flag not evaluated inside loops or hot render paths
- [ ] Context attributes passed for targeting rules

Cleanup:
- [ ] Flag fully rolled out for at least 1 week with no issues
- [ ] Winning code path kept, losing path deleted
- [ ] Flag removed from service and registry
- [ ] No flag references remain in codebase (grep to verify)
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| `Math.random() < 0.05` for 5% rollout | Stable hash on userId — consistent per user |
| Flag service down → request fails | `try/catch` → return default on failure |
| Release flag never removed after full rollout | Create cleanup ticket at flag creation time |
| Flags for permanent access control | Use role/permission system |
| Evaluating flag on every render | Evaluate once per request or lifecycle, cache result |
| Flags named after ticket numbers | Descriptive names: `enable-new-search`, not `PROJ-1234` |
| No flag registry | Maintain inventory with owner + removal target |

## Connected Skills

- `ci-cd` — feature flags let you deploy dark and activate separately from deployment
- `observability` — log flag evaluation decisions in structured fields for debugging rollout issues
- `api-contract` — flag-gated API endpoints may need versioned contract management
- `technical-context-discovery` — discover existing flag infrastructure before adding new flag tooling
