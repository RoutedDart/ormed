# ormed_cli

Command-line tooling for the routed ORM (migrations generator + runner).

## Commands

```
# Scaffold orm.yaml, database/migrations.dart, and migrations directory
dart run ormed_cli:orm init

# Create a new migration file and register it in the registry
dart run ormed_cli:orm make --name create_users_table

# Run pending migrations (use --pretend to preview diff + SQL)
dart run ormed_cli:orm migrate
dart run ormed_cli:orm migrate --pretend

# Roll back migrations (also accepts --pretend)
dart run ormed_cli:orm migrate:rollback --steps 1

# Show migration status
dart run ormed_cli:orm migrate:status

# Run seeders
dart run ormed_cli:orm seed --class DatabaseSeeder
```

The CLI reads `orm.yaml` to determine the driver + connection options and
assumes that `database/migrations.dart` exposes the generator template created
by `ormed_cli:orm init`. Add `--pretend` to any migration command to see the
schema diff and SQL plan before it runs; otherwise migrations execute
immediately.
Define a matching `seeds` block to enable `orm seed` and `orm migrate --seed`, which execute the registry at `database/seeders.dart`.

When you define multiple entries under `connections:` and set
`default_connection`, pass `--connection <name>` to target a specific tenant (for
example `orm migrate --connection analytics`). Every command that touches the
database respects the flag, so you can migrate/migrate:rollback/seed each database
without switching `orm.yaml`.
