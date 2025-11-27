# Observability

The ORM exposes structured hooks for every query and mutation so you can ship
metrics, traces, and logs without patching driver code. Observability is built
around three primitives:

1. **Statement preview** (`StatementPreview`) – Generated via `Query.toSql()`,
   `QueryContext.describeQuery`, and `QueryContext.describeMutation`.
2. **Events** – `QueryContext` emits `QueryEvent` and `MutationEvent` payloads
   before returning results or when an error occurs.
3. **StructuredQueryLogger** – Convenience logger that translates events into
   JSON-friendly maps (or prints them) with optional attributes.

## Query & Mutation Events

Register listeners on the `QueryContext`:

```dart
final context = QueryContext(registry: registry, driver: adapter);

context.onQuery((event) {
  print('[query] ${event.preview.sql} took ${event.duration}');
});

context.onMutation((event) {
  if (!event.succeeded) {
    errorReporter.capture(event.error, event.stackTrace);
  }
});
```

### QueryEvent fields

| Field | Description |
| --- | --- |
| `plan` | `QueryPlan` executed against the driver (filters, orders, relations). |
| `preview` | `StatementPreview` returned by the driver (SQL text or driver-specific payload). |
| `duration` | Wall-clock `Duration` for the execution. |
| `rows` | Number of rows returned (if the driver reported it). |
| `error` / `stackTrace` | Populated when the driver threw. |
| `succeeded` | `true` when no error occurred. |

### MutationEvent fields

| Field | Description |
| --- | --- |
| `plan` | `MutationPlan` (operation, rows, returning flag). |
| `preview` | SQL preview for the mutation. |
| `duration` | Execution time. |
| `affectedRows` | Driver-reported row count. |
| `error` / `stackTrace` | Failure context. |
| `succeeded` | Indicates success. |

Use these hooks to emit custom metrics, raise alerts, or enrich tracing spans.

## StructuredQueryLogger

`StructuredQueryLogger` listens to the events above and produces structured log
entries. Attach it once per context:

```dart
StructuredQueryLogger(
  onLog: (entry) => observability.log('orm', entry),
  includeParameters: false, // hide sensitive data
  includeStackTrace: true,
  attributes: {'service': 'api', 'env': 'prod'},
).attach(context);
```

Each entry contains:

```json
{
  "type": "query",
  "timestamp": "2025-01-01T12:00:00.000Z",
  "model": "User",
  "table": "users",
  "sql": "SELECT \"id\" FROM \"users\" WHERE \"email\" = ?",
  "parameters": ["alice@example.com"],
  "duration_ms": 1.23,
  "success": true,
  "env": "prod"
}
```

For failed queries the logger adds `error_type`, `error_message`, and (optionally)
`stack_trace` if `includeStackTrace` is `true`.

### Printing helper

```dart
StructuredQueryLogger.printing(pretty: true).attach(context);
```

Useful during development or when piping logs directly to stdout/stderr.

## SQL Preview Without Execution

Use `Query.toSql()` to inspect queries before running them:

```dart
final preview = context
    .query<User>()
    .whereEquals('active', true)
    .limit(5)
    .toSql();
print(preview.sql);       // SELECT "id", ...
print(preview.parameters); // [1, 5]
```

Mutation previews are available via repository helpers (`previewInsert`,
`previewUpdateMany`, etc.) and the context’s `describeMutation` API. This is
handy for migration tooling and dry runs.

## Best Practices

- **Attach early** – Add event listeners or `StructuredQueryLogger` as soon as
  the `QueryContext` is created so you capture migrations, seed data, and runtime
  queries.
- **Protect secrets** – Disable `includeParameters` or scrub entries inside
  `onLog` for columns that may contain PII.
- **Correlate with tracing** – Use `onQuery`/`onMutation` to start tracing spans
  (OpenTelemetry, Datadog, etc.) using the SQL preview and duration data.
- **Forward to routed observability** – When running inside the routed runtime,
  forward entries to the `ObservabilityServiceProvider` so they appear alongside
  HTTP request logs.
- **Monitor slow queries** – Register a listener that warns when
  `event.duration` exceeds your SLO, and include the `preview.sql`/parameters
  for debugging.

## Routed Observability Adapter

When the ORM runs inside the routed engine, the `ObservabilityServiceProvider`
registers an `OrmQueryTelemetry` singleton that already knows how to emit
structured query events and tracing spans. Resolve it from the container and
attach it to every `QueryContext` that the application creates:

```dart
final telemetry = await engine.container.make<OrmQueryTelemetry>();
telemetry.attach(context, dataSource: 'primary');
```

Telemetry inherits the observability settings under `observability.orm`:

```yaml
observability:
  orm:
    enabled: true
    include_parameters: false  # flip to true only when parameters are safe to log
    attributes:
      subsystem: orm
      env: ${APP_ENV}
```

The adapter automatically decorates tracing spans with driver metadata (system,
data source, model, row counts, etc.) so database activity is correlated with
HTTP spans. You can still add additional `StructuredQueryLogger` listeners when
you need to persist entries somewhere else, but most applications can rely on
this shared telemetry binding.
