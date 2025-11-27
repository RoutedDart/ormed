import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:test/test.dart';

import 'support/mongo_harness.dart';

void main() {
  late MongoTestHarness harness;

  setUpAll(() async {
    harness = await MongoTestHarness.create();
    await seedGraph(harness);
  });

  tearDownAll(() async => await harness.dispose());

  test('tracks session metadata during transaction', () async {
    final sessions = <Map<String, Object?>>[];
    final remove = harness.context.beforeExecuting((statement) {
      final payload = statement.preview.payload as DocumentStatementPayload;
      final map = payload.metadata?['session'] as Map<String, Object?>?;
      if (map != null) {
        sessions.add(map);
      }
    });
    try {
      await harness.context.transaction(() async {
        await harness.context.query<Post>().whereEquals('id', 1).rows();
      });
      await harness.context.transaction(() async {
        await harness.context.query<Post>().whereEquals('id', 2).rows();
      });
    } finally {
      remove();
    }
    final sessionIds = sessions
        .map((session) => session['id'] as String?)
        .whereType<String>()
        .toSet();
    expect(sessionIds.length, equals(2));
    expect(sessionIds, hasLength(2));
    expect(sessions.every((session) => session['state'] == 'active'), isTrue);
  });

  test('preview metadata includes session id', () async {
    final sessions = <Map<String, Object?>>[];
    final remove = harness.context.beforeExecuting((statement) {
      final payload = statement.preview.payload as DocumentStatementPayload;
      final map = payload.metadata?['session'] as Map<String, Object?>?;
      if (map != null) {
        sessions.add(map);
      }
    });
    try {
      await harness.context.transaction(() async {
        await harness.context.query<Post>().rows();
      });
    } finally {
      remove();
    }
    final sessionIds = sessions
        .map((session) => session['id'] as String?)
        .whereType<String>()
        .toSet();
    expect(sessionIds, isNotEmpty);
    expect(sessionIds.length, equals(1));
    expect(sessions.first['state'], equals('active'));
  });
}
