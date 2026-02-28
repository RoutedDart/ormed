library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

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
    this.rows = const <Map<String, Object?>>[],
    this.meta = const <String, Object?>{},
  });

  final List<Map<String, Object?>> rows;
  final Map<String, Object?> meta;

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

class D1HttpTransport implements D1Transport {
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
    http.Client? client,
  }) : maxAttempts = maxAttempts < 1 ? 1 : maxAttempts,
       _client = client ?? http.Client();

  factory D1HttpTransport.fromOptions(Map<String, Object?> options) {
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
  final http.Client _client;
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

  Future<D1StatementResult> _sendSingle(D1Statement statement) async {
    final uri = Uri.parse(
      '$baseUrl/accounts/$accountId/d1/database/$databaseId/query',
    );
    final payload = jsonEncode(statement.toJson());
    D1RequestException? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final startedAt = DateTime.now();
      _log(
        'request attempt=$attempt/$maxAttempts sql="${_summarizeSql(statement.sql)}" params=${statement.parameters.length}',
      );

      try {
        final response = await _client
            .post(
              uri,
              headers: {
                'Authorization': 'Bearer $apiToken',
                'Content-Type': 'application/json',
              },
              body: payload,
            )
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
        if (success != true) {
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

        final resultEntry = _firstResultEntry(decoded['result']);
        final rows = _rowsFrom(resultEntry['results']);
        final meta = _metaFrom(resultEntry['meta']);
        return D1StatementResult(rows: rows, meta: meta);
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
      } on SocketException catch (e) {
        final error = D1RequestException('D1 network error: $e');
        if (attempt < maxAttempts) {
          final delay = _computeRetryDelay(attempt);
          _log('retrying after ${delay.inMilliseconds}ms due to socket error');
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

    try {
      final asDate = HttpDate.parse(value);
      final delta = asDate.difference(DateTime.now().toUtc());
      return delta.isNegative ? Duration.zero : delta;
    } on FormatException {
      return null;
    }
  }

  String _summarizeSql(String sql) {
    final compact = sql.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 140) return compact;
    return '${compact.substring(0, 137)}...';
  }

  void _log(String message) {
    if (!debugLog) return;
    stderr.writeln(
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
