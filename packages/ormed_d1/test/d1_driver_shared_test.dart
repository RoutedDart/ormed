@Tags(['integration', 'shared'])
@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:driver_tests/driver_tests.dart' hide Tags;
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import 'support/d1_test_harness.dart';

Future<void> main() async {
  final env = OrmedEnvironment.fromDirectory(Directory.current);
  final accountId = env.value('D1_ACCOUNT_ID') ?? env.value('CF_ACCOUNT_ID');
  final databaseId = env.value('D1_DATABASE_ID');
  final apiToken = env.value('D1_API_TOKEN') ?? env.value('D1_SECRET');

  final missing = <String>[
    if (accountId == null) 'D1_ACCOUNT_ID/CF_ACCOUNT_ID',
    if (databaseId == null) 'D1_DATABASE_ID',
    if (apiToken == null) 'D1_API_TOKEN/D1_SECRET',
  ];

  if (missing.isNotEmpty) {
    test(
      'D1 shared tests require integration env vars',
      () {},
      skip: 'Missing env vars: ${missing.join(', ')}',
    );
    return;
  }

  final harness = await createD1TestHarness(logging: true);
  _attachDataSourceDebugLogging(harness.dataSource, env: env);

  tearDownAll(() async {
    await harness.dispose();
  });

  runAllDriverTests();
  runRawQueryOrderGroupByPreviewTests();
}

void runRawQueryOrderGroupByPreviewTests() {
  ormedGroup('Raw Query Helpers (D1 preview)', (dataSource) {
    final supportsRaw = dataSource.options.driver.metadata.supportsCapability(
      DriverCapability.rawSQL,
    );

    test('includes raw SQL fragments and bindings in order', () {
      final preview = dataSource.context
          .query<Post>()
          .whereRaw('status = ?', ['draft'])
          .groupByRaw('CASE WHEN ? THEN status END', [true])
          .orderByRaw('CASE WHEN status = ? THEN 0 ELSE 1 END', ['draft'])
          .toSql();

      expect(preview.sql, contains('GROUP BY CASE WHEN ? THEN status END'));
      expect(
        preview.sql,
        contains('ORDER BY CASE WHEN status = ? THEN 0 ELSE 1 END'),
      );
      expect(preview.parameters, hasLength(3));
      expect(preview.parameters.first, 'draft');
      expect(
        preview.parameters[1],
        anyOf(isTrue, equals(1)),
        reason: 'boolean may be encoded as bool or int',
      );
      expect(preview.parameters.last, 'draft');
    }, skip: !supportsRaw);
  });
}

void _attachDataSourceDebugLogging(
  DataSource dataSource, {
  required OrmedEnvironment env,
}) {
  final enabled = env.firstBool([
    'D1_DS_LOG',
    'D1_DATA_SOURCE_LOG',
    'D1_DEBUG_LOG',
  ], fallback: true);
  if (!enabled) {
    return;
  }

  dataSource.context.onQuery((event) {
    stdout.writeln(
      '[D1DataSource][query] ok=${event.succeeded} rows=${event.rows ?? 0} '
      'ms=${event.duration.inMilliseconds} sql=${event.preview.sqlWithBindings}',
    );
    if (event.error != null) {
      stdout.writeln('[D1DataSource][query][error] ${event.error}');
    }
  });

  dataSource.context.onMutation((event) {
    stdout.writeln(
      '[D1DataSource][mutation] ok=${event.succeeded} affected=${event.affectedRows ?? 0} '
      'ms=${event.duration.inMilliseconds} sql=${event.preview.sqlWithBindings}',
    );
    if (event.error != null) {
      stdout.writeln('[D1DataSource][mutation][error] ${event.error}');
    }
  });
}
