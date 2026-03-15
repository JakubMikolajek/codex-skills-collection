---
name: migration-strategy
description: Database migration strategy patterns for zero-downtime schema changes, backward-compatible migrations, rollback procedures, and migration safety. Use when planning or reviewing database schema changes, coordinating migrations with application deployments, or designing migration workflows for CI/CD pipelines.
---

# Migration Strategy

A migration is a deployment. It modifies a shared, stateful system — the database — and unlike application code, it cannot simply be rolled back by reverting a deploy. This skill covers how to change database schemas safely without downtime and without data loss.

## When to Use

- Planning a schema change to an existing production database
- Reviewing a migration file before it runs in production
- Designing the migration workflow for a CI/CD pipeline
- A migration ran but needs to be rolled back
- Adding a column or index to a large table in production

## When NOT to Use

- Designing the initial schema for a new database — use `sql-and-database`
- Application-level data transformation logic not involving schema changes
- Message queue schema changes (different toolchain)

## Core Principles

### Migrations and Application Deployments are Separate

Never run a migration and deploy new application code simultaneously. Separate them into distinct, independently reversible steps. The application must be able to run against both the old and new schema during the transition window.

### Expand-Contract Pattern

Every breaking schema change has a safe path: expand first (add new structure, keep old), deploy new application code that uses both, then contract (remove old structure once old code is gone). This eliminates downtime and enables rollback at every step.

### Every Migration Must be Reversible — or Explicitly Not

Write a `down` migration for every `up` migration. If the `down` migration would cause data loss (e.g. dropping a column with data), document that explicitly and require sign-off before the migration runs in production. A migration with no rollback plan is a liability.

## Migration Safety Classification

Before writing a migration, classify its risk:

| Operation | Risk | Strategy |
|---|---|---|
| Add nullable column | Safe | Deploy directly |
| Add column with default | Safe (Postgres 11+) | Deploy directly |
| Add index concurrently | Safe | `CREATE INDEX CONCURRENTLY` |
| Add foreign key | Medium | Add as `NOT VALID`, validate separately |
| Rename column | **Breaking** | Expand-contract (add new, migrate, remove old) |
| Drop column | **Breaking** | Expand-contract (remove from app first, then drop) |
| Change column type | **Breaking** | New column + backfill + swap + drop |
| Drop table | **Breaking** | Stop all references in app first, then drop |
| Add NOT NULL to existing column | **Breaking** | Backfill + add constraint with `NOT VALID` + validate |
| Large table backfill | Dangerous | Batch processing, never single transaction |

## Migration Strategy Process

```
Migration strategy progress:
- [ ] Step 1: Classify migration risk and choose strategy
- [ ] Step 2: Write migration with explicit up and down
- [ ] Step 3: Design the deployment sequence
- [ ] Step 4: Plan the backfill if data changes are needed
- [ ] Step 5: Test rollback in staging
- [ ] Step 6: Verify migration is safe for production table sizes
```

**Step 1: Classify migration risk and choose strategy**

Ask before writing any migration:
1. Will this lock the table? If yes, for how long?
2. Can the running application still function if the migration is halfway complete?
3. What does rollback look like if the migration succeeds but the deploy fails?

For PostgreSQL specifically:
- `ADD COLUMN` with a constant default is non-locking in PostgreSQL 11+
- `ADD COLUMN` with a volatile default (e.g. `DEFAULT gen_random_uuid()`) rewrites the table in PostgreSQL < 11 — check version
- `CREATE INDEX` without `CONCURRENTLY` takes a full table lock — always use `CONCURRENTLY`
- `ALTER COLUMN TYPE` rewrites the table — use a new column + swap strategy
- `FOREIGN KEY` without `NOT VALID` scans the entire table — use `NOT VALID` + `VALIDATE CONSTRAINT` separately

**Step 2: Write migration with explicit up and down**

Migration file structure:
```sql
-- migrations/20250315_143000_add_tags_to_documents.sql
-- Description: Add tags array to documents table for filtering
-- Risk: Safe — adds nullable column with no default
-- Rollback: Drop the column (no data loss)
-- Estimated duration: <1s on current table size (50k rows)

-- Up
ALTER TABLE documents ADD COLUMN tags TEXT[] DEFAULT '{}' NOT NULL;
CREATE INDEX CONCURRENTLY idx_documents_tags ON documents USING GIN(tags);

-- Down
DROP INDEX CONCURRENTLY IF EXISTS idx_documents_tags;
ALTER TABLE documents DROP COLUMN IF EXISTS tags;
```

File naming: `YYYYMMDD_HHMMSS_<description>.sql` — timestamps prevent ordering conflicts.

Required migration header comments:
- **Description**: what this changes and why
- **Risk**: safety classification and potential impact
- **Rollback**: what the down migration does, note if data loss is possible
- **Estimated duration**: based on current row count and operation type

**Step 3: Design the deployment sequence**

For safe migrations (add nullable column, add index concurrently):
```
1. Run migration  →  2. Deploy application
```

For breaking changes (rename, type change, column removal) — expand-contract:

