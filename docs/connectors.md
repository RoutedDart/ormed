# Connection Factory & Connectors

Connectors are responsible for creating physical database connections while the
`OrmConnectionFactory` (in `orm_core`) wraps `ConnectionManager` and returns
disposable handles. Driver packages expose helpers like
`registerSqliteOrmConnection` that internally delegate to the same factory, so
applications can bootstrap connections without rewriting CLI logic.

```dart
final registry = ModelRegistry()..register(UserOrmDefinition.definition);
final factory = OrmConnectionFactory();
final handle = factory.register(
  name: 'primary',
  connection: const ConnectionConfig(name: 'primary'),
  builder: (_) {
    final adapter = SqliteDriverAdapter.custom(
      config: const DatabaseConfig(
        driver: 'sqlite',
        options: {'path': 'database.sqlite'},
      ),
    );
    return OrmConnection(
      config: const ConnectionConfig(name: 'primary'),
      driver: adapter,
      registry: registry,
    );
  },
);
```

When you no longer need the connection, call `await handle.dispose()`—this
unregisters it from the manager and closes cached drivers.

## Configuration Model

```dart
const config = DatabaseConfig(
  driver: 'sqlite',
  options: {'path': 'database/app.db'},
  replicas: [
    DatabaseEndpoint(driver: 'sqlite', options: {'path': 'replica.db'}),
  ],
);
```

- `driver` - Logical driver identifier.
- `options` - Driver-specific map (paths, hosts, usernames, etc.).
- `name` - Optional label for observability.
- `replicas` - Optional list of read replica endpoints; the factory selects one
  at random when `ConnectionRole.read` is requested.

## ConnectionFactory

```dart
final factory = ConnectionFactory(connectors: {
  'sqlite': () => SqliteConnector(),
});

final handle = await factory.open(config);
final database = handle.client; // backend-specific client
await handle.close();
```

- `register(driver, builder)` - add connectors at runtime.
- `open(config, role: ConnectionRole.primary)` - returns a `ConnectionHandle`
  that wraps the underlying client and knows how to close it.

## OrmConnection & ConnectionManager

Once the low-level connector is ready you rarely interact with raw handles.
Instead, build an `OrmConnection` that wraps the driver, registry, codecs, and
scope registry:

```dart
final registry = ModelRegistry()..registerAll([UserOrmDefinition.definition]);
final adapter = SqliteDriverAdapter.memory();
final connection = OrmConnection(
  config: ConnectionConfig(
    name: 'primary',
    database: 'app.db',
    defaultSchema: 'main',
    tableAliasStrategy: TableAliasStrategy.incremental,
  ),
  driver: adapter,
  registry: registry,
);

final users = await connection.query<User>().get();
final logs = await connection
    .table('logs', scopes: ['tenant'])
    .mapRows(LogEntry.fromMap)
    .getMapped();
```

`OrmConnection` exposes the same helpers as `QueryContext` (`query`,
`repository`, `table`) while layering on pretend mode, query logging, and
connection metadata. Hydrated models automatically retain a reference to the
connection resolver so lazy relations keep working—no more manual resolver
plumbing inside repositories or eager loaders.

For apps with multiple databases, use `ConnectionManager` to register named
connections once and resolve them by role (primary/read/write):

```dart
final manager = ConnectionManager();
manager.register(
  'analytics',
  ConnectionConfig(name: 'analytics'),
  (config) => OrmConnection(
    config: config,
    driver: sqliteAdapter,
    registry: registry,
  ),
);

final analytics = manager.connection('analytics');
await manager.use('analytics', (conn) async {
  await conn
      .table('events', scopes: ['tenant'])
      .mapRows(EventRow.fromMap)
      .streamMapped()
      .forEach(processEvent);
});

// disposable connections
await manager.use('read-replica', role: ConnectionRole.read, (conn) async {
  await conn.table('event_rollups').whereGreaterThan('id', 0).describeQuery();
});
```

Managers can register role-specific factories (`role: ConnectionRole.read`) and
fall back to the default connection when a role is missing. `use` and
`useSync` helpers build transient connections and run your callback, ensuring
release hooks fire for disposable handles. The static
`ConnectionManager.defaultManager` is available for frameworks that need a
shared registry.

Each driver package exposes a helper to simplify registration:

