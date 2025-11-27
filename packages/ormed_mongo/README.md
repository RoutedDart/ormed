# ormed_mongo

MongoDB driver for the routed ORM project. Includes a lightweight adapter plus helpers for compiling {@link QueryPlan}s and {@link MutationPlan}s into MongoDB commands.

## Getting Started

1. Run `just docker-up` (calls `docker compose up -d`) inside this directory to start a Mongo container (see `docker-compose.yml`).
2. Configure a connection:
   ```dart
   final adapter = MongoDriverAdapter.custom(
     config: const DatabaseConfig(
       driver: 'mongo',
       options: {
         'url': 'mongodb://localhost:27017',
         'database': 'orm_test',
       },
     ),
   );
   ```
3. Optionally register the adapter via `registerMongoOrmConnection` to keep it in a shared `ConnectionManager`:

```dart
final handle = registerMongoOrmConnection(
  name: 'mongo-main',
  database: const DatabaseConfig(
    driver: 'mongo',
    options: {'url': 'mongodb://localhost:27017', 'database': 'orm_test'},
  ),
  registry: ModelRegistry()..register(UserOrmDefinition.definition),
);
```
`handle` exposes `context`/`driver` helpers (same as other driver helpers) and closes the adapter when disposed.

4. Use `QueryContext`/`Repository` as usual with ORM models.

## Testing

Start the Mongo container once before running the tests:

```bash
just docker-up
```

Then run the Dart suite (the `just test` recipe now assumes the container is
already available and reads connection info via `MONGO_URL` / `MONGO_DATABASE`):

```bash
MONGO_URL=mongodb://root:example@localhost:27017/?authSource=admin \
MONGO_DATABASE=orm_test \
just test
```

When you're done hacking on the driver, tear the compose stack down with:

```bash
just docker-down
```
