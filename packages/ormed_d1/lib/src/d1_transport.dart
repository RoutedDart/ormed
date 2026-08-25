library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'd1_binding.dart';

class D1RequestException implements Exception {
  const D1RequestException(this.message);

  final String message;

  @override
  String toString() => message;
}

class D1Statement {
  const D1Statement({required this.sql, this.parameters = const []});

  final String sql;
  final List<Object?> parameters;

  Map<String, Object?> toJson() => {'sql': sql, 'params': parameters};
}

class D1StatementResult {
  const D1StatementResult({
    this.success = true,
    this.rows = const <Map<String, Object?>>[],
    this.meta = const <String, Object?>{},
    this.error,
  });

  final bool success;
  final List<Map<String, Object?>> rows;
  final Map<String, Object?> meta;
  final Object? error;

  int get affectedRows {
    final changes =
        meta['changes'] ?? meta['rows_written'] ?? meta['rowsAffected'];
    if (changes is num) return changes.toInt();
    if (changes is String) return int.tryParse(changes) ?? 0;
    return 0;
  }

  int? get lastRowId {
    final value = meta['last_row_id'] ?? meta['lastRowId'];
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

abstract class D1Transport {
  Future<D1StatementResult> query(
    String sql, [
    List<Object?> parameters = const [],
  ]);

  Future<D1StatementResult> execute(
    String sql, [
    List<Object?> parameters = const [],
  ]);

  Future<void> close() async {}
}

/// Optional capability for transports that can preserve D1 batch atomicity.
abstract interface class D1BatchTransport {
  /// Executes statements as one atomic batch.
  Future<List<D1StatementResult>> batch(Iterable<D1Statement> statements);
}

/// Adapts a native Cloudflare D1 binding to Ormed's driver transport.
final class D1BindingTransport implements D1Transport, D1BatchTransport {
  /// Creates a transport over a native D1 binding.
  const D1BindingTransport(this.database);

  /// The binding used by this transport.
  final D1DatabaseBinding database;

  @override
  Future<D1StatementResult> query(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final result = await database
        .prepare(sql)
        .bind(parameters)
        .all<Map<String, Object?>>(decode: (row) => row);
    return _statementResult(result);
  }

  @override
  Future<D1StatementResult> execute(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final result = await database
        .prepare(sql)
        .bind(parameters)
        .run<Map<String, Object?>>(decode: (row) => row);
    return _statementResult(result);
  }

  @override
  Future<List<D1StatementResult>> batch(
    Iterable<D1Statement> statements,
  ) async {
    final prepared = [
      for (final statement in statements)
        database.prepare(statement.sql).bind(statement.parameters),
    ];
    final results = await database.batch<Map<String, Object?>>(prepared);
    return results.map(_statementResult).toList(growable: false);
  }

  @override
  Future<void> close() async {}

  D1StatementResult _statementResult(D1Result<Map<String, Object?>> result) {
    if (!result.success) {
      throw D1RequestException('D1 statement failed: ${result.error}');
    }
    return D1StatementResult(rows: result.results, meta: _metaMap(result.meta));
  }
}

Map<String, Object?> _metaMap(D1Meta? meta) => {
  if (meta?.duration != null) 'duration': meta!.duration,
  if (meta?.rowsRead != null) 'rows_read': meta!.rowsRead,
  if (meta?.rowsWritten != null) 'rows_written': meta!.rowsWritten,
  if (meta?.changes != null) 'changes': meta!.changes,
  if (meta?.changedDb != null) 'changed_db': meta!.changedDb,
  if (meta?.sizeAfter != null) 'size_after': meta!.sizeAfter,
  if (meta?.lastRowId != null) 'last_row_id': meta!.lastRowId,
  if (meta?.servedBy != null) 'served_by': meta!.servedBy,
  if (meta?.servedByColo != null) 'served_by_colo': meta!.servedByColo,
  if (meta?.servedByPrimary != null) 'served_by_primary': meta!.servedByPrimary,
  if (meta?.servedByRegion != null) 'served_by_region': meta!.servedByRegion,
  if (meta?.servedByLocation != null)
    'served_by_location': meta!.servedByLocation,
  if (meta?.bookmark != null) 'bookmark': meta!.bookmark,
};

class D1HttpTransport implements D1Transport, D1BatchTransport {
  D1HttpTransport({
    required this.accountId,
    required this.databaseId,
    required this.apiToken,
    this.baseUrl = 'https://api.cloudflare.com/client/v4',
    this.requestTimeout = const Duration(seconds: 30),
    this.retryBaseDelay = const Duration(milliseconds: 250),
    this.retryMaxDelay = const Duration(seconds: 3),
    int maxAttempts = 4,
    this.debugLog = false,
    this.logger,
    http.Client? client,
  }) : maxAttempts = maxAttempts < 1 ? 1 : maxAttempts,
       _client = client ?? http.Client(),
       _endpoint = null,
       _batchEndpoint = null,
       _headers = const <String, String>{};

  /// Creates a transport for an application-owned D1 HTTP endpoint.
  ///
  /// This constructor is the browser/Worker-safe path. The endpoint should
  /// be an application endpoint that authenticates the caller and executes
  /// D1 inside the Worker; a Cloudflare API token must never be shipped to a
  /// browser.
  ///
  /// The endpoint accepts `{sql, params}` and returns the Cloudflare D1
  /// result shape (`success`, `results`, and `meta`) or the management API
  /// shape (`success`, `result: [{results, meta}]`). If [batchEndpoint] is
  /// supplied, it accepts `{statements: [{sql, params}, ...]}` and returns a
  /// list of those result shapes in `results` or `result`.
  D1HttpTransport.endpoint({
    required Uri endpoint,
    Uri? batchEndpoint,
    Map<String, String> headers = const <String, String>{},
    Duration requestTimeout = const Duration(seconds: 30),
    Duration retryBaseDelay = const Duration(milliseconds: 250),
    Duration retryMaxDelay = const Duration(seconds: 3),
    int maxAttempts = 4,
    bool debugLog = false,
    void Function(String message)? logger,
    http.Client? client,
  }) : this._endpointConstructor(
         endpoint: endpoint,
         batchEndpoint: batchEndpoint,
         headers: headers,
         requestTimeout: requestTimeout,
         retryBaseDelay: retryBaseDelay,
         retryMaxDelay: retryMaxDelay,
         maxAttempts: maxAttempts,
         debugLog: debugLog,
         logger: logger,
         client: client,
       );

  D1HttpTransport._endpointConstructor({
    required this._endpoint,
    this._batchEndpoint,
    required Map<String, String> headers,
    required this.requestTimeout,
    required this.retryBaseDelay,
    required this.retryMaxDelay,
    required int maxAttempts,
    required this.debugLog,
    required this.logger,
    http.Client? client,
  }) : accountId = '',
       databaseId = '',
       apiToken = '',
       baseUrl = '',
       maxAttempts = maxAttempts < 1 ? 1 : maxAttempts,
       _client = client ?? http.Client(),
       _headers = Map.unmodifiable(headers);

  factory D1HttpTransport.fromOptions(Map<String, Object?> options) {
    final endpointValue =
        options['endpoint']?.toString() ?? options['url']?.toString();
    if (endpointValue != null && endpointValue.isNotEmpty) {
      final endpoint = Uri.tryParse(endpointValue);
      if (endpoint == null || !endpoint.hasScheme) {
        throw ArgumentError('D1 option "endpoint" must be an absolute URI.');
      }
      final batchEndpointValue =
          options['batchEndpoint']?.toString() ??
          options['batch_endpoint']?.toString();
      final batchEndpoint = batchEndpointValue == null
          ? null
          : Uri.tryParse(batchEndpointValue);
      if (batchEndpointValue != null &&
          (batchEndpoint == null || !batchEndpoint.hasScheme)) {
        throw ArgumentError(
          'D1 option "batchEndpoint" must be an absolute URI.',
        );
      }
      return D1HttpTransport.endpoint(
        endpoint: endpoint,
        batchEndpoint: batchEndpoint,
        headers: _readHeaders(options['headers']),
        maxAttempts: _readIntOption(
          options,
          keys: const ['maxAttempts', 'max_attempts', 'retryAttempts'],
          fallback: 4,
        ),
        requestTimeout: Duration(
          milliseconds: _readIntOption(
            options,
            keys: const ['requestTimeoutMs', 'request_timeout_ms', 'timeoutMs'],
            fallback: 30000,
          ),
        ),
        retryBaseDelay: Duration(
          milliseconds: _readIntOption(
            options,
            keys: const ['retryBaseDelayMs', 'retry_base_delay_ms'],
            fallback: 250,
          ),
        ),
        retryMaxDelay: Duration(
          milliseconds: _readIntOption(
            options,
            keys: const ['retryMaxDelayMs', 'retry_max_delay_ms'],
            fallback: 3000,
          ),
        ),
        debugLog: _readBoolOption(
          options,
          keys: const ['debugLog', 'debug_log', 'debug'],
          fallback: false,
        ),
      );
    }

    final accountId =
        options['accountId']?.toString() ?? options['account_id']?.toString();
    final databaseId =
        options['databaseId']?.toString() ?? options['database_id']?.toString();
    final apiToken =
        options['apiToken']?.toString() ??
        options['api_token']?.toString() ??
        options['token']?.toString();
    final baseUrl =
        options['baseUrl']?.toString() ??
        options['base_url']?.toString() ??
        'https://api.cloudflare.com/client/v4';
    final maxAttempts = _readIntOption(
      options,
      keys: const ['maxAttempts', 'max_attempts', 'retryAttempts'],
      fallback: 4,
    );
    final requestTimeoutMs = _readIntOption(
      options,
      keys: const ['requestTimeoutMs', 'request_timeout_ms', 'timeoutMs'],
      fallback: 30000,
    );
    final retryBaseDelayMs = _readIntOption(
      options,
      keys: const ['retryBaseDelayMs', 'retry_base_delay_ms'],
      fallback: 250,
    );
    final retryMaxDelayMs = _readIntOption(
      options,
      keys: const ['retryMaxDelayMs', 'retry_max_delay_ms'],
      fallback: 3000,
    );
    final debugLog = _readBoolOption(
      options,
      keys: const ['debugLog', 'debug_log', 'debug'],
      fallback: false,
    );

    if (accountId == null || accountId.isEmpty) {
      throw ArgumentError('D1 option "accountId" is required.');
    }
    if (databaseId == null || databaseId.isEmpty) {
      throw ArgumentError('D1 option "databaseId" is required.');
    }
    if (apiToken == null || apiToken.isEmpty) {
      throw ArgumentError('D1 option "apiToken" is required.');
    }

    return D1HttpTransport(
      accountId: accountId,
      databaseId: databaseId,
      apiToken: apiToken,
      baseUrl: baseUrl,
      maxAttempts: maxAttempts,
      requestTimeout: Duration(milliseconds: requestTimeoutMs),
      retryBaseDelay: Duration(milliseconds: retryBaseDelayMs),
      retryMaxDelay: Duration(milliseconds: retryMaxDelayMs),
      debugLog: debugLog,
    );
  }

  final String accountId;
  final String databaseId;
  final String apiToken;
  final String baseUrl;
  final int maxAttempts;
  final Duration requestTimeout;
  final Duration retryBaseDelay;
  final Duration retryMaxDelay;
  final bool debugLog;
  final void Function(String message)? logger;
  final http.Client _client;
  final Uri? _endpoint;
  final Uri? _batchEndpoint;
  final Map<String, String> _headers;
  final Random _random = Random();

  @override
  Future<D1StatementResult> query(
    String sql, [
    List<Object?> parameters = const [],
  ]) => _sendSingle(D1Statement(sql: sql, parameters: parameters));

  @override
  Future<D1StatementResult> execute(
    String sql, [
    List<Object?> parameters = const [],
  ]) => _sendSingle(D1Statement(sql: sql, parameters: parameters));

  @override
  Future<List<D1StatementResult>> batch(
    Iterable<D1Statement> statements,
  ) async {
    final endpoint = _batchEndpoint;
    if (endpoint == null) {
      throw UnsupportedError(
        'This D1 HTTP transport has no batch endpoint configured.',
      );
    }

    final response = await _postJson(endpoint, <String, Object?>{
      'statements': [for (final statement in statements) statement.toJson()],
    });
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw D1RequestException(
        'D1 batch request failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = _decodeObject(response.body);
    if (decoded['success'] == false) {
      throw D1RequestException('D1 batch unsuccessful: ${response.body}');
    }
    final rawResults = decoded['result'] ?? decoded['results'];
    if (rawResults is! List) {
      throw const D1RequestException('Invalid D1 batch response payload.');
    }
    return rawResults.map(_statementResultFrom).toList(growable: false);
  }

  Future<D1StatementResult> _sendSingle(D1Statement statement) async {
    final uri =
        _endpoint ??
        Uri.parse('$baseUrl/accounts/$accountId/d1/database/$databaseId/query');
    final payload = jsonEncode(statement.toJson());
    D1RequestException? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final startedAt = DateTime.now();
      _log(
        'request attempt=$attempt/$maxAttempts sql="${_summarizeSql(statement.sql)}" params=${statement.parameters.length}',
      );

      try {
        final response = await _client
            .post(uri, headers: _requestHeaders, body: payload)
            .timeout(requestTimeout);

        final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
        _log('response status=${response.statusCode} elapsed=${elapsedMs}ms');

        if (response.statusCode < 200 || response.statusCode >= 300) {
          final retryable =
              _isRetryableStatus(response.statusCode) ||
              _bodyLooksRetryable(response.body);
          final error = D1RequestException(
            'D1 request failed (${response.statusCode}): ${response.body}',
          );
          if (retryable && attempt < maxAttempts) {
            final delay = _computeRetryDelay(
              attempt,
              retryAfterHeader: response.headers['retry-after'],
            );
            _log(
              'retrying after ${delay.inMilliseconds}ms due to HTTP ${response.statusCode}',
            );
            await Future<void>.delayed(delay);
            lastError = error;
            continue;
          }
          throw error;
        }

        final decodedValue = jsonDecode(response.body);
        if (decodedValue is! Map<String, Object?>) {
          throw const D1RequestException('Invalid D1 response payload.');
        }
        final decoded = decodedValue;
        final success = decoded['success'];
        if (success == false) {
          final retryable =
              _decodedLooksRetryable(decoded) ||
              _bodyLooksRetryable(response.body);
          final error = D1RequestException(
            'D1 query unsuccessful: ${response.body}',
          );
          if (retryable && attempt < maxAttempts) {
            final delay = _computeRetryDelay(
              attempt,
              retryAfterHeader: response.headers['retry-after'],
            );
            _log(
              'retrying after ${delay.inMilliseconds}ms due to unsuccessful D1 response',
            );
            await Future<void>.delayed(delay);
            lastError = error;
            continue;
          }
          throw error;
        }

        return _statementResultFrom(decoded);
      } on TimeoutException catch (e) {
        final error = D1RequestException(
          'D1 request timed out after ${requestTimeout.inMilliseconds}ms: $e',
        );
        if (attempt < maxAttempts) {
          final delay = _computeRetryDelay(attempt);
          _log(
            'retrying after ${delay.inMilliseconds}ms due to timeout (${e.runtimeType})',
          );
          await Future<void>.delayed(delay);
          lastError = error;
          continue;
        }
        throw error;
      } on http.ClientException catch (e) {
        final error = D1RequestException('D1 client error: $e');
        if (attempt < maxAttempts) {
          final delay = _computeRetryDelay(attempt);
          _log('retrying after ${delay.inMilliseconds}ms due to client error');
          await Future<void>.delayed(delay);
          lastError = error;
          continue;
        }
        throw error;
      }
    }

    throw lastError ??
        const D1RequestException('D1 request failed without a specific error.');
  }

  Map<String, String> get _requestHeaders => {
    'Content-Type': 'application/json',
    if (_endpoint == null) 'Authorization': 'Bearer $apiToken',
    ..._headers,
  };

  Future<http.Response> _postJson(Uri uri, Object body) async {
    try {
      return await _client
          .post(uri, headers: _requestHeaders, body: jsonEncode(body))
          .timeout(requestTimeout);
    } on TimeoutException catch (error) {
      throw D1RequestException(
        'D1 request timed out after ${requestTimeout.inMilliseconds}ms: $error',
      );
    } on http.ClientException catch (error) {
      throw D1RequestException('D1 client error: $error');
    }
  }

  Map<String, Object?> _decodeObject(String body) {
    final decodedValue = jsonDecode(body);
    if (decodedValue is Map<String, Object?>) return decodedValue;
    if (decodedValue is Map) {
      return decodedValue.map((key, value) => MapEntry(key.toString(), value));
    }
    throw const D1RequestException('Invalid D1 response payload.');
  }

  D1StatementResult _statementResultFrom(Object? value) {
    if (value is! Map) {
      throw const D1RequestException('Invalid D1 statement result payload.');
    }
    final entry = value.map((key, value) => MapEntry(key.toString(), value));
    if (entry['success'] == false) {
      throw D1RequestException('D1 statement unsuccessful: $entry');
    }
    final resultEntry = entry.containsKey('result')
        ? _firstResultEntry(entry['result'])
        : entry;
    return D1StatementResult(
      rows: _rowsFrom(resultEntry['results']),
      meta: _metaFrom(resultEntry['meta']),
    );
  }

  Map<String, Object?> _firstResultEntry(Object? value) {
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, Object?>) return first;
      if (first is Map) return first.map((k, v) => MapEntry(k.toString(), v));
    }
    if (value is Map<String, Object?>) return value;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    return const <String, Object?>{};
  }

