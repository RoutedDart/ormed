import 'dart:convert';

import 'package:ormed/ormed.dart';
import 'package:test/test.dart';
import 'package:driver_tests/driver_tests.dart';

void main() {
  group('FieldDefinition driver overrides', () {
    final definition = DriverOverrideModelOrmDefinition.definition;
    final field = definition.fieldByName('payload')!;

    test('resolves column type per driver', () {
      expect(field.columnTypeForDriver('postgres'), equals('jsonb'));
      expect(field.columnTypeForDriver('sqlite'), equals('TEXT'));
      expect(field.columnTypeForDriver('Postgres'), equals('jsonb'));
      expect(field.columnTypeForDriver(null), equals('TEXT'));
    });
  });

  group('Mutation plans capture driver name', () {
    test('repository insert uses driver metadata name', () async {
      final definition = DriverOverrideModelOrmDefinition.definition;
      late MutationPlan captured;
      final repo = Repository<DriverOverrideModel>(
        definition: definition,
        driverName: 'postgres',
        codecs: ValueCodecRegistry.standard(),
        runMutation: (plan) async {
          captured = plan;
          return const MutationResult(affectedRows: 0);
        },
        describeMutation: (_) =>
            const StatementPreview(payload: SqlStatementPayload(sql: '')),
        attachRuntimeMetadata: (_) {},
      );

      await repo.insert(
        const DriverOverrideModel(id: 1, payload: {'theme': 'dark'}),
      );
      expect(captured.driverName, equals('postgres'));
    });
  });

  group('Driver-specific codecs', () {
    final definition = DriverOverrideModelOrmDefinition.definition;
    final baseRegistry = ValueCodecRegistry.standard()
      ..registerCodecFor(PostgresPayloadCodec, const PostgresPayloadCodec())
      ..registerCodecFor(SqlitePayloadCodec, const SqlitePayloadCodec());

    test('encode uses codec override per driver', () {
      final postgresMap = definition.toMap(
        const DriverOverrideModel(id: 1, payload: {'mode': 'dark'}),
        registry: baseRegistry.forDriver('postgres'),
      );
      final sqliteMap = definition.toMap(
        const DriverOverrideModel(id: 2, payload: {'mode': 'dark'}),
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
