# ORM CLI Reference

The `ormed_cli` package provides a command-line interface for managing database
migrations, seeders, and schema operations. It ships an executable named `orm`.

## Installation

Add `ormed_cli` to your `dev_dependencies`:

```yaml
dev_dependencies:
  ormed_cli: ^1.0.0
```

Run commands using:

```bash
dart run ormed_cli:orm <command> [options]
```

## Quick Reference

| Command | Description |
|---------|-------------|
| `orm init` | Initialize project structure |
| `orm make` | Create migrations or seeders |
| `orm apply` | Apply pending migrations |
| `orm rollback` | Rollback applied migrations |
| `orm status` | Show migration status |
| `orm seed` | Run database seeders |
| `orm schema:describe` | Describe and dump current schema |

## Configuration

The CLI uses `orm.yaml` for configuration. Run `orm init` to scaffold a default
configuration or create one manually.

### Single Connection

```yaml
driver:
  type: sqlite
  options:
    database: database.sqlite
migrations:
  directory: database/migrations
  registry: database/migrations.dart
  ledger_table: orm_migrations
  schema_dump: database/schema.sql
seeds:
  directory: database/seeders
  registry: database/seeders.dart
  default_class: DatabaseSeeder
```

### Multi-Tenant Connections

```yaml
default_connection: default
connections:
  default:
    driver:
      type: sqlite
      options:
        database: database.sqlite
    migrations:
      directory: database/migrations
      registry: database/migrations.dart
      ledger_table: orm_migrations
      schema_dump: database/schema.sql
    seeds:
      directory: database/seeders
      registry: database/seeders.dart
      default_class: DatabaseSeeder
  analytics:
    driver:
      type: sqlite
      options:
        database: database.analytics.sqlite
    migrations:
      directory: database/migrations
      registry: database/migrations.dart
      ledger_table: orm_migrations
      schema_dump: database/schema.sql
    seeds:
      directory: database/seeders
      registry: database/seeders.dart
      default_class: DatabaseSeeder
```

Use `--connection <name>` with any command to target a specific tenant.

---

## Commands

### `orm init`

Initialize the ORM project structure with configuration and registry files.

```bash
orm init [options]
```

**Options:**

| Option | Description |
|--------|-------------|
| `-f, --force` | Rebuild scaffolding even if files already exist |
| `--paths` | Print canonical paths for each scaffolded artifact |

**Created Files:**

- `orm.yaml` — Configuration file
- `database/migrations/` — Migrations directory
- `database/migrations.dart` — Migration registry
- `database/seeders/` — Seeders directory
- `database/seeders.dart` — Seeder registry
- `database/seeders/database_seeder.dart` — Default seeder
- `database/schema.sql` — Schema dump file

**Example:**

```bash
# Initialize a new project
orm init

# Force recreate all files
orm init --force

# Show created paths
orm init --paths
```

---

### `orm make`

Create a new migration or seeder file and register it automatically.

```bash
orm make --name <slug> [options]
```

**Options:**

| Option | Description |
|--------|-------------|
| `-n, --name` | Slug for the migration/seeder (required) |
| `--table` | Table to modify or create |
| `--create` | Indicates the migration creates a table (guesses name from slug) |
| `--path` | Override migrations directory |
| `--realpath` | Treat `--path` as absolute path |
| `--fullpath` | Print full path instead of relative |
| `--seeder` | Generate a seeder instead of a migration |
| `-c, --config` | Path to orm.yaml |

**Examples:**

```bash
# Create a migration
orm make --name create_users_table

# Create a table migration with explicit table name
orm make --name create_users_table --create --table users

# Create a seeder
orm make --name demo_data --seeder

# Use custom config
orm make --name add_posts_table -c packages/my_app/orm.yaml
```

**Generated Migration:**

```dart
import 'package:ormed/migrations.dart';

class CreateUsersTable extends Migration {
  const CreateUsersTable();

  @override
  void up(SchemaBuilder schema) {}

  @override
  void down(SchemaBuilder schema) {}
}
```

**Generated Seeder:**

