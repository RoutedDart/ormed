# ormed_postgres

PostgreSQL adapter for the routed ORM driver interface. It implements the
`DriverAdapter` contract, compiling `QueryPlan`s into SQL and executing them via
`package:postgres` (v3).

## Usage

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';

Future<void> main() async {
  final adapter = PostgresDriverAdapter.fromUrl(
    'postgres://postgres:postgres@localhost:6543/orm_test',
  );
  final registry = ModelRegistry()..register(UserOrmDefinition.definition);
  final context = QueryContext(
    registry: registry,
    driver: adapter,
    codecRegistry: adapter.codecs,
  );

  await adapter.executeRaw(
    'CREATE TABLE IF NOT EXISTS users '
    '(id SERIAL PRIMARY KEY, email TEXT NOT NULL, active BOOLEAN NOT NULL)',
  );

  await context.repository<User>().insert(
    const User(id: 1, email: 'alice@example.com', active: true),
  );

  final users = await context.query<User>().get();
  print(users.first.email);
  await adapter.close();
}
```

## Local Postgres via Docker Compose

A ready-to-use Docker Compose setup lives at `packages/orm/ormed_postgres/docker-compose.yml`.

```bash
# Start the Postgres container
docker compose -f packages/orm/ormed_postgres/docker-compose.yml up -d

# Point the test suite at the container
export POSTGRES_URL="postgres://postgres:postgres@localhost:6543/orm_test"

# Run the adapter tests
dart test packages/orm/ormed_postgres

# Tear everything down when finished
docker compose -f packages/orm/ormed_postgres/docker-compose.yml down -v
```

## Testing Helpers

- `executeRaw` lets tests run schema/migration statements during setup.
- `QueryContext.repository<T>()` provides insert helpers so fixtures can be
  created without handwritten SQL.
- `PostgresTestHarness.connect()` (see `test/support/postgres_harness.dart`)
  spins up a clean schema for integration tests and respects the `POSTGRES_URL`
  environment variable.