```
Phase 1 — Expand:
  1. Migration: add new column/structure (keep old)
  2. Deploy: app reads from old, writes to both old and new

Phase 2 — Backfill (if needed):
  3. Run backfill: copy data from old column to new column in batches

Phase 3 — Switch:
  4. Deploy: app reads from new, writes to both (still safe to roll back)
  5. Deploy: app reads from new, writes to new only

Phase 4 — Contract:
  6. Migration: drop old column/structure (only after old code is fully gone)
```

Each phase is independently deployable and independently reversible. The entire process may span multiple releases.

Example — renaming `title` to `name` on `documents`:
```sql
-- Phase 1 migration: add new column
ALTER TABLE documents ADD COLUMN name TEXT;

-- Phase 2: application writes to both `title` AND `name`

-- Phase 3 migration: backfill
UPDATE documents SET name = title WHERE name IS NULL;
-- Then add NOT NULL constraint once backfill is complete

-- Phase 4: application reads `name`, writes `name` only

-- Phase 5 migration: drop old column
ALTER TABLE documents DROP COLUMN title;
```

**Step 4: Plan the backfill if data changes are needed**

Never backfill a large table in a single transaction. A long-running transaction locks rows, blocks reads and writes, and can crash on timeout.

Safe batch backfill pattern:
```sql
-- Run this in batches from application code or a migration script
-- DO NOT run as a single UPDATE in a migration file for large tables

DO $$
DECLARE
  batch_size INT := 1000;
  last_id UUID := '00000000-0000-0000-0000-000000000000';
  affected INT;
BEGIN
  LOOP
    UPDATE documents
    SET name = title
    WHERE id > last_id
      AND name IS NULL
    RETURNING id INTO last_id;

    GET DIAGNOSTICS affected = ROW_COUNT;
    EXIT WHEN affected = 0;

    PERFORM pg_sleep(0.01); -- brief pause between batches
  END LOOP;
END $$;
```

Backfill rules:
- Process in batches of 100–10,000 rows depending on row size
- Brief pause between batches to allow replication lag to catch up
- Track progress — log completed batches and total affected rows
- Run during low-traffic windows for initial large backfills
- The migration that adds `NOT NULL` runs after the backfill confirms zero null rows

**Step 5: Test rollback in staging**

Before every production migration:
1. Run the `up` migration on staging database
2. Deploy the new application version
3. Run the `down` migration on staging database
4. Verify the previous application version still works against the rolled-back schema
5. Document any data loss that the `down` migration causes

If the `down` migration causes data loss, this must be explicitly acknowledged and the production plan must include a data backup before running the `up` migration.

**Step 6: Verify migration is safe for production table sizes**

Estimated duration scales with table size and operation type:
- `ADD COLUMN` (nullable, no default): microseconds regardless of size
- `CREATE INDEX CONCURRENTLY` on 1M rows: ~30–120 seconds (non-blocking)
- `UPDATE` backfill on 1M rows (single transaction): 10–60 seconds with full table lock — **do not do this**
- `ALTER COLUMN TYPE` on 1M rows: 1–10 minutes with full table lock — use expand-contract instead

Check current table size before planning:
```sql
SELECT
  relname AS table,
  pg_size_pretty(pg_relation_size(relid)) AS table_size,
  n_live_tup AS row_count
FROM pg_stat_user_tables
WHERE relname = 'documents';
```

For tables over 100k rows: any locking migration requires a maintenance window or a non-locking strategy.

## Migration Checklist

```
Before writing:
- [ ] Migration risk classified (safe / medium / breaking)
- [ ] Locking behavior verified for the database version in use
- [ ] Expand-contract strategy chosen for breaking changes

Writing:
- [ ] Up migration written
- [ ] Down migration written (or data loss documented + sign-off obtained)
- [ ] Header comment includes: description, risk, rollback, estimated duration

Deployment:
- [ ] Deployment sequence defined (migration order relative to app deploy)
- [ ] Application compatible with both old and new schema during transition
- [ ] Backfill is batched, not a single transaction

Testing:
- [ ] Migration tested on staging with production-equivalent row counts
- [ ] Rollback tested in staging
- [ ] Data loss impact documented if down migration is destructive

Production:
- [ ] Table size verified — locking strategy is safe at current size
- [ ] Maintenance window scheduled if locking is unavoidable
- [ ] Database backup confirmed before running destructive migrations
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Rename column in one migration | Expand-contract: add new column, backfill, remove old |
| `UPDATE large_table SET ...` in migration | Batch backfill from application code |
| `CREATE INDEX` without `CONCURRENTLY` on production | `CREATE INDEX CONCURRENTLY` — always |
| Migration and app deploy in the same step | Separate steps: migration first or app first depending on change type |
| No `down` migration | Write the down migration, or document data loss and get sign-off |
| `ALTER TABLE ADD COLUMN ... NOT NULL` without backfill | Add nullable first, backfill, then add NOT NULL constraint |
| Assuming migration duration from row count alone | Measure on staging with production-equivalent size |
| Dropping a column while old app code still references it | Remove reference from app first, then drop column in later release |

## Connected Skills

- `sql-and-database` — schema design principles and ORM migration tool usage (TypeORM, Prisma, Flyway)
- `ci-cd` — migration execution belongs in the deployment pipeline, not in application startup
- `observability` — log migration start, duration, and outcome; alert on migration failure
- `api-contract` — API and schema changes must be coordinated (breaking schema change = breaking API change)
- `error-handling` — migration runner must handle partial failure, timeout, and rollback atomically
