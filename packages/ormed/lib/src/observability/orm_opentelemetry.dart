import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart' as dotel;

import '../query/query_interceptor.dart';

/// Creates OpenTelemetry database spans for Ormed execution.
///
/// Initialize `dartastic_opentelemetry` once in the application before issuing
/// queries, then install this interceptor on `DataSourceOptions`,
/// `OrmDatabase.connect`, or a driver-specific direct connection helper:
///
/// ```dart
/// await dotel.OTel.initialize(serviceName: 'catalog-api');
/// final db = await OrmDatabase.connect(
///   driver: driver,
///   interceptors: [OrmOpenTelemetryInterceptor()],
/// );
/// ```
///
/// SQL text is excluded by default because it may contain sensitive schema or
/// application details. Set [includeSql] to `true` when the deployment's
/// telemetry policy allows it.
class OrmOpenTelemetryInterceptor extends QueryInterceptor {
  /// Creates an OpenTelemetry interceptor.
  ///
  /// [tracer] may be supplied when an application uses a named or test tracer;
  /// otherwise the global tracer from `OTel.tracer()` is used.
  OrmOpenTelemetryInterceptor({
    this.tracer,
    this.includeSql = false,
    this.includeParameterCount = true,
    this.spanNamePrefix = 'ormed.db',
    this.spanKind = dotel.SpanKind.client,
  });

  /// An explicitly selected tracer, or `null` to use the global tracer.
  final dotel.Tracer? tracer;

  /// Whether to include the SQL statement as `db.query.text`.
  final bool includeSql;

  /// Whether to include the number of bound parameters.
  final bool includeParameterCount;

  /// Prefix used for generated span names.
  final String spanNamePrefix;

  /// Span kind used for database operations.
  final dotel.SpanKind spanKind;

  dotel.Tracer get _resolvedTracer => tracer ?? dotel.OTel.tracer();

  @override
  Future<T> intercept<T>(
    QueryExecutionContext context,
    Future<T> Function() next,
  ) async {
    final tracer = _resolvedTracer;
    final span = tracer.startSpan(
      _spanName(context),
      kind: spanKind,
      attributes: dotel.OTel.attributesFromList(_attributesFor(context)),
    );

    try {
      return await tracer.withSpanAsync(span, next);
    } finally {
      if (!span.isEnded) {
        span.end();
      }
    }
  }

  String _spanName(QueryExecutionContext context) {
    final collection = context.collectionName;
    if (collection == null || collection.isEmpty) {
      return '$spanNamePrefix.${context.operationName.toLowerCase()}';
    }
    return '$spanNamePrefix.${context.operationName.toLowerCase()} $collection';
  }

  List<dotel.Attribute> _attributesFor(QueryExecutionContext context) {
    final attributes = <dotel.Attribute>[
      dotel.OTel.attributeString('db.system', context.driverName),
      dotel.OTel.attributeString('db.operation.name', context.operationName),
      dotel.OTel.attributeString('db.query.summary', context.querySummary),
    ];
    final connectionName = context.connectionName;
    if (connectionName != null && connectionName.isNotEmpty) {
      attributes.add(
        dotel.OTel.attributeString('ormed.connection.name', connectionName),
      );
    }
    final database = context.database;
    if (database != null && database.isNotEmpty) {
      attributes.add(dotel.OTel.attributeString('db.namespace', database));
    }
    final collectionName = context.collectionName;
    if (collectionName != null && collectionName.isNotEmpty) {
      attributes.add(
        dotel.OTel.attributeString('db.collection.name', collectionName),
      );
    }
    final transactionId = context.transactionId;
    if (transactionId != null && transactionId.isNotEmpty) {
      attributes.add(
        dotel.OTel.attributeString('ormed.transaction.id', transactionId),
      );
    }
    if (includeParameterCount) {
      attributes.add(
        dotel.OTel.attributeInt(
          'db.operation.parameter_count',
          context.parameters.length,
        ),
      );
    }
    if (includeSql) {
      attributes.add(dotel.OTel.attributeString('db.query.text', context.sql));
    }
    return attributes;
  }
}
