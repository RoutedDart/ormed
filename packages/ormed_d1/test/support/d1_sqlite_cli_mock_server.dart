import 'dart:async';
import 'dart:convert';
import 'dart:io';

class D1MockHttpRequest {
  D1MockHttpRequest({
    required this.method,
    required this.path,
    required this.headers,
    required this.body,
  });

  final String method;
  final String path;
  final Map<String, String> headers;
  final String body;

  Map<String, Object?> get jsonBody {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    throw StateError('Expected JSON object request body.');
  }
}

/// Lightweight D1-compatible HTTP endpoint backed by local sqlite3 CLI.
///
/// This intentionally avoids introducing a Dart sqlite dependency into
/// `ormed_d1` test code while still executing real SQL statements.
class D1SqliteCliMockServer {
  D1SqliteCliMockServer._(
    this._server,
    this._subscription,
    this._tempDir,
    this.requests,
  );

  final HttpServer _server;
  final StreamSubscription<HttpRequest> _subscription;
  final Directory _tempDir;
  final List<D1MockHttpRequest> requests;

  static final bool isAvailable = _isSqliteCliAvailable();

  String get baseUrl => 'http://${_server.address.host}:${_server.port}';

  static Future<D1SqliteCliMockServer> start({String seedSql = ''}) async {
    if (!isAvailable) {
      throw StateError('sqlite3 CLI is not available on PATH');
    }

    final tempDir = await Directory.systemTemp.createTemp('ormed_d1_cli_');
    final dbPath = '${tempDir.path}/mock.sqlite';
    await File(dbPath).create(recursive: true);

    if (seedSql.trim().isNotEmpty) {
      await _runSqliteJson(dbPath, seedSql);
    }

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <D1MockHttpRequest>[];

    final subscription = server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      final headers = <String, String>{};
      request.headers.forEach((name, values) {
        headers[name.toLowerCase()] = values.join(', ');
      });
      requests.add(
        D1MockHttpRequest(
          method: request.method,
          path: request.uri.path,
          headers: headers,
          body: body,
        ),
      );

      Map<String, Object?> responseBody;
      var statusCode = 200;

      try {
        final payload = jsonDecode(body);
        if (payload is! Map) {
          throw const FormatException('Expected JSON object payload.');
        }

        final sql = payload['sql']?.toString();
        if (sql == null || sql.isEmpty) {
          throw const FormatException('Missing SQL in payload.');
        }

        final rawParams = payload['params'];
        final params = rawParams is List<Object?>
            ? rawParams
            : rawParams is List
            ? rawParams.cast<Object?>()
            : const <Object?>[];
        final boundSql = _bindSqlParameters(sql, params);

        List<Map<String, Object?>> rows = const <Map<String, Object?>>[];
        Map<String, Object?> meta = const <String, Object?>{
          'changes': 0,
          'last_row_id': 0,
        };

        final hasReturning = _hasReturningClause(boundSql);
        if (_isReadStatement(boundSql) || hasReturning) {
          rows = await _runSqliteJson(dbPath, boundSql);
          if (hasReturning) {
            meta = <String, Object?>{'changes': rows.length, 'last_row_id': 0};
          }
        } else {
          final metaRows = await _runSqliteJson(
            dbPath,
            '$boundSql; SELECT changes() AS changes, last_insert_rowid() AS last_row_id;',
          );
          if (metaRows.isNotEmpty) {
            meta = metaRows.first;
          }
        }

        responseBody = <String, Object?>{
          'success': true,
          'result': <Object?>[
            <String, Object?>{'results': rows, 'meta': meta},
          ],
          'errors': const <Object?>[],
          'messages': const <Object?>[],
        };
      } catch (error) {
        statusCode = 400;
        responseBody = <String, Object?>{
          'success': false,
          'result': const <Object?>[],
          'errors': <Object?>[
            <String, Object?>{'code': 7500, 'message': error.toString()},
          ],
          'messages': const <Object?>[],
        };
      }

      request.response.statusCode = statusCode;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(responseBody));
      await request.response.close();
    });

    return D1SqliteCliMockServer._(server, subscription, tempDir, requests);
  }

  Future<void> close() async {
    await _subscription.cancel();
    await _server.close(force: true);
    if (_tempDir.existsSync()) {
      await _tempDir.delete(recursive: true);
    }
  }
}

