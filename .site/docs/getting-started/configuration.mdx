---
sidebar_position: 3
---

# Configuration

Ormed uses `orm.yaml` for CLI + runtime configuration. Two shapes are supported: a single top-level connection (scaffold default) or a `connections:` map for multi-db setups.

:::note Snippet context
- YAML blocks show CLI/runtime config.
- Dart snippets show only the relevant registry/setup pieces; full app bootstrapping is covered in Quick Start.
:::

## Single Connection (default)

Create `orm.yaml` in your project root:

```yaml
driver:
  type: sqlite
  options:
    database: database.sqlite
migrations:
  directory: lib/src/database/migrations
  registry: lib/src/database/migrations.dart
  ledger_table: orm_migrations
  schema_dump: database/schema.sql
seeds:
  directory: lib/src/database/seeders
  registry: lib/src/database/seeders.dart
```

CLI commands read these top-level blocks as the single active connection.

## Multiple Connections (multi-tenant or multi-env)

```yaml
default_connection: primary

connections:
  primary:
    driver:
      type: sqlite
      options:
        database: data/app.sqlite
    migrations:
      directory: lib/src/database/migrations
      registry: lib/src/database/migrations.dart
      ledger_table: orm_migrations
      schema_dump: database/schema.sql
    seeds:
      directory: lib/src/database/seeders
      registry: lib/src/database/seeders.dart

  analytics:
    driver:
      type: postgres
      options:
        url: ${ANALYTICS_URL}
        schema: analytics
    migrations:
      directory: lib/src/database/migrations/analytics
      registry: lib/src/database/analytics_migrations.dart
```

Use `--connection <name>` on any CLI command to target a specific entry.

## Configuration Blocks (what each section means)

### `default_connection`

The default database connection to use when `--connection` is not specified.

```yaml
default_connection: primary
```

### `connections`

Named database connections. Each connection has its own driver, migrations, and seed configuration.

```yaml
connections:
  primary:
    driver:
      type: sqlite  # sqlite, postgres, mysql, mariadb
      options:
        database: database.sqlite
    
    # Migrations configuration
    migrations:
      directory: lib/src/database/migrations
      registry: lib/src/database/migrations.dart
      ledger_table: _orm_migrations
      schema_dump: database/schema.sql
    
    # Seeders configuration (optional)
    seeds:
      directory: lib/src/database/seeders
      registry: lib/src/database/seeders.dart
```

## Registry Files (Why They Matter)

Both `migrations.registry` and `seeds.registry` are **standalone Dart entrypoints**. The CLI shells out to these files, so keep their paths accurate in `orm.yaml`.

- **Migrations registry** (`migrations.registry`): exports `buildMigrations()` and a small `main` that supports flags like `--dump-json`/`--plan-json` for schema previews. You can run it directly:

  ```bash
  dart run lib/src/database/migrations.dart --dump-json
  ```

- **Seeds registry** (`seeds.registry`): lists `SeederRegistration`s and exposes `main` for `orm seed` / `orm migrate --seed`. You can execute it without the CLI wrapper:

  ```bash
  dart run lib/src/database/seeders.dart
  ```

If you relocate these files, update the `registry` paths so the CLI can find and execute them.

Driver-specific options live on the dedicated pages: **Drivers → SQLite / PostgreSQL / MySQL**.

## Environment Variables

You can use environment variables in your configuration. `${VAR}` resolves from the current process environment; `${VAR:-fallback}` uses `fallback` when unset.

```yaml
connections:
  production:
    driver:
      type: postgres
      options:
        url: ${DATABASE_URL}
        sslmode: ${DB_SSLMODE:-disable}
```

Set the environment variable:

```bash
export DATABASE_URL="postgres://user:pass@db.example.com:5432/myapp"
dart run orm migrate:apply --connection production
```

`.env` support: if a `.env` file sits next to `orm.yaml`, it is loaded automatically (merged with platform environment). Useful for local secrets without exporting them.

## Programmatic Configuration

You can also configure Ormed programmatically using the generated registry:

```dart file=../../examples/lib/setup.dart#programmatic-config
```

### Manual Registration

If you prefer manual control, you can still register models individually:

```dart file=../../examples/lib/setup.dart#manual-registration
```

## Next Steps

- [Drivers](../drivers/overview) — choose and configure your target database
- [Defining Models](../models/defining-models) — create your first models
- [CLI Commands](../cli/commands) — learn all available CLI commands
- [Migrations](../migrations/overview) — set up database migrations