  List<Map<String, Object?>> _rowsFrom(Object? value) {
    if (value is! List) return const <Map<String, Object?>>[];
    return value
        .whereType<Map>()
        .map((entry) => entry.map((k, v) => MapEntry(k.toString(), v)))
        .toList(growable: false);
  }

  Map<String, Object?> _metaFrom(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return const <String, Object?>{};
  }

  bool _isRetryableStatus(int statusCode) {
    return statusCode == 408 ||
        statusCode == 425 ||
        statusCode == 429 ||
        statusCode >= 500;
  }

  bool _decodedLooksRetryable(Map<String, Object?> decoded) {
    final errors = decoded['errors'];
    if (errors is! List) return false;
    for (final entry in errors.whereType<Map>()) {
      final code = entry['code']?.toString() ?? '';
      final message = (entry['message']?.toString() ?? '').toLowerCase();
      if (code == '429') return true;
      if (message.contains('rate limit') ||
          message.contains('too many requests') ||
          message.contains('overloaded') ||
          message.contains('temporar') ||
          message.contains('timeout') ||
          message.contains('try again')) {
        return true;
      }
    }
    return false;
  }

  bool _bodyLooksRetryable(String body) {
    final lower = body.toLowerCase();
    return lower.contains('rate limit') ||
        lower.contains('too many requests') ||
        lower.contains('overloaded') ||
        lower.contains('temporar') ||
        lower.contains('timeout') ||
        lower.contains('retry-after') ||
        lower.contains('"429"');
  }

