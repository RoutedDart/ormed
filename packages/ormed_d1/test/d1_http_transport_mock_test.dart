import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_d1/ormed_d1.dart';
import 'package:test/test.dart';

import 'support/d1_sqlite_cli_mock_server.dart';

class _RecordedRequest {
  _RecordedRequest({
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

class _PlannedResponse {
  const _PlannedResponse({
    required this.statusCode,
    required this.body,
    this.headers = const <String, String>{},
  });

  final int statusCode;
  final Object body;
  final Map<String, String> headers;
}

class _MockD1Server {
  _MockD1Server._(this._server, this._subscription, this.requests);

  final HttpServer _server;
  final StreamSubscription<HttpRequest> _subscription;
  final List<_RecordedRequest> requests;

  String get baseUrl => 'http://${_server.address.host}:${_server.port}';

  static Future<_MockD1Server> start(List<_PlannedResponse> responses) async {
    if (responses.isEmpty) {
      throw ArgumentError('responses must not be empty');
    }

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <_RecordedRequest>[];
    var responseIndex = 0;

    final subscription = server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      final headers = <String, String>{};
      request.headers.forEach((name, values) {
        headers[name.toLowerCase()] = values.join(', ');
      });
      requests.add(
        _RecordedRequest(
          method: request.method,
          path: request.uri.path,
          headers: headers,
          body: body,
        ),
      );

      final response =
          responses[responseIndex < responses.length
              ? responseIndex
              : responses.length - 1];
      responseIndex++;

      request.response.statusCode = response.statusCode;
      for (final entry in response.headers.entries) {
        request.response.headers.set(entry.key, entry.value);
      }
      if (response.body is String) {
        request.response.write(response.body as String);
      } else {
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(response.body));
      }
      await request.response.close();
    });

    return _MockD1Server._(server, subscription, requests);
  }

  Future<void> close() async {
    await _subscription.cancel();
    await _server.close(force: true);
  }
}

