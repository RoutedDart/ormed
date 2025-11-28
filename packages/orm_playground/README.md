# ORM Playground

This package is a miniature app that exercises the routed ORM end-to-end. It
ships with:

- A pre-populated `database/migrations.dart` registry.
- An `orm.yaml` configuration that points at `database.sqlite`.
- A demo entrypoint (`bin/orm_playground.dart`) that lists users via
  `OrmConnection.table('users')`.

## Running migrations

From the workspace root you can run the CLI against this package without
changing directories by pointing `--config` at the bundled `orm.yaml`:

```bash
dart run packages/orm/ormed_cli/bin/orm.dart apply --config orm_playground/orm.yaml
# Run a single seeder (defaults to DatabaseSeeder when omitted)
dart run packages/orm/ormed_cli/bin/orm.dart seed --config orm_playground/orm.yaml --class DatabaseSeeder
# Run multiple seeders in sequence, Laravel style
dart run packages/orm/ormed_cli/bin/orm.dart seed --config orm_playground/orm.yaml --class DatabaseSeeder --class DemoContentSeeder
```

Use `status`/`rollback` the same way (just swap the subcommand). The `seed`
subcommand replays the bundled seeders in order—pass `--class Foo --class Bar`
to mirror Laravel’s `call([Foo::class, Bar::class])` behavior.

## Exploring the data

After the schema exists, run the playground binary to inspect rows:

```bash
cd orm_playground
dart run bin/orm_playground.dart
# Seed a specific set of classes before running the demo
dart run bin/orm_playground.dart --seed DemoContentSeeder --seed ExtraSeeder
```

By default the SQLite database lives at `orm_playground/database.sqlite`. Set
`PLAYGROUND_DB=/absolute/path/to/db.sqlite` before running the binary if you
want to point at a different file.

### Multi-tenant demo

The package now defines `default` and `analytics` connections in `orm.yaml`
and exposes `bin/multi_tenant_demo.dart` to highlight how to bind multiple
databases. After applying migrations against each tenant, run:

```bash
dart run packages/orm/ormed_cli/bin/orm.dart apply --config orm_playground/orm.yaml
dart run packages/orm/ormed_cli/bin/orm.dart apply \
  --config orm_playground/orm.yaml \
  --connection analytics
dart run bin/multi_tenant_demo.dart
```

The script seeds whichever connection is empty and prints per-tenant user
counts so you can see tenant-specific data without touching `Model` classes.

`PlaygroundDatabase` now loads `orm.yaml` and automatically registers every
defined connection using `registerConnectionsFromConfig`. Calling
`PlaygroundDatabase.open(tenant: ...)` simply resolves the requested tenant from
the configuration, so the sample apps always use the same connection names as
the CLI.
