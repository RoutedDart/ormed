import 'package:ormed/ormed.dart';
import 'package:ormed_mongo/ormed_mongo.dart';
import 'package:test/test.dart';

import 'shared.dart';

class FallbackCodec extends ModelCodec<Map<String, Object?>> {
  const FallbackCodec();

  @override
  Map<String, Object?> encode(
    Map<String, Object?> model,
    ValueCodecRegistry registry,
  ) => Map<String, Object?>.from(model);

  @override
  Map<String, Object?> decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) => Map<String, Object?>.from(data);
}

void main() {
  late MongoDriverAdapter adapter;

  final definition = ModelDefinition<Map<String, Object?>>(
    modelName: 'Fallback',
    tableName: 'fallback_updates',
    fields: const [
      FieldDefinition(
        name: '_id',
        columnName: '_id',
        dartType: 'Object',
        resolvedType: 'Object',
        isPrimaryKey: false,
        isNullable: false,
      ),
      FieldDefinition(
        name: 'code',
        columnName: 'code',
        dartType: 'String',
        resolvedType: 'String',
        isPrimaryKey: false,
        isNullable: false,
      ),
      FieldDefinition(
        name: 'value',
        columnName: 'value',
        dartType: 'int',
        resolvedType: 'int',
        isPrimaryKey: false,
        isNullable: true,
      ),
    ],
    codec: const FallbackCodec(),
    metadata: const ModelAttributesMetadata(
      driverAnnotations: [DriverModel('mongo')],
    ),
  );

  setUpAll(() async {
    adapter = createAdapter();
    // Registry is built per test when needed by the query context.
    await adapter.dropCollectionDirect('fallback_updates');
  });

  tearDownAll(() async {
    await adapter.close();
  });

  setUp(() async {
    final collection = await adapter.databaseInstance().then(
      (db) => db.collection('fallback_updates'),
    );
    await collection.deleteMany({});
    await collection.insertAll([
      {'code': 'alpha', 'value': 1},
      {'code': 'beta', 'value': 2},
    ]);
  });

  test(
    'query update works without declared PK using fallback identifier',
    () async {
      final logEntries = <QueryLogEntry>[];
      final registry = ModelRegistry()..register(definition);
      final loggingContext = QueryContext(
        registry: registry,
        driver: adapter,
        codecRegistry: adapter.codecs,
        queryLogHook: (entry) {
          if (entry.type == 'mutation') {
            logEntries.add(entry);
          }
        },
      );

      final affected = await loggingContext
          .query<Map<String, Object?>>()
          .whereEquals('code', 'alpha')
          .update({'value': 5});
      expect(affected, equals(1));

      final row = await loggingContext
          .query<Map<String, Object?>>()
          .whereEquals('code', 'alpha')
          .first();
      expect(row, isNotNull);
      expect(row!['value'], equals(5));

      final logEntry = logEntries.lastWhere((entry) {
        if (entry.type != 'mutation') return false;
        final payload = entry.preview.payload;
        if (payload is! DocumentStatementPayload) return false;
        final filter = payload.arguments['filter'];
        if (filter is! Map<String, Object?>) return false;
        return filter['code'] == 'alpha';
      });
      final payload = logEntry.preview.payload as DocumentStatementPayload;
      expect(payload.metadata, containsPair('identifier_column', '_id'));
    },
  );
}