```dart
final handle = registerSqliteOrmConnection(
  name: 'analytics-sqlite',
  database: const DatabaseConfig(driver: 'sqlite', options: {'memory': true}),
  registry: registry,
);

registerMySqlOrmConnection(...);
registerPostgresOrmConnection(...);
registerMongoOrmConnection(
  name: 'analytics-mongo',
  database: const DatabaseConfig(
    driver: 'mongo',
    options: {'url': 'mongodb://localhost:27017', 'database': 'orm_test'},
  ),
  registry: registry,
);

final conn = OrmConnection.fromManager('analytics-sqlite');
await handle.dispose(); // unregister when no longer needed
```

Helpers accept optional `ConnectionManager`, `ConnectionConfig`, and
`ValueCodecRegistry` arguments, making it straightforward to mirror Laravel’s
`config/database.php` experience inside routed applications.

`ConnectionConfig` also accepts ad-hoc query hints:

- `defaultSchema` automatically applies when calling `connection.table()`
  without specifying a schema.
- `tableAliasStrategy` controls alias generation for raw tables (`none`,
  `tableName`, or `incremental`), eliminating repetitive `as: '...'`
  arguments.

## Connection Instrumentation

`OrmConnection` mirrors Laravel’s instrumentation helpers so you can observe
database activity without patching drivers:

- `beforeExecuting((statement) { ... })` fires for every query or mutation,
  providing an `ExecutingStatement` with the SQL, bindings, and connection
  metadata. The returned disposer removes the hook to avoid overhead.
- `whenQueryingForLongerThan(Duration threshold, handler)` reports statements
  whose wall-clock duration meets the threshold. The `LongRunningQueryEvent`
  contains the elapsed time, the original `ExecutingStatement`, and any driver
  error.
- `pretend(() async { ... })` runs a block without touching the database and
  returns the generated `QueryLogEntry` list. This is ideal for tests or admin
  tools that need to inspect SQL safely.

All hooks route through `QueryContext`, so registering them on
`OrmConnection` automatically scopes instrumentation to the active driver and
registry.

## ConnectionHandle

`ConnectionHandle<T>` carries:

- `client` - The backend-specific object (e.g., sqlite3 `Database`).
- `metadata` - `ConnectionMetadata(driver, role, description)` for logging.
- `close()` - Invokes the connector's `onClose` hook once.

## Built-in SqliteConnector

Located at `ormed_sqlite/lib/src/sqlite_connector.dart`, it supports:

- `options['memory'] == true` - opens an in-memory database.
- `options['path']` - opens/creates a file-backed database.

`SqliteDriverAdapter` now depends on the factory:

```dart
final adapter = SqliteDriverAdapter.custom(
  config: const DatabaseConfig(driver: 'sqlite', options: {'path': 'app.db'}),
  connections: factory,
);
```

It caches the primary handle internally but still uses the factory to resolve
new connections (enabling future pooling/read replica support).

## Observability Hooks

Each connector can emit events before/after establishing connections by wrapping
`ConnectionHandle` creation. Combined with `StructuredQueryLogger`, you can log
connection metadata (driver, role, description) alongside query events.

## Extending with New Drivers

Implement the `Connector<TClient>` interface:

```dart
class PostgresConnector extends Connector<PostgresConnection> {
  @override
  Future<ConnectionHandle<PostgresConnection>> connect(
    DatabaseEndpoint endpoint,
    ConnectionRole role,
  ) async {
    final conn = await PostgresConnection.open(endpoint.options);
    return ConnectionHandle(
      client: conn,
      metadata: ConnectionMetadata(
        driver: endpoint.driver,
        role: role,
        description: endpoint.name,
      ),
      onClose: () => conn.close(),
    );
  }
}
```

Register it (`factory.register('postgres', () => PostgresConnector())`), and all
higher-level code (repositories, migrations, CLI) can immediately consume it.

## Compatibility

`QueryContext` construction remains valid. `OrmConnection` is a thin wrapper
that forwards to the same context while layering on connection metadata,
pretend mode, and logging hooks. You can migrate gradually: start by plugging
existing contexts into `OrmConnection` (or registering them with
`ConnectionManager`) and expand usage as new features require richer metadata.

Existing code that instantiates `QueryContext` directly continues to work, but
once you switch to `OrmConnection`, models hydrated through repositories and
query builders will automatically expose the active connection via
`ModelConnection`.
