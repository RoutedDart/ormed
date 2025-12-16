---
sidebar_position: 3
---

# PostgreSQL

Use PostgreSQL for production‑grade features (JSONB, window functions, robust constraints). Configure via URL or discrete fields.

## orm.yaml

```yaml
driver:
  type: postgres
  options:
    url: postgres://postgres:postgres@localhost:6543/orm_test
    sslmode: disable        # disable | require | verify-full
    timezone: UTC
    connectTimeout: 5000    # milliseconds
    statementTimeout: 30000 # milliseconds
    applicationName: my-app
migrations:
  directory: lib/src/database/migrations
  registry: lib/src/database/migrations.dart
seeds:
  directory: lib/src/database/seeders
  registry: lib/src/database/seeders.dart
```

### Options

- `url` / `uri` / `dsn` — full connection string; overrides individual fields.
- `host` (default `localhost`)
- `port` (default `5432`)
- `database` (defaults to path segment or `postgres`)
- `username` (default `postgres`)
- `password` (optional)
- `sslmode` (`disable`, `require`, `verify-full`)
- `connectTimeout` (ms) — socket connect timeout.
- `statementTimeout` (ms) — server‑side statement timeout.
- `timezone` (default `UTC`)
- `applicationName` — tags sessions for monitoring.
- `schema` — default schema name for migrations/queries (defaults to `public`).

### Notes

- Supports `RETURNING`, JSON/JSONB operators, window functions, and schema introspection.
- Use `POSTGRES_URL` to point tests or CLI commands at ephemeral containers.
