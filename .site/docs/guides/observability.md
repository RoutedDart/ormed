---
sidebar_position: 3
---

# Observability

The ORM exposes structured hooks for every query and mutation so you can ship metrics, traces, and logs without patching driver code.

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

### QueryEvent Fields

| Field | Description |
| --- | --- |
| `plan` | `QueryPlan` executed against the driver |
| `preview` | `StatementPreview` with SQL text |
| `duration` | Wall-clock `Duration` for the execution |
| `rows` | Number of rows returned |
| `error` / `stackTrace` | Populated when the driver threw |
| `succeeded` | `true` when no error occurred |

### MutationEvent Fields

| Field | Description |
| --- | --- |
| `plan` | `MutationPlan` (operation, rows, returning flag) |
| `preview` | SQL preview for the mutation |
| `duration` | Execution time |
| `affectedRows` | Driver-reported row count |
| `error` / `stackTrace` | Failure context |
| `succeeded` | Indicates success |

## StructuredQueryLogger

Attach a structured logger for JSON-friendly output:

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

For failed queries, the logger adds `error_type`, `error_message`, and (optionally) `stack_trace`.

### Printing Helper

For development or when piping logs to stdout:

```dart
StructuredQueryLogger.printing(pretty: true).attach(context);
```

## SQL Preview Without Execution

Use `Query.toSql()` to inspect queries before running them:

```dart
final preview = context
    .query<$User>()
    .whereEquals('active', true)
    .limit(5)
    .toSql();

print(preview.sql);       // SELECT "id", ...
print(preview.parameters); // [1, 5]
```

Mutation previews are available via repository helpers (`previewInsert`, `previewUpdateMany`, etc.) and `context.describeMutation()`.

## Connection Instrumentation

`OrmConnection` provides additional hooks:

### beforeExecuting

```dart
final unregister = connection.beforeExecuting((statement) {
  print('[SQL] ${statement.sqlWithBindings}');
});

// Later, unregister
unregister();
```

### Slow Query Detection

```dart
connection.whenQueryingForLongerThan(
  Duration(milliseconds: 100),
  (event) {
    logger.warning('Slow query: ${event.statement.sql}');
    logger.warning('Duration: ${event.elapsed.inMilliseconds}ms');
  },
);
```

### Pretend Mode

Preview SQL without executing:

```dart
final statements = await connection.pretend(() async {
  await connection.repo<$User>().insert(
    $User(id: 0, email: 'test@example.com'),
  );
});

for (final entry in statements) {
  print('Would execute: ${entry.sql}');
}
// No actual database changes
```

## Integration with Tracing

Use event hooks to create tracing spans:

```dart
context.onQuery((event) {
  final span = tracer.startSpan('db.query')
    ..setAttribute('db.statement', event.preview.sql)
    ..setAttribute('db.system', 'sqlite');
  
  if (event.succeeded) {
    span.end();
  } else {
    span.recordException(event.error!, event.stackTrace);
    span.setStatus(SpanStatus.error);
    span.end();
  }
});
```

## Metrics Integration

Send query metrics to your monitoring service:

```dart
context.onQuery((event) {
  metrics.histogram('db.query.duration', event.duration.inMicroseconds);
  metrics.increment('db.query.count');
  
  if (!event.succeeded) {
    metrics.increment('db.query.errors');
  }
});

context.onMutation((event) {
  metrics.histogram('db.mutation.duration', event.duration.inMicroseconds);
  metrics.increment('db.mutation.affected_rows', event.affectedRows);
});
```

## Best Practices

- **Attach early** – Add event listeners as soon as the `QueryContext` is created to capture migrations, seed data, and runtime queries.

- **Protect secrets** – Disable `includeParameters` or scrub entries inside `onLog` for columns that may contain PII.

- **Correlate with tracing** – Use `onQuery`/`onMutation` to start tracing spans using the SQL preview and duration data.

- **Monitor slow queries** – Register a listener that warns when `event.duration` exceeds your SLO.

```dart
context.onQuery((event) {
  if (event.duration > Duration(milliseconds: 100)) {
    logger.warning('Slow query detected', {
      'sql': event.preview.sql,
      'duration_ms': event.duration.inMilliseconds,
    });
  }
});
```
