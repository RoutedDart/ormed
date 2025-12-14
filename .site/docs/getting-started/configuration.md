---
sidebar_position: 3
---

# Configuration

Ormed uses an `orm.yaml` file for CLI configuration and database connections.

## Basic Configuration

Create `orm.yaml` in your project root:

```yaml
default_connection: primary

connections:
  primary:
    driver:
      type: sqlite
      options:
        database: database.sqlite
    migrations:
      directory: lib/src/database/migrations
      registry: lib/src/database/migrations.dart
      ledger_table: _orm_migrations
      schema_dump: database/schema.sql
```

## Configuration Options

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
    # Driver configuration
    driver:
      type: sqlite  # sqlite, postgres, mysql
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
      default_class: DatabaseSeeder
```

## Driver Options

### SQLite

```yaml
driver:
  type: sqlite
  options:
    database: database.sqlite  # File path or ":memory:" for in-memory
```

### PostgreSQL

```yaml
driver:
  type: postgres
  options:
    host: localhost
    port: 5432
    database: myapp
    username: postgres
    password: secret
    # Or use a connection URL:
    # url: postgres://user:pass@localhost:5432/myapp
```

### MySQL

```yaml
driver:
  type: mysql
  options:
    host: localhost
    port: 3306
    database: myapp
    username: root
    password: secret
```

## Multiple Connections

Configure multiple database connections for different purposes:

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

  analytics:
    driver:
      type: sqlite
      options:
        database: data/analytics.sqlite
    migrations:
      directory: lib/src/database/migrations/analytics
      registry: lib/src/database/analytics_migrations.dart

  testing:
    driver:
      type: sqlite
      options:
        database: ":memory:"
    migrations:
      directory: lib/src/database/migrations
      registry: lib/src/database/migrations.dart
```

Use the `--connection` flag to target a specific connection:

```bash
# Run migrations on analytics database
dart run orm migrate:apply --connection analytics

# Check status of testing database
dart run orm migrate:status --connection testing
```

## Environment Variables

You can use environment variables in your configuration:

```yaml
connections:
  production:
    driver:
      type: postgres
      options:
        url: ${DATABASE_URL}
```

Set the environment variable:

```bash
export DATABASE_URL="postgres://user:pass@db.example.com:5432/myapp"
dart run orm migrate:apply --connection production
```

## Programmatic Configuration

You can also configure Ormed programmatically using the generated registry:

```dart file=../../examples/lib/setup.dart#programmatic-config
```

### Manual Registration

If you prefer manual control, you can still register models individually:

```dart file=../../examples/lib/setup.dart#manual-registration
```

## Next Steps

- [Defining Models](../models/defining-models) - Create your first models
- [CLI Commands](../cli/commands) - Learn all available CLI commands
- [Migrations](../migrations/overview) - Set up database migrations
