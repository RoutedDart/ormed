// Observability examples for documentation
// ignore_for_file: unused_local_variable

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart' as dotel;
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

import '../models/user.dart';
import '../models/user.orm.dart';
import '../models/post.dart';
import '../models/post.orm.dart';
import 'package:ormed_examples/src/database/orm_registry.g.dart';

// #region opentelemetry
Future<OrmDatabase> openDatabaseWithTracing() async {
  await dotel.OTel.initialize(serviceName: 'catalog-api');

  return SqliteDatabase.connect(
    path: ':memory:',
    interceptors: [OrmOpenTelemetryInterceptor()],
  );
}
// #endregion opentelemetry

// #region custom-interceptor
class QueryTimingInterceptor extends QueryInterceptor {
  @override
  Future<T> intercept<T>(
    QueryExecutionContext context,
    Future<T> Function() next,
  ) async {
    final startedAt = DateTime.now();
    try {
      return await next();
    } finally {
      final elapsed = DateTime.now().difference(startedAt);
      print('${context.operationName} took ${elapsed.inMilliseconds}ms');
    }
  }
}
// #endregion custom-interceptor

// #region query-logging
Future<void> queryLoggingExample() async {
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'primary',
      driver: SqliteDriverAdapter.inMemory(),
      entities: generatedOrmModelDefinitions,
      logging: true, // Enable query logging
    ),
  );
  await dataSource.init();

  // Execute queries...
  await dataSource.query<$User>().get();

  // Review the log
  for (final entry in dataSource.queryLog) {
    print('SQL: ${entry.sql}');
    print('Parameters: ${entry.parameters}');
    print('Duration: ${entry.duration}');
  }

  // Clear when done
  dataSource.flushQueryLog();
  dataSource.disableQueryLog();
}
// #endregion query-logging

// #region query-events
Future<void> queryEventsExample(DataSource dataSource) async {
  // Listen for query events
  dataSource.context.onQuery((event) {
    print('Query: ${event.preview.sql}');
    print('Duration: ${event.duration}ms');

    if (event.duration.inMilliseconds > 100) {
      print('SLOW QUERY: ${event.preview.sql}');
    }
  });

  // Execute queries
  await dataSource.query<$User>().get();
}
// #endregion query-events

// #region structured-logger
class StructuredQueryLogger {
  void log(QueryExecuted entry) {
    final logEntry = {
      'sql': entry.sql,
      'bindings': entry.bindings,
      'duration_ms': entry.time,
      'timestamp': DateTime.now().toIso8601String(),
    };
    print(logEntry);
  }
}

Future<void> structuredLoggerExample(DataSource dataSource) async {
  final logger = StructuredQueryLogger();

  dataSource.listen(logger.log);
}
// #endregion structured-logger

// #region sql-preview
Future<void> sqlPreviewExample(DataSource dataSource) async {
  // Preview SQL without executing
  final query = dataSource
      .query<$User>()
      .whereEquals('active', true)
      .orderBy('name');

  final sql = query.toSql();
  print('Generated SQL: $sql');

  // Then execute if needed
  final users = await query.get();
}
// #endregion sql-preview

// #region before-hooks
Future<void> beforeHooksExample(DataSource dataSource) async {
  final unregister = dataSource.beforeExecuting((statement) {
    print('About to execute: ${statement.sql}');
    print('With parameters: ${statement.parameters}');
  });

  await dataSource.query<$User>().get();
  unregister();
}
// #endregion before-hooks

// #region on-query-logged
void onQueryLoggedExample(OrmConnection connection) {
  connection.listen((entry) {
    print('SQL: ${entry.sql} (${entry.time}ms)');
  });
}
// #endregion on-query-logged

// #region before-executing
void beforeExecutingExample(OrmConnection connection) {
  final unregister = connection.beforeExecuting((statement) {
    print('[SQL] ${statement.sqlWithBindings}');
    print('Type: ${statement.type}'); // query or mutation
    print('Connection: ${statement.connectionName}');
  });

  // Later, unregister
  unregister();
}
// #endregion before-executing

// #region slow-query-detection
void slowQueryDetectionExample(OrmConnection connection) {
  connection.whenQueryingForLongerThan(Duration(milliseconds: 100), (event) {
    print('Slow query: ${event.statement.sql}');
    print('Duration: ${event.duration.inMilliseconds}ms');
  });
}
// #endregion slow-query-detection

// #region pretend-mode
Future<void> pretendModeExample(DataSource ds, User user, Post post) async {
  final captured = await ds.pretend(() async {
    await ds.repo<$User>().insert(user);
    await ds.repo<$Post>().insert(post);
  });

  for (final entry in captured) {
    print('Would execute: ${entry.sql}');
  }
  // No actual database changes made
}
// #endregion pretend-mode

// #region tracing-integration
Future<OrmDatabase> tracingIntegrationExample() async {
  await dotel.OTel.initialize(serviceName: 'catalog-api');
  return SqliteDatabase.connect(
    path: ':memory:',
    interceptors: [
      OrmOpenTelemetryInterceptor(
        includeParameterCount: true,
        includeSql: false,
      ),
      QueryTimingInterceptor(),
    ],
  );
}
// #endregion tracing-integration

// #region metrics-integration
void metricsIntegrationExample(QueryContext context, Metrics metrics) {
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
}

// Placeholder metrics interface
abstract class Metrics {
  void histogram(String name, int value);
  void increment(String name, [int value = 1]);
}
// #endregion metrics-integration

// #region slow-query-monitoring
void slowQueryMonitoringExample(QueryContext context) {
  context.onQuery((event) {
    if (event.duration > Duration(milliseconds: 100)) {
      print('Slow query detected: ${event.preview.sql}');
      print('Duration: ${event.duration.inMilliseconds}ms');
    }
  });
}
// #endregion slow-query-monitoring

// #region printing-helper
void printingHelperExample(QueryContext context) {
  // For development or when piping logs to stdout:
  // StructuredQueryLogger.printing(pretty: true).attach(context);
}
// #endregion printing-helper
