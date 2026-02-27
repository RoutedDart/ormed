# ormed_cli

Command-line interface for the ormed ORM. Provides migration management, schema operations, seeding, and project scaffolding—similar to Laravel's Artisan CLI.

## Installation

```yaml
dev_dependencies:
  ormed_cli: ^0.1.0
```

The CLI is available as the `ormed` executable:

```bash
dart run ormed_cli:ormed <command>
```

## Commands

### Project Initialization

```bash
# Scaffold code-first datasource + migrations/seed registries
dart run ormed_cli:ormed init

# Also scaffold ormed.yaml (optional)
dart run ormed_cli:ormed init --with-config

# Overwrite existing files
dart run ormed_cli:ormed init --force

# Scan and register existing migrations/seeders
dart run ormed_cli:ormed init --populate-existing
```

### Migration Management

```bash
# Create a new migration
dart run ormed_cli:ormed make --name create_users_table
dart run ormed_cli:ormed make:migration --name create_users_table
# `makemigration` remains available as a deprecated alias.
dart run ormed_cli:ormed make --name create_posts_table --create --table posts
dart run ormed_cli:ormed make --name add_column --format sql  # SQL format instead of Dart
# `create_*` names infer create-table scaffolding automatically.
# `add_*_to_*` / `remove_*_from_*` names infer alter-table targets.
# If registries are missing, `make` bootstraps migrations/seed scaffolding automatically.

# Generate migration from model schema diff (and sync registry entries)
dart run ormed_cli:ormed makemigrations
dart run ormed_cli:ormed makemigrations --sync-only
dart run ormed_cli:ormed migrations:sync --dry-run   # sync registry only
dart run ormed_cli:ormed migrations:check

# Run pending migrations
dart run ormed_cli:ormed migrate
dart run ormed_cli:ormed migrate --pretend      # Preview SQL without executing
dart run ormed_cli:ormed migrate --step         # Apply one migration at a time
dart run ormed_cli:ormed migrate --seed         # Run default seeder after
dart run ormed_cli:ormed migrate --force        # Skip production confirmation

# Rollback migrations
dart run ormed_cli:ormed migrate:rollback              # Rollback 1 migration
dart run ormed_cli:ormed migrate:rollback --steps 3    # Rollback 3 migrations
dart run ormed_cli:ormed migrate:rollback --batch 2    # Rollback specific batch
dart run ormed_cli:ormed migrate:rollback --pretend    # Preview rollback SQL

# Reset/Refresh
dart run ormed_cli:ormed migrate:reset      # Rollback ALL migrations
dart run ormed_cli:ormed migrate:refresh    # Reset + re-migrate
dart run ormed_cli:ormed migrate:fresh      # Drop all tables + re-migrate
dart run ormed_cli:ormed migrate:fresh --seed

# Migration status
dart run ormed_cli:ormed migrate:status
dart run ormed_cli:ormed migrate:status --pending  # Only show pending

# Export SQL files
dart run ormed_cli:ormed migrate:export        # Export pending migrations
dart run ormed_cli:ormed migrate:export --all  # Export all migrations
```

### Database Operations

```bash
# Run seeders
dart run ormed_cli:ormed seed
dart run ormed_cli:ormed seed --class UserSeeder  # Specific seeder
dart run ormed_cli:ormed seed --pretend           # Preview SQL

# Create seeders
dart run ormed_cli:ormed make --name UserSeeder --seeder
dart run ormed_cli:ormed make:seeder --name UserSeeder

# Wipe database
dart run ormed_cli:ormed db:wipe --force
dart run ormed_cli:ormed db:wipe --drop-views

# Schema operations
dart run ormed_cli:ormed schema:dump
dart run ormed_cli:ormed schema:dump --prune  # Delete migration files after dump
dart run ormed_cli:ormed schema:describe
dart run ormed_cli:ormed schema:describe --json
```

### Multi-Database Support

```bash
# Target specific connection
dart run ormed_cli:ormed migrate --connection analytics
dart run ormed_cli:ormed seed --connection analytics
dart run ormed_cli:ormed migrate:status --connection analytics
```

### Existing Project Onboarding

```bash
# 1) Scaffold only database wiring into an existing project
dart run ormed_cli:ormed init

# 2) Generate model code
dart run build_runner build

# 3) Create first migration from model definitions
dart run ormed_cli:ormed makemigrations

# 4) Apply migrations
dart run ormed_cli:ormed migrate

# 5) Keep using make:migration for manual schema edits
dart run ormed_cli:ormed make:migration --name add_status_to_users
```

## Configuration (ormed.yaml, optional)

`init --with-config` (or `init --only=config`) scaffolds this file:

Without `ormed.yaml`, CLI commands use convention defaults:
- driver: `sqlite`
- database: `database/<package>.sqlite`
- migrations registry: `lib/src/database/migrations.dart`
- seed registry: `lib/src/database/seeders.dart`

```yaml
driver:
  type: sqlite                              # sqlite, mysql, postgres
  options:
    database: database.sqlite               # Connection-specific options

migrations:
  directory: lib/src/database/migrations    # Migration files location
  registry: lib/src/database/migrations.dart # Migration registry file
  ledger_table: orm_migrations              # Table tracking applied migrations
  schema_dump: database/schema.sql          # Schema dump output
  format: dart                              # Migration format: dart or sql

seeds:
  directory: lib/src/database/seeders
  registry: lib/src/database/seeders.dart
```

### Multi-Connection Configuration

```yaml
connections:
  default:
    type: sqlite
    options:
      database: main.sqlite
  analytics:
    type: postgres
    options:
      host: localhost
      port: 5432
      database: analytics
      username: user
      password: secret

default_connection: default
```

## Directory Structure

After running `init`:

```
project/
├── ormed.yaml (optional)
├── database/
│   └── schema.sql
└── lib/src/database/
    ├── migrations/
    │   └── m_YYYYMMDDHHMMSS_migration_name.dart
    ├── migrations.dart   (registry)
    ├── seeders/
    │   └── database_seeder.dart
    └── seeders.dart      (registry)
```

## Migration Formats

### Dart Migrations (default)

```dart
class CreateUsersTable extends Migration {
  @override
  void up(SchemaBuilder schema) {
    schema.create('users', (table) {
      table.id();
      table.string('email').unique();
      table.timestamps();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('users');
  }
}
```

### SQL Migrations

```
m_20251220120000_create_users_table/
├── up.sql
└── down.sql
```

## Global Options

Most commands support these flags:

| Flag | Description |
|------|-------------|
| `--config, -c` | Path to ormed.yaml |
| `--database, -d` | Override database connection |
| `--connection` | Select connection from ormed.yaml |
| `--path` | Override migration registry path |
| `--force, -f` | Skip production confirmation |
| `--pretend` | Preview SQL without executing |
| `--graceful` | Treat errors as warnings |

## Creating Seeders

```bash
dart run ormed_cli:ormed make --name UserSeeder --seeder
```

```dart
class UserSeeder extends DatabaseSeeder {
  @override
  Future<void> run() async {
    await seed<User>([
      {'email': 'admin@example.com', 'name': 'Admin'},
      {'email': 'user@example.com', 'name': 'User'},
    ]);
  }
}
```
