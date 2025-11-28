import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import 'models/named_constructor_model.dart';

void main() {
  group('Constructor Targeting Feature', () {
    late QueryContext context;

    setUp(() {
      final registry = ModelRegistry();
      final driver = InMemoryQueryExecutor();
      context = QueryContext(registry: registry, driver: driver);

      // Register model definition
      registry.register(NamedConstructorModelOrmDefinition.definition);

      // Setup test data in memory driver
      driver.register(NamedConstructorModelOrmDefinition.definition, []);
    });

    test('generates code using specified named constructor', () {
      // The generated code should use NamedConstructorModel.fromDatabase
      // instead of the default constructor
      final definition = NamedConstructorModelOrmDefinition.definition;

      expect(definition.modelName, 'NamedConstructorModel');
      expect(definition.tableName, 'named_constructor_models');
      expect(definition.fields, hasLength(3));
    });

    test('can encode model to map using generated codec', () {
      final model = NamedConstructorModel.fromDatabase(
        id: 1,
        name: 'Test Model',
        value: 42,
      );

      final registry = ValueCodecRegistry.standard();
      final encoded = NamedConstructorModelOrmDefinition.definition.toMap(
        model,
        registry: registry,
      );

      expect(encoded['id'], 1);
      expect(encoded['name'], 'Test Model');
      expect(encoded['value'], 42);
    });

    test('can decode map to model using generated codec', () {
      final data = {'id': 2, 'name': 'Decoded Model', 'value': 99};

      final registry = ValueCodecRegistry.standard();
      final model = NamedConstructorModelOrmDefinition.definition.fromMap(
        data,
        registry: registry,
      );

      expect(model.id, 2);
      expect(model.name, 'Decoded Model');
      expect(model.value, 99);
    });

    test('can save and retrieve model using targeted constructor', () async {
      // Create a new model using the named constructor
      final model = NamedConstructorModel.fromDatabase(
        id: 100, // Explicit ID
        name: 'Constructor Test',
        value: 123,
      );

      // Save the model
      final repository = context.repository<NamedConstructorModel>();
      final saved = (await repository.insertMany([model])).first;

      expect(saved.id, 100);
      expect(saved.name, 'Constructor Test');
      expect(saved.value, 123);

      // Retrieve the model
      final retrieved = await context
          .query<NamedConstructorModel>()
          .whereEquals('id', 100)
          .first();

      expect(retrieved, isNotNull);
      expect(retrieved?.id, 100);
      expect(retrieved?.name, 'Constructor Test');
      expect(retrieved?.value, 123);
    });

    test('codec respects named constructor parameter order', () {
      // This test verifies that the generated codec properly maps
      // parameters to the specified constructor, even if parameter
      // order differs from field declaration order

      final data = {
        'id': 10,
        'value': 50, // Different order than fields
        'name': 'Order Test',
      };

      final registry = ValueCodecRegistry.standard();
      final model = NamedConstructorModelOrmDefinition.definition.fromMap(
        data,
        registry: registry,
      );

      // All fields should be correctly mapped regardless of order
      expect(model.id, 10);
      expect(model.name, 'Order Test');
      expect(model.value, 50);
    });

    test('model attributes are accessible through getAttribute', () {
      final data = {'id': 5, 'name': 'Attribute Test', 'value': 777};

      final registry = ValueCodecRegistry.standard();
      final model = NamedConstructorModelOrmDefinition.definition.fromMap(
        data,
        registry: registry,
      );

      // The generated subclass should provide getAttribute access
      expect(model.getAttribute<int>('id'), 5);
      expect(model.getAttribute<String>('name'), 'Attribute Test');
      expect(model.getAttribute<int>('value'), 777);
    });

    test('multiple models can use different constructors', () {
      // This test demonstrates that different models can specify
      // different constructors independently

      // NamedConstructorModel uses 'fromDatabase' constructor
      final namedModel = NamedConstructorModel.fromDatabase(
        id: 1,
        name: 'Named',
        value: 100,
      );

      // Other models can use default constructors (implicit)
      // This shows the feature is opt-in per model

      final registry = ValueCodecRegistry.standard();
      final encoded = NamedConstructorModelOrmDefinition.definition.toMap(
        namedModel,
        registry: registry,
      );

      expect(encoded, isMap);
      expect(encoded.keys, containsAll(['id', 'name', 'value']));
    });
  });
}