```dart
import 'package:ormed_cli/runtime.dart';
import 'package:ormed/ormed.dart';

class DemoData extends Seeder {
  DemoData(SeedContext context) : super(context);

  @override
  Future<void> run() async {
    final seeder = context.seeder;
    // TODO: add seed logic here
  }
}
```

---

### `orm apply`

Apply pending migrations to the database.

```bash
orm apply [options]
```

**Options:**

| Option | Description |
|--------|-------------|
| `-c, --config` | Path to orm.yaml |
| `--preview` | Print schema diffs and SQL previews before applying |
| `--connection` | Select a specific connection from orm.yaml |
| `-d, --database` | Override database connection path |
| `--limit` | Maximum number of migrations to apply |
| `--seed` | Run default seeder after applying migrations |
| `--seeder` | Run a specific seeder after migrations |
| `--step` | Apply one migration at a time |
| `--pretend` | Preview SQL without executing |
| `--schema-path` | Schema dump file to load when ledger is empty |
| `-f, --force` | Skip production confirmation prompt |
| `--graceful` | Return success even if errors occur |
| `--path` | Override migration registry path |
| `--realpath` | Treat `--path` as absolute path |

**Examples:**

```bash
# Apply all pending migrations
orm apply

# Apply to a specific connection
orm apply --connection analytics

# Preview what would be applied
orm apply --pretend

# Apply with schema diff preview
orm apply --preview

# Apply and seed
orm apply --seed
orm apply --seeder DemoContentSeeder

# Apply limited migrations
orm apply --limit 5

# Apply one at a time
orm apply --step

# Force apply in production
orm apply --force
```

**Schema Dump Loading:**

When the migration ledger is empty, `apply` automatically loads the schema dump
file (configured via `migrations.schema_dump`) to bootstrap the database. This
is useful for fresh deployments where you want to start from a known state.

---

### `orm rollback`

Rollback the most recently applied migrations.

```bash
orm rollback [options]
```

**Options:**

| Option | Description |
|--------|-------------|
| `-c, --config` | Path to orm.yaml |
| `--preview` | Print schema diffs and SQL previews |
| `--connection` | Select a specific connection from orm.yaml |
| `-d, --database` | Override database connection path |
| `--steps` | Number of migrations to rollback (default: 1) |
| `--batch` | Rollback all migrations from a specific batch |
| `--pretend` | Preview SQL without executing |
| `-f, --force` | Skip production confirmation prompt |
| `--graceful` | Treat errors as warnings and return success |
| `--path` | Override migration registry path |
| `--realpath` | Treat `--path` as absolute path |

**Examples:**

```bash
# Rollback last migration
orm rollback

# Rollback last 3 migrations
orm rollback --steps 3

# Rollback entire last batch
orm rollback --batch 1

# Preview rollback
orm rollback --pretend

# Rollback on analytics connection
orm rollback --connection analytics

# Force rollback in production
orm rollback --force
```

---

### `orm status`

Show the status of all registered migrations.

```bash
orm status [options]
```

**Options:**

| Option | Description |
|--------|-------------|
| `-c, --config` | Path to orm.yaml |
| `--preview` | Print schema diffs and SQL previews |
| `--connection` | Select a specific connection from orm.yaml |
| `-d, --database` | Override database connection path |
| `--pending` | Only list pending migrations (exits with code 1 if any exist) |
| `--path` | Override migration registry path |
| `--realpath` | Treat `--path` as absolute path |

**Examples:**

```bash
# Show all migration statuses
orm status

# Check for pending migrations (useful in CI)
orm status --pending

# Status for specific connection
orm status --connection analytics
```

**Output:**

```
Migration                                 Status
------------------------------------------ -------------------------
2025_01_01_000000_create_users_table      Ran at 2025-01-15T10:30:00Z [batch 1]
2025_01_02_000000_create_posts_table      Ran at 2025-01-15T10:30:01Z [batch 1]
2025_01_03_000000_add_tags_table          Pending
```

---

### `orm seed`

Run database seeders defined in orm.yaml.

