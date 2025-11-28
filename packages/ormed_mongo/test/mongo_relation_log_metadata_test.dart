import 'dart:convert';

import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:test/test.dart';

import 'support/mongo_harness.dart';

void main() {
  late MongoTestHarness harness;
  late QueryContext loggingContext;
  late OrmConnection connection;
  final logEntries = <QueryLogEntry>[];

  setUpAll(() async {
    harness = await MongoTestHarness.create();
    await seedGraph(harness);
    loggingContext = QueryContext(
      registry: harness.registry,
      driver: harness.adapter,
      codecRegistry: harness.adapter.codecs,
      queryLogHook: (entry) => logEntries.add(entry),
    );
    connection = OrmConnection(
      config: ConnectionConfig(name: 'mongo-log'),
      driver: harness.adapter,
      registry: harness.registry,
      context: loggingContext,
    );
  });

  tearDownAll(() async {
    await harness.dispose();
  });

  test('logged previews include relation aggregate metadata', () async {
    logEntries.clear();
    await loggingContext.query<Author>().withCount('posts').rows();
    final entry = logEntries.last;
    final payload = entry.preview.payload as DocumentStatementPayload;
    final metadata = payload.metadata?['mongo_plan'] as Map<String, Object?>?;
    expect(metadata, isNotNull);
    final aggregates = metadata!['relation_aggregates'] as List<Object?>?;
    expect(aggregates, isNotNull);
  });

  test('pretend output includes relation metadata', () async {
    final _ = await connection.pretend(() async {
      await loggingContext.query<Author>().withCount('posts').rows();
    });
    final entry = logEntries.last;
    final payload = entry.preview.payload as DocumentStatementPayload;
    final metadata = payload.metadata?['mongo_plan'] as Map<String, Object?>?;
    expect(metadata, isNotNull);
    final aggregates = metadata!['relation_aggregates'] as List<Object?>?;
    expect(aggregates, isNotNull);
    final formatted = const JsonEncoder.withIndent(
      '  ',
    ).convert(payload.toJson());
    expect(formatted, contains('relation_aggregates'));
  });
}
