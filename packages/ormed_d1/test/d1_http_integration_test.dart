@Tags(['integration'])
library;

import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_d1/ormed_d1.dart';
import 'package:test/test.dart';

void main() {
  final env = OrmedEnvironment.fromDirectory(Directory.current);
  final accountId = env.value('D1_ACCOUNT_ID') ?? env.value('CF_ACCOUNT_ID');
  final databaseId = env.value('D1_DATABASE_ID');
  final apiToken = env.value('D1_API_TOKEN') ?? env.value('D1_SECRET');
  final baseUrl = env.string(
    'D1_BASE_URL',
    fallback: 'https://api.cloudflare.com/client/v4',
  );
  final debugLog = env.boolValue('D1_DEBUG_LOG', fallback: false);

  final missing = <String>[
    if (accountId == null) 'D1_ACCOUNT_ID/CF_ACCOUNT_ID',
    if (databaseId == null) 'D1_DATABASE_ID',
    if (apiToken == null) 'D1_API_TOKEN/D1_SECRET',
  ];

  test(
    'D1 HTTP transport can execute a simple query',
    () async {
      final transport = D1HttpTransport(
        accountId: accountId!,
        databaseId: databaseId!,
        apiToken: apiToken!,
        baseUrl: baseUrl,
        debugLog: debugLog,
      );

      try {
        final result = await transport.query('SELECT 1 AS ok');
        expect(result.rows, isNotEmpty);
        final value = result.rows.first['ok'];
        expect(value, anyOf(1, '1'));
      } finally {
        await transport.close();
      }
    },
    skip: missing.isEmpty ? false : 'Missing env vars: ${missing.join(', ')}',
  );
}