```bash
orm seed [options]
```

**Options:**

| Option | Description |
|--------|-------------|
| `-c, --config` | Path to orm.yaml |
| `--connection` | Select a specific connection from orm.yaml |
| `-d, --database` | Override database connection path |
| `-s, --class` | Specific seeder class(es) to run (repeatable) |
| `--pretend` | Preview SQL without executing |
| `-f, --force` | Skip production confirmation prompt |

**Examples:**

```bash
# Run default seeder
orm seed

# Run specific seeders
orm seed --class DemoContentSeeder
orm seed --class UserSeeder --class PostSeeder

# Seed specific connection
orm seed --connection analytics

# Preview seeding
orm seed --pretend

# Force seed in production
orm seed --force
```

---

### `orm schema:describe`

Describe the current database schema and update the schema dump file.

```bash
orm schema:describe [options]
```

**Options:**

| Option | Description |
|--------|-------------|
| `-c, --config` | Path to orm.yaml |
| `--json` | Output schema as JSON |

**Examples:**

```bash
# Describe schema and update dump
orm schema:describe

# Output as JSON
orm schema:describe --json
```

**Output:**

```
Collection: users
Collection: posts
Collection: comments
Collection: tags
Collection: post_tags
Collection: orm_migrations
Updated schema dump at database/schema.sql
```

---

## Global Options

These options are available on most commands:

| Option | Description |
|--------|-------------|
| `-c, --config` | Path to orm.yaml (defaults to project root) |
| `--connection` | Select a connection block from orm.yaml |
| `-d, --database` | Override the database path |
| `-h, --help` | Print usage information |

---

## Multi-Tenant Workflows

When working with multiple database connections:

```bash
# Apply migrations to all connections
orm apply
orm apply --connection analytics
orm apply --connection reporting

# Check status across connections
orm status
orm status --connection analytics

# Seed each connection
orm seed
orm seed --connection analytics
```

---

## CI/CD Integration

### Check for Pending Migrations

Use `--pending` to fail CI when migrations haven't been applied:

```bash
orm status --pending
# Exits with code 1 if pending migrations exist
```

### Preview Before Applying

Use `--pretend` to verify SQL before execution:

```bash
orm apply --pretend
```

### Force Apply in Production

Skip confirmation prompts with `--force`:

```bash
orm apply --force
```

### Graceful Error Handling

Continue on errors with `--graceful`:

```bash
orm apply --graceful
```

### Example CI Script

```bash
#!/bin/bash
set -e

# Check for pending migrations
dart run ormed_cli:orm status --pending

# Or apply pending migrations
dart run ormed_cli:orm apply --force

# Optionally seed
dart run ormed_cli:orm seed --force
```

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `POSTGRES_URL` | PostgreSQL connection URL |
| `MYSQL_URL` | MySQL connection URL |
| `PLAYGROUND_DB` | Override SQLite database path (playground only) |

**Example:**

```bash
export POSTGRES_URL=postgres://user:pass@host/db
dart run ormed_cli:orm apply
```

---

## Troubleshooting

### Migration Checksum Mismatch

If you see "checksum mismatch" errors, the migration file content has changed
since it was applied. Options:

1. **Restore the original migration** — Revert changes to match the applied version
2. **Reset the database** — Delete the database and re-apply from scratch
3. **Update the ledger** — Manually update the checksum in `orm_migrations` table (use caution)

### Schema Dump Out of Sync

Run `orm schema:describe` to regenerate the schema dump:

```bash
orm schema:describe
```

### Registry Not Found

If you see "Registry file not found", run `orm init` to scaffold the project:

```bash
orm init
```

### Connection Not Found

Ensure the connection name matches an entry in `orm.yaml`:

```yaml
connections:
  myconnection:  # Use --connection myconnection
    driver:
      type: sqlite
      options:
        database: my.sqlite
```

---

## See Also

- [Migrations Documentation](migrations.md) — Detailed migration concepts and schema builder API
- [Data Source Documentation](data_source.md) — Runtime database access patterns
- [Examples](examples.md) — Complete working examples