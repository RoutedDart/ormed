import 'package:ormed/ormed.dart';
import 'package:ormed_mongo/ormed_mongo.dart';
import 'package:test/test.dart';

void main() {
  group('Mongo repository hook', () {
    late MongoDriverAdapter adapter;

    setUp(() {
      adapter = MongoDriverAdapter.custom(
        config: const DatabaseConfig(
          driver: 'mongo',
          options: {'database': 'orm_test'},
        ),
      );
    });

    tearDown(() async {
      await adapter.close();
    });

    test('annotated models receive MongoRepository and reject returning', () {
      final registry = ModelRegistry();
      registry.register<Map<String, Object?>>(
        _buildDefinition(annotated: true),
      );
      final context = QueryContext(registry: registry, driver: adapter);

      final repository = context.repository<Map<String, Object?>>();
      expect(repository, isA<MongoRepository<Map<String, Object?>>>());
      expect(
        () => repository.insertMany(const [
          {'name': 'widget'},
        ], returning: true),
        throwsUnsupportedError,
      );
    });

    test('plain models keep the default repository', () {
      final registry = ModelRegistry();
      registry.register<Map<String, Object?>>(_buildDefinition());
      final context = QueryContext(registry: registry, driver: adapter);

      final repository = context.repository<Map<String, Object?>>();
      expect(repository, isNot(isA<MongoRepository<Map<String, Object?>>>()));
    });
  });
}

ModelDefinition<Map<String, Object?>> _buildDefinition({
  bool annotated = false,
}) {
  final columns = const [AdHocColumn(name: '_id', isPrimaryKey: true)];
  final base = AdHocModelDefinition(
    tableName: 'hooked_models',
    columns: columns,
  );
  if (!annotated) return base;
  return base.copyWith(
    metadata: const ModelAttributesMetadata(
      driverAnnotations: [DriverModel('mongo')],
    ),
  );
}
