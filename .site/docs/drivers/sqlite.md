---
sidebar_position: 2
---

# SQLite

SQLite is the default scaffold for new projects. It runs without external services and is great for local development, CLI tools, and fast integration tests.

## orm.yaml

```yaml
driver:
  type: sqlite
  options:
    database: database.sqlite   # relative to project root
migrations:
  directory: lib/src/database/migrations
  registry: lib/src/database/migrations.dart
seeds:
  directory: lib/src/database/seeders
  registry: lib/src/database/seeders.dart
```

### Options

- `database` (string) — path to the `.sqlite` file (relative or absolute). If omitted, defaults to `database.sqlite`.
- `memory` (bool, default: false) — set to `true` to run entirely in memory (overrides `database`).

### Notes

- The adapter automatically enables `RETURNING` support and schema inspection.
- Schema dumps use the same paths as other drivers; `orm migrate --seed` works without changes.
