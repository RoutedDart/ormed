import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ormed_d1/ormed_d1.dart';
import 'package:test/test.dart';

final class _ResponseClient extends http.BaseClient {
  _ResponseClient(this.responses);

  final List<http.Response> responses;
  final List<http.BaseRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final response = responses.removeAt(0);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

http.Response _jsonResponse(Object body, {int statusCode = 200}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: const <String, String>{'content-type': 'application/json'},
  );
}

void main() {
  test(
    'endpoint transport sends browser-safe requests and parses D1 shape',
    () async {
      final client = _ResponseClient([
        _jsonResponse(const <String, Object?>{
          'success': true,
          'results': <Object?>[
            <String, Object?>{'ok': 1},
          ],
          'meta': <String, Object?>{'changes': 1},
        }),
      ]);
      final transport = D1HttpTransport.endpoint(
        endpoint: Uri.parse('https://app.example.test/api/db/query'),
        headers: const <String, String>{'X-Request-Token': 'session-token'},
        client: client,
        maxAttempts: 1,
      );

      final result = await transport.query('SELECT ? AS ok', [1]);
      final request = client.requests.single;

      expect(result.rows.single['ok'], 1);
      expect(result.affectedRows, 1);
      expect(request.url.toString(), 'https://app.example.test/api/db/query');
      expect(request.headers['authorization'], isNull);
      expect(request.headers['x-request-token'], 'session-token');
      expect(jsonDecode((request as http.Request).body), <String, Object?>{
        'sql': 'SELECT ? AS ok',
        'params': <Object?>[1],
      });
      await transport.close();
    },
  );

  test('endpoint transport preserves atomic batch capability', () async {
    final client = _ResponseClient([
      _jsonResponse(const <String, Object?>{
        'success': true,
        'results': <Object?>[
          <String, Object?>{
            'success': true,
            'results': <Object?>[],
            'meta': <String, Object?>{'changes': 1},
          },
          <String, Object?>{
            'success': true,
            'results': <Object?>[],
            'meta': <String, Object?>{'changes': 1},
          },
        ],
      }),
    ]);
    final transport = D1HttpTransport.endpoint(
      endpoint: Uri.parse('https://app.example.test/api/db/query'),
      batchEndpoint: Uri.parse('https://app.example.test/api/db/batch'),
      client: client,
      maxAttempts: 1,
    );

    final results = await transport.batch(const [
      D1Statement(
        sql: 'INSERT INTO users (name) VALUES (?)',
        parameters: ['Ada'],
      ),
      D1Statement(
        sql: 'INSERT INTO users (name) VALUES (?)',
        parameters: ['Grace'],
      ),
    ]);

    expect(results, hasLength(2));
    expect(results.every((result) => result.affectedRows == 1), isTrue);
    expect(client.requests.single.url.path, '/api/db/batch');
    expect(
      jsonDecode((client.requests.single as http.Request).body),
      <String, Object?>{
        'statements': <Object?>[
          <String, Object?>{
            'sql': 'INSERT INTO users (name) VALUES (?)',
            'params': <Object?>['Ada'],
          },
          <String, Object?>{
            'sql': 'INSERT INTO users (name) VALUES (?)',
            'params': <Object?>['Grace'],
          },
        ],
      },
    );
    await transport.close();
  });

  test('endpoint transport requires a batch endpoint for atomic batches', () {
    final transport = D1HttpTransport.endpoint(
      endpoint: Uri.parse('https://app.example.test/api/db/query'),
    );

    expect(
      transport.batch(const [D1Statement(sql: 'SELECT 1')]),
      throwsA(isA<UnsupportedError>()),
    );
  });
}
