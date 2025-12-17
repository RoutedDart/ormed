import 'dart:convert';

import 'package:ormed/ormed.dart';
import 'package:test/test.dart';
import 'package:driver_tests/driver_tests.dart';

void main() {
  group('FieldDefinition driver overrides', () {
    final field =
        DriverOverrideModelOrmDefinition.definition.fieldByName('payload')!;

    test('resolves column type per driver', () {
      expect(field.columnTypeForDriver('postgres'), equals('jsonb'));
      expect(field.columnTypeForDriver('sqlite'), equals('TEXT'));
      expect(field.columnTypeForDriver('Postgres'), equals('jsonb'));
      expect(field.columnTypeForDriver(null), equals('TEXT'));
    });
  });

  group('Mutation plans capture driver name', () {
    test('repository insert uses driver metadata name', () async {
      late MutationPlan captured;

      // Create a mock driver that captures mutation plans
      final driver = _MockDriver(
        onMutation: (plan) {
          captured = plan;
          return const MutationResult(
            affectedRows: 1,
            returnedRows: [
              {
                'id': 1,
                'payload': {'theme': 'dark', 'encoded_by': 'postgres'},
              },
            ],
          );
        },
      );

      final registry = ModelRegistry()..registerGeneratedModels();
      final context = QueryContext(registry: registry, driver: driver);

      final repo = context.repository<DriverOverrideModel>();

      await repo.insert(
        const DriverOverrideModel(id: 1, payload: {'theme': 'dark'}),
      );
      expect(captured.driverName, equals('postgres'));
    });
  });

  group('Driver-specific codecs', () {
    final definition = DriverOverrideModelOrmDefinition.definition;
    final baseRegistry = ValueCodecRegistry.instance
      ..registerCodecFor(PostgresPayloadCodec, const PostgresPayloadCodec())
      ..registerCodecFor(SqlitePayloadCodec, const SqlitePayloadCodec());

    test('encode uses codec override per driver', () {
      final postgresMap = definition.toMap(
        const DriverOverrideModel(id: 1, payload: {'mode': 'dark'}).toTracked(),
        registry: baseRegistry.forDriver('postgres'),
      );
      final sqliteMap = definition.toMap(
        const DriverOverrideModel(id: 2, payload: {'mode': 'dark'}).toTracked(),
        registry: baseRegistry.forDriver('sqlite'),
      );

      expect(
        postgresMap['payload'],
        equals({'mode': 'dark', 'encoded_by': 'postgres'}),
      );
      final expectedSqlite = jsonEncode({'mode': 'dark'});
      expect(sqliteMap['payload'], equals(expectedSqlite));
    });

    test('decode consults driver override metadata', () {
      final decoded = definition.fromMap({
        'id': 5,
        'payload': {'mode': 'dark', 'encoded_by': 'postgres'},
      }, registry: baseRegistry.forDriver('postgres'));
      expect(decoded.payload['mode'], equals('dark'));
      expect(decoded.payload.containsKey('encoded_by'), isFalse);
    });
  });
}

/// Mock driver that allows capturing mutation plans.
class _MockDriver implements DriverAdapter {
  _MockDriver({required this.onMutation});

  final MutationResult Function(MutationPlan plan) onMutation;

  @override
  DriverMetadata get metadata => const DriverMetadata(
    name: 'postgres',
    capabilities: {DriverCapability.advancedQueryBuilders},
  );

  @override
  ValueCodecRegistry get codecs => ValueCodecRegistry.instance;

  @override
  PlanCompiler get planCompiler => fallbackPlanCompiler();

  @override
  Future<MutationResult> runMutation(MutationPlan plan) async =>
      onMutation(plan);

  @override
  StatementPreview describeMutation(MutationPlan plan) =>
      const StatementPreview(payload: SqlStatementPayload(sql: ''));

  @override
  Future<List<Map<String, Object?>>> execute(QueryPlan plan) async => [];

  @override
  Stream<Map<String, Object?>> stream(QueryPlan plan) => const Stream.empty();

  @override
  StatementPreview describeQuery(QueryPlan plan) =>
      const StatementPreview(payload: SqlStatementPayload(sql: ''));

  @override
  Future<void> close() async {}

  @override
  Future<void> executeRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {}

  @override
  Future<List<Map<String, Object?>>> queryRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async => [];

  @override
  Future<R> transaction<R>(Future<R> Function() action) => Future.sync(action);

  @override
  Future<void> beginTransaction() async {}

  @override
  Future<void> commitTransaction() async {}

  @override
  Future<void> rollbackTransaction() async {}

  @override
  Future<void> truncateTable(String tableName) async {}

  @override
  Future<int?> threadCount() async => null;
}