bool _isSqliteCliAvailable() {
  try {
    final result = Process.runSync('sqlite3', const ['--version']);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

Future<List<Map<String, Object?>>> _runSqliteJson(
  String dbPath,
  String sql,
) async {
  final result = await Process.run('sqlite3', ['-json', dbPath, sql]);
  if (result.exitCode != 0) {
    final stderr = (result.stderr as String?)?.trim();
    final stdout = (result.stdout as String?)?.trim();
    final message = [
      if (stderr != null && stderr.isNotEmpty) stderr,
      if (stdout != null && stdout.isNotEmpty) stdout,
    ].join(' ');
    throw StateError(message.isEmpty ? 'sqlite3 command failed' : message);
  }

  final rawOutput = (result.stdout as String?)?.trim() ?? '';
  if (rawOutput.isEmpty) {
    return const <Map<String, Object?>>[];
  }

  final decoded = jsonDecode(rawOutput);
  if (decoded is! List) {
    throw StateError('Expected sqlite3 -json output to be a JSON array.');
  }

  return decoded
      .whereType<Map>()
      .map((entry) => entry.map((k, v) => MapEntry(k.toString(), v)))
      .toList(growable: false);
}

bool _isReadStatement(String sql) {
  final trimmed = sql.trimLeft().toLowerCase();
  return trimmed.startsWith('select ') ||
      trimmed.startsWith('with ') ||
      trimmed.startsWith('pragma ') ||
      trimmed.startsWith('explain ');
}

bool _hasReturningClause(String sql) {
  return RegExp(r'\breturning\b', caseSensitive: false).hasMatch(sql);
}

String _bindSqlParameters(String sql, List<Object?> params) {
  final buffer = StringBuffer();
  var parameterIndex = 0;
  var inSingleQuote = false;
  var inDoubleQuote = false;
  var inBacktick = false;

  for (var i = 0; i < sql.length; i++) {
    final char = sql[i];

    if (inSingleQuote) {
      buffer.write(char);
      if (char == "'") {
        final escapedQuote = i + 1 < sql.length && sql[i + 1] == "'";
        if (escapedQuote) {
          buffer.write("'");
          i++;
        } else {
          inSingleQuote = false;
        }
      }
      continue;
    }

    if (inDoubleQuote) {
      buffer.write(char);
      if (char == '"') {
        inDoubleQuote = false;
      }
      continue;
    }

    if (inBacktick) {
      buffer.write(char);
      if (char == '`') {
        inBacktick = false;
      }
      continue;
    }

    if (char == "'") {
      inSingleQuote = true;
      buffer.write(char);
      continue;
    }
    if (char == '"') {
      inDoubleQuote = true;
      buffer.write(char);
      continue;
    }
    if (char == '`') {
      inBacktick = true;
      buffer.write(char);
      continue;
    }

    if (char == '?') {
      if (parameterIndex >= params.length) {
        throw StateError(
          'Missing value for SQL parameter at index $parameterIndex.',
        );
      }
      buffer.write(_toSqliteLiteral(params[parameterIndex]));
      parameterIndex++;
      continue;
    }

    buffer.write(char);
  }

  if (parameterIndex != params.length) {
    throw StateError(
      'Received ${params.length} params but consumed $parameterIndex placeholders.',
    );
  }

  return buffer.toString();
}

String _toSqliteLiteral(Object? value) {
  if (value == null) return 'NULL';
  if (value is bool) return value ? '1' : '0';
  if (value is num) return value.toString();
  if (value is DateTime) {
    return "'${value.toUtc().toIso8601String().replaceAll("'", "''")}'";
  }
  final text = value.toString().replaceAll("'", "''");
  return "'$text'";
}
