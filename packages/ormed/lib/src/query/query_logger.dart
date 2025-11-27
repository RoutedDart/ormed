import 'dart:convert';

import '../driver/driver.dart';
import '../model_definition.dart';
import 'query.dart';

/// Serializes query + mutation events into structured log entries.
class StructuredQueryLogger {
  StructuredQueryLogger({
    required void Function(Map<String, Object?> entry) onLog,
    this.includeParameters = true,
    this.includeStackTrace = false,
    Map<String, Object?>? attributes,
    DateTime Function()? clock,
  }) : _onLog = onLog,
       _attributes = attributes ?? const {},
       _clock = clock ?? DateTime.now;

  /// Convenience helper that prints JSON to stdout.
  factory StructuredQueryLogger.printing({bool pretty = false}) {
    final encoder = pretty
        ? const JsonEncoder.withIndent('  ')
        : const JsonEncoder();
    return StructuredQueryLogger(
      onLog: (entry) {
        // ignore: avoid_print
        print(encoder.convert(entry));
      },
    );
  }

  final void Function(Map<String, Object?> entry) _onLog;
  final Map<String, Object?> _attributes;
  final DateTime Function() _clock;

  /// Whether bound SQL parameters are included in the log entry.
  final bool includeParameters;

  /// Whether stack traces are serialized when errors occur.
  final bool includeStackTrace;

  /// Subscribes to [context] query + mutation events.
  void attach(QueryContext context) {
    context.onQuery(_handleQuery);
    context.onMutation(_handleMutation);
  }

  void _handleQuery(QueryEvent event) {
    _onLog(
      _serialize(
        kind: 'query',
        preview: event.preview,
        duration: event.duration,
        definition: event.plan.definition,
        rowCount: event.rows,
        error: event.error,
        stackTrace: event.stackTrace,
        extra: {
          'success': event.succeeded,
          if (event.connectionName != null) 'connection': event.connectionName,
          if (event.connectionDatabase != null)
            'connection_database': event.connectionDatabase,
          if (event.connectionTablePrefix != null)
            'connection_table_prefix': event.connectionTablePrefix,
        },
      ),
    );
  }

  void _handleMutation(MutationEvent event) {
    _onLog(
      _serialize(
        kind: 'mutation',
        preview: event.preview,
        duration: event.duration,
        definition: event.plan.definition,
        rowCount: event.affectedRows,
        error: event.error,
        stackTrace: event.stackTrace,
        extra: {
          'operation': event.plan.operation.name,
          'returning': event.plan.returning,
          'success': event.succeeded,
          if (event.connectionName != null) 'connection': event.connectionName,
          if (event.connectionDatabase != null)
            'connection_database': event.connectionDatabase,
          if (event.connectionTablePrefix != null)
            'connection_table_prefix': event.connectionTablePrefix,
        },
      ),
    );
  }

  Map<String, Object?> _serialize({
    required String kind,
    required StatementPreview preview,
    required Duration duration,
    required ModelDefinition<dynamic> definition,
    required Object? rowCount,
    required Object? error,
    required StackTrace? stackTrace,
    Map<String, Object?>? extra,
  }) {
    final entry = <String, Object?>{
      'type': kind,
      'timestamp': _clock().toUtc().toIso8601String(),
      'model': definition.modelName,
      'table': definition.tableName,
      'schema': definition.schema,
      'sql': preview.sql,
      'statement_payload': preview.payload.toJson(),
      'duration_ms': duration.inMicroseconds / 1000,
      if (rowCount != null) 'row_count': rowCount,
      if (includeParameters && preview.parameters.isNotEmpty)
        'parameters': preview.parameters,
      if (includeParameters && preview.parameterSets.isNotEmpty)
        'parameter_sets': preview.parameterSets,
      ..._attributes,
      ...?extra,
    };

    if (error != null) {
      entry['error_type'] = error.runtimeType.toString();
      entry['error_message'] = error.toString();
      if (includeStackTrace && stackTrace != null) {
        entry['stack_trace'] = stackTrace.toString();
      }
    }

    return entry;
  }
}