  Duration _computeRetryDelay(int attempt, {String? retryAfterHeader}) {
    final retryAfter = _parseRetryAfter(retryAfterHeader);
    if (retryAfter != null && retryAfter > Duration.zero) {
      return retryAfter;
    }

    final exponent = attempt <= 1 ? 0 : attempt - 1;
    final multiplier = 1 << exponent;
    final rawMs = retryBaseDelay.inMilliseconds * multiplier;
    final cappedMs = min(rawMs, retryMaxDelay.inMilliseconds);
    final jitterMs = (cappedMs * 0.25 * _random.nextDouble()).round();
    return Duration(milliseconds: cappedMs + jitterMs);
  }

  Duration? _parseRetryAfter(String? value) {
    if (value == null || value.isEmpty) return null;
    final asSeconds = int.tryParse(value.trim());
    if (asSeconds != null && asSeconds >= 0) {
      return Duration(seconds: asSeconds);
    }

    final asDate = DateTime.tryParse(value);
    if (asDate == null) return null;
    final delta = asDate.difference(DateTime.now().toUtc());
    return delta.isNegative ? Duration.zero : delta;
  }

  String _summarizeSql(String sql) {
    final compact = sql.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 140) return compact;
    return '${compact.substring(0, 137)}...';
  }

  void _log(String message) {
    if (!debugLog) return;
    logger?.call(
      '[D1HttpTransport ${DateTime.now().toIso8601String()}] $message',
    );
  }

  @override
  Future<void> close() async {
    _client.close();
  }
}

int _readIntOption(
  Map<String, Object?> options, {
  required List<String> keys,
  required int fallback,
}) {
  for (final key in keys) {
    final value = options[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return fallback;
}

Map<String, String> _readHeaders(Object? value) {
  if (value is! Map) return const <String, String>{};
  return value.map((key, value) => MapEntry(key.toString(), value.toString()));
}

bool _readBoolOption(
  Map<String, Object?> options, {
  required List<String> keys,
  required bool fallback,
}) {
  for (final key in keys) {
    final value = options[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == '1' ||
          normalized == 'true' ||
          normalized == 'yes' ||
          normalized == 'on') {
        return true;
      }
      if (normalized == '0' ||
          normalized == 'false' ||
          normalized == 'no' ||
          normalized == 'off') {
        return false;
      }
    }
  }
  return fallback;
}