void main() {
  group('D1HttpTransport mock server behavior', () {
    test('sends expected request and parses result/meta', () async {
      final server = await _MockD1Server.start([
        const _PlannedResponse(
          statusCode: 200,
          body: <String, Object?>{
            'success': true,
            'result': <Object?>[
              <String, Object?>{
                'results': <Object?>[
                  <String, Object?>{'ok': 1},
                ],
                'meta': <String, Object?>{'changes': 2, 'last_row_id': 42},
              },
            ],
          },
        ),
      ]);

      final transport = D1HttpTransport(
        accountId: 'acct-1',
        databaseId: 'db-1',
        apiToken: 'token-1',
        baseUrl: server.baseUrl,
        maxAttempts: 1,
      );

      try {
        final result = await transport.query('SELECT ? AS ok', [1]);
        expect(result.rows, hasLength(1));
        expect(result.rows.first['ok'], 1);
        expect(result.affectedRows, 2);
        expect(result.lastRowId, 42);
      } finally {
        await transport.close();
        await server.close();
      }

      expect(server.requests, hasLength(1));
      final request = server.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/accounts/acct-1/d1/database/db-1/query');
      expect(request.headers['authorization'], 'Bearer token-1');
      expect(request.headers['content-type'], contains('application/json'));
      expect(request.jsonBody['sql'], 'SELECT ? AS ok');
      expect(request.jsonBody['params'], <Object?>[1]);
    });

    test('retries on HTTP 429 and eventually succeeds', () async {
      final server = await _MockD1Server.start([
        const _PlannedResponse(
          statusCode: 429,
          headers: <String, String>{'retry-after': '0'},
          body: <String, Object?>{
            'success': false,
            'errors': <Object?>[
              <String, Object?>{'code': 429, 'message': 'too many requests'},
            ],
          },
        ),
        const _PlannedResponse(
          statusCode: 200,
          body: <String, Object?>{
            'success': true,
            'result': <Object?>[
              <String, Object?>{
                'results': <Object?>[
                  <String, Object?>{'ok': 1},
                ],
                'meta': <String, Object?>{},
              },
            ],
          },
        ),
      ]);

      final transport = D1HttpTransport(
        accountId: 'acct-1',
        databaseId: 'db-1',
        apiToken: 'token-1',
        baseUrl: server.baseUrl,
        maxAttempts: 3,
        retryBaseDelay: const Duration(milliseconds: 1),
        retryMaxDelay: const Duration(milliseconds: 2),
      );

      try {
        final result = await transport.query('SELECT 1');
        expect(result.rows.single['ok'], 1);
      } finally {
        await transport.close();
        await server.close();
      }

      expect(server.requests, hasLength(2));
    });

    test('retries on success=false retryable payload and succeeds', () async {
      final server = await _MockD1Server.start([
        const _PlannedResponse(
          statusCode: 200,
          body: <String, Object?>{
            'success': false,
            'errors': <Object?>[
              <String, Object?>{
                'code': 7500,
                'message': 'temporarily overloaded',
              },
            ],
            'result': <Object?>[],
          },
        ),
        const _PlannedResponse(
          statusCode: 200,
          body: <String, Object?>{
            'success': true,
            'result': <Object?>[
              <String, Object?>{
                'results': <Object?>[
                  <String, Object?>{'ok': 1},
                ],
                'meta': <String, Object?>{},
              },
            ],
          },
        ),
      ]);

      final transport = D1HttpTransport(
        accountId: 'acct-1',
        databaseId: 'db-1',
        apiToken: 'token-1',
        baseUrl: server.baseUrl,
        maxAttempts: 3,
        retryBaseDelay: const Duration(milliseconds: 1),
        retryMaxDelay: const Duration(milliseconds: 2),
      );

      try {
        final result = await transport.query('SELECT 1');
        expect(result.rows.single['ok'], 1);
      } finally {
        await transport.close();
        await server.close();
      }

      expect(server.requests, hasLength(2));
    });

    test('throws without retry on non-retryable HTTP 400', () async {
      final server = await _MockD1Server.start([
        const _PlannedResponse(
          statusCode: 400,
          body: <String, Object?>{
            'success': false,
            'errors': <Object?>[
              <String, Object?>{'code': 7500, 'message': 'not authorized'},
            ],
          },
        ),
      ]);

      final transport = D1HttpTransport(
        accountId: 'acct-1',
        databaseId: 'db-1',
        apiToken: 'token-1',
        baseUrl: server.baseUrl,
        maxAttempts: 3,
        retryBaseDelay: const Duration(milliseconds: 1),
        retryMaxDelay: const Duration(milliseconds: 2),
      );

      try {
        await expectLater(
          transport.query('SELECT 1'),
          throwsA(
            isA<D1RequestException>().having(
              (error) => error.message,
              'message',
              contains('D1 request failed (400)'),
            ),
          ),
        );
      } finally {
        await transport.close();
        await server.close();
      }

      expect(server.requests, hasLength(1));
    });
  });

  group('Ormed + D1 mock integration', () {
    const usersColumns = <AdHocColumn>[
      AdHocColumn(name: 'id', columnName: 'id', isPrimaryKey: true),
      AdHocColumn(name: 'name', columnName: 'name'),
    ];

    test(
      'DataSource table get/update/delete executes against sqlite3 CLI-backed endpoint',
      () async {
        final server = await D1SqliteCliMockServer.start(
          seedSql: '''
CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT);
INSERT INTO users (name) VALUES ('Alice');
INSERT INTO users (name) VALUES ('O''Reilly');
''',
        );

        final registry = ModelRegistry();
        final dataSource = DataSource(
          registry.d1DataSourceOptions(
            accountId: 'acct-1',
            databaseId: 'db-1',
            apiToken: 'token-1',
            baseUrl: server.baseUrl,
            maxAttempts: 1,
            requestTimeoutMs: 1000,
            retryBaseDelayMs: 1,
            retryMaxDelayMs: 2,
            name: 'mock_d1',
          ),
        );

        try {
          await dataSource.init();

          final rows = await dataSource
              .table('users', columns: usersColumns)
              .whereEquals('name', "O'Reilly")
              .get();
          expect(rows, hasLength(1));
          expect(rows.first['name'], "O'Reilly");

          final updated = await dataSource
              .table('users', columns: usersColumns)
              .whereEquals('id', 1)
              .update({'name': 'Bob'});
          expect(updated, 1);

          final deleted = await dataSource
              .table('users', columns: usersColumns)
              .whereEquals('id', 1)
              .delete();
          expect(deleted, 1);

          final countRows = await dataSource.connection.driver.queryRaw(
            'SELECT COUNT(*) AS count FROM users',
          );
          expect(countRows, hasLength(1));
          expect(countRows.first['count'], anyOf(1, '1'));
        } finally {
          await dataSource.dispose();
          await server.close();
        }

        expect(server.requests.length, greaterThanOrEqualTo(3));
        for (final request in server.requests) {
          expect(request.method, 'POST');
          expect(request.path, '/accounts/acct-1/d1/database/db-1/query');
        }

        final sqlStatements = server.requests
            .map((request) => request.jsonBody['sql']?.toString() ?? '')
            .toList(growable: false);
        expect(
          sqlStatements.any(
            (sql) => sql.contains('SELECT') && sql.contains('"users"'),
          ),
          isTrue,
        );
        expect(
          sqlStatements.any(
            (sql) => sql.contains('UPDATE') && sql.contains('"users"'),
          ),
          isTrue,
        );
        expect(
          sqlStatements.any(
            (sql) => sql.contains('DELETE') && sql.contains('"users"'),
          ),
          isTrue,
        );
        expect(
          server.requests.any((request) {
            final params = request.jsonBody['params'];
            return params is List && params.contains("O'Reilly");
          }),
          isTrue,
        );
      },
      skip: D1SqliteCliMockServer.isAvailable
          ? false
          : 'sqlite3 CLI is not available',
    );

    test(
      'd1DataSourceFromEnv boots and executes queries through sqlite3 CLI-backed endpoint',
      () async {
        final server = await D1SqliteCliMockServer.start(
          seedSql: '''
CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT);
INSERT INTO users (name) VALUES ('EnvUser');
''',
        );

        final registry = ModelRegistry();
        final dataSource = registry.d1DataSourceFromEnv(
          name: 'env_mock',
          environment: <String, String>{
            'CF_ACCOUNT_ID': 'acct-env',
            'D1_DATABASE_ID': 'db-env',
            'D1_SECRET': 'token-env',
            'D1_BASE_URL': server.baseUrl,
            'D1_RETRY_ATTEMPTS': '1',
            'D1_REQUEST_TIMEOUT_MS': '1000',
            'D1_RETRY_BASE_DELAY_MS': '1',
            'D1_RETRY_MAX_DELAY_MS': '2',
          },
        );

        try {
          await dataSource.init();
          final rows = await dataSource
              .table('users', columns: usersColumns)
              .whereEquals('id', 1)
              .get();
          expect(rows, isNotEmpty);
        } finally {
          await dataSource.dispose();
          await server.close();
        }

        expect(server.requests, isNotEmpty);
        expect(
          server.requests.first.path,
          '/accounts/acct-env/d1/database/db-env/query',
        );
        expect(
          server.requests.first.headers['authorization'],
          'Bearer token-env',
        );
      },
      skip: D1SqliteCliMockServer.isAvailable
          ? false
          : 'sqlite3 CLI is not available',
    );

    test(
      'propagates SQL errors from sqlite3 CLI-backed endpoint',
      () async {
        final server = await D1SqliteCliMockServer.start(
          seedSql: '''
CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT);
INSERT INTO users (name) VALUES ('Alice');
''',
        );

        final transport = D1HttpTransport(
          accountId: 'acct-1',
          databaseId: 'db-1',
          apiToken: 'token-1',
          baseUrl: server.baseUrl,
          maxAttempts: 1,
        );

        try {
          await expectLater(
            transport.query('SELECT missing_column FROM users WHERE id = ?', [
              1,
            ]),
            throwsA(
              isA<D1RequestException>().having(
                (error) => error.message.toLowerCase(),
                'message',
                contains('no such column'),
              ),
            ),
          );
        } finally {
          await transport.close();
          await server.close();
        }
      },
      skip: D1SqliteCliMockServer.isAvailable
          ? false
          : 'sqlite3 CLI is not available',
    );
  });
}
