# DATA Branch

## When to enter this branch
- Task involves database schema design, normalization, or data modeling
- Task involves SQL queries, indexes, query optimization, or `EXPLAIN ANALYZE`
- Task involves database migrations or schema changes
- Task involves ORM patterns, entity design, or repository layers
- Task involves foreign keys, relationships, or referential integrity
- Task involves domain-driven data modeling, aggregate design, or value objects
- Files being edited are `.sql`, migration files, or entity/model definitions

## When NOT to enter this branch
- Task is about backend application logic that happens to use a database — use BACKEND (and combine with DATA)
- Task is about frontend data fetching or state management — use FRONTEND
- Task is about Docker or deployment — use INFRA
- Task is about reviewing code quality or architecture — use WORKFLOW

## Decision tree

For tasks matching this branch, read the next level:

| If the task involves... | Read next |
|---|---|
| SQL, PostgreSQL, schema design, normalization, indexes, migrations, ORM | skills/sql-and-database/SKILL.md |
| DDD, aggregate design, value objects, repository pattern, domain events | skills/data-modeling/SKILL.md |
| Both physical schema and domain model design | Load both skills |
| Unclear / data-related task | skills/sql-and-database/SKILL.md |

## Combination rules
- When the task involves both a backend service and database changes, load `sql-and-database` together with the backend skill (`nestjs`, `kotlin`, `rust`, `python-fastapi`) from BACKEND
- When designing architecture that includes data modeling, load `data-modeling` together with `architecture-design` from WORKFLOW
- `migration-strategy` (from WORKFLOW) should always be loaded alongside `sql-and-database` when the task involves changing existing production tables
- When reviewing code that includes SQL or ORM patterns, load `sql-and-database` together with `code-review` from WORKFLOW
- `data-modeling` and `sql-and-database` are complementary — domain model design precedes physical schema design
- `sql-and-database` is never loaded together with frontend-only skills
