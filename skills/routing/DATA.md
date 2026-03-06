# DATA Branch

## When to enter this branch
- Task involves database schema design, normalization, or data modeling
- Task involves SQL queries, indexes, query optimization, or `EXPLAIN ANALYZE`
- Task involves database migrations or schema changes
- Task involves ORM patterns, entity design, or repository layers
- Task involves foreign keys, relationships, or referential integrity
- Files being edited are `.sql`, migration files, or entity/model definitions

## When NOT to enter this branch
- Task is about backend application logic that happens to use a database — use BACKEND (and combine with DATA)
- Task is about frontend data fetching or state management — use FRONTEND
- Task is about Docker or deployment — use INFRA
- Task is about reviewing code quality or architecture — use WORKFLOW

## Decision tree

For tasks matching this branch, read the next level:

| If the task involves... | Read next |
|-------------------------|-----------|
| SQL, PostgreSQL, schema design, normalization, indexes, migrations, ORM | skills/sql-and-database/SKILL.md |
| Unclear / data-related task | skills/sql-and-database/SKILL.md |

## Combination rules
- When the task involves both a backend service and database changes, load `sql-and-database` together with the backend skill (`nestjs`, `kotlin`, or `rust`) from the BACKEND branch
- When designing architecture that includes data modeling, load `sql-and-database` together with `architecture-design` from the WORKFLOW branch
- When reviewing code that includes SQL or ORM patterns, load `sql-and-database` together with `code-review` from the WORKFLOW branch
- `sql-and-database` is never loaded together with frontend-only skills — if data concerns appear in a frontend task, route through BACKEND first
