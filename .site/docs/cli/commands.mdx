---
sidebar_position: 1
---

# CLI Commands

The Ormed CLI provides commands for managing migrations, generating code, and working with your database.

## Installation

```bash
# Run via dart
dart run orm <command>

# Or add to PATH and run directly
orm <command>
```

## Configuration

The CLI uses `orm.yaml` for configuration:

```yaml
default_connection: primary
connections:
  primary:
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
  analytics:
    driver:
      type: postgres
      options:
        url: ${POSTGRES_URL}
    migrations:
      directory: database/migrations
      registry: database/migrations.dart
      ledger_table: orm_migrations
```

The CLI automatically finds the nearest `orm.yaml` walking up from the current directory.

## Global Options

| Option | Description |
|--------|-------------|
| `--config`, `-c` | Path to orm.yaml file |
| `--connection` | Target database connection |
| `--help`, `-h` | Show command help |
| `--verbose`, `-v` | Verbose output |

---

## Initialization

### `orm init`

Initialize Ormed in a new project:

```bash
dart run orm init
```

Creates:
- `orm.yaml` configuration file
- `database/migrations/` directory
- `database/migrations.dart` registry file

---

## Migration Commands

### `orm migrate:apply`

Apply pending migrations:

```bash
# Apply all pending
dart run orm migrate:apply

# Apply with limit
dart run orm migrate:apply --limit 5

# Apply to specific connection
dart run orm migrate:apply --connection analytics
```

**Change Set Preview:** Each apply shows a preview of schema changes before execution:

```
Migration m_20241201000000_create_users_table (up) change set:
  + Create table users
      - columns: id, email, name, created_at
  SQL statements: 1
```

### `orm migrate:rollback`

Rollback applied migrations:

```bash
# Rollback last batch
dart run orm migrate:rollback

# Rollback multiple batches
dart run orm migrate:rollback --steps 3

# Target specific connection
dart run orm migrate:rollback --connection analytics
```

### `orm migrate:status`

Check migration status:

```bash
dart run orm migrate:status
```

Output:
```
Migration                                      | Status
----------------------------------------------|--------
m_20241201000000_create_users_table           | Applied
m_20241201000100_create_posts_table           | Applied
m_20241201000200_add_slug_to_posts            | Pending
```

### `orm migrate:fresh`

Drop all tables and re-run all migrations:

```bash
dart run orm migrate:fresh

# With seeding
dart run orm migrate:fresh --seed
```

:::caution
This command drops all tables in the database. Only use in development!
:::

### `orm migrate:reset`

Rollback all migrations and re-run:

```bash
dart run orm migrate:reset
```

### `orm migrate:refresh`

Rollback and re-apply migrations:

```bash
# Refresh all
dart run orm migrate:refresh

# Refresh last N batches
dart run orm migrate:refresh --steps 5
```

---

## Generator Commands

### `orm make:migration`

Generate a new migration file:

```bash
# Basic migration
dart run orm make:migration --name create_users_table

# Create table migration (with boilerplate)
dart run orm make:migration --name create_posts_table --create

# Alter table migration
dart run orm make:migration --name add_slug_to_posts --table posts
```

Generated file: `m_20241201143052_create_users_table.dart`

The migration is automatically registered in `database/migrations.dart`.

### `orm make:model`

Generate a new model:

```bash
dart run orm make:model --name User

# With migration
dart run orm make:model --name Post --migration
```

### `orm make:seeder`

Generate a database seeder:

```bash
dart run orm make:seeder --name UserSeeder
```

---

## Schema Commands

### `orm schema:dump`

Dump the current schema to a SQL file for squashing migrations:

```bash
# Create dump
dart run orm schema:dump

# Create dump and delete migration files
dart run orm schema:dump --prune

# Custom output path
dart run orm schema:dump --path database/schema.sql

# Target specific connection
dart run orm schema:dump --database testing
```

**How schema dumps work:**
1. Fresh databases load the dump first (if ledger is empty)
2. Then apply any migrations created after the dump
3. Speeds up test database setup and onboarding

:::tip
Commit schema dumps to version control so CI/CD can quickly create databases.
:::

### `orm schema:diff`

Show differences between migrations and current database:

```bash
dart run orm schema:diff
```

---

## Database Commands

### `orm db:seed`

Run database seeders:

```bash
# Run default seeder
dart run orm db:seed

# Run specific seeder
dart run orm db:seed --class UserSeeder
```

### `orm db:wipe`

Drop all tables (without running migrations):

```bash
dart run orm db:wipe
```

---

## CI/CD Usage

Run migrations in CI/CD pipelines:

```bash
# For SQLite - works out of the box
dart run orm migrate:apply

# For Postgres - set connection URL
export POSTGRES_URL=postgres://user:pass@db.internal/app
dart run orm migrate:apply --limit 10
```

---

## Examples

```bash
# Initialize new project
dart run orm init

# Create a migration
dart run orm make:migration --name create_users_table --create

# Apply migrations
dart run orm migrate:apply

# Check status
dart run orm migrate:status

# Create and run a seeder
dart run orm make:seeder --name UserSeeder
dart run orm db:seed --class UserSeeder

# Fresh database with seeds
dart run orm migrate:fresh --seed

# Multi-tenant: apply to analytics database
dart run orm migrate:apply --connection analytics
```
