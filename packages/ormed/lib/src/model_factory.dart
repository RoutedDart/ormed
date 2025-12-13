import 'dart:math';

import 'model.dart';
import 'model_definition.dart';
import 'query/query.dart';
import 'value_codec.dart';

/// Context passed to generators while building factory output.
class ModelFactoryGenerationContext<TModel> {
  ModelFactoryGenerationContext({
    required this.definition,
    required this.random,
    required this.overrides,
    this.seed,
  });

  final ModelDefinition<TModel> definition;
  final Random random;
  final Map<String, Object?> overrides;
  final int? seed;
}

/// Signature used to generate a field value for a factory.
typedef FieldValueGenerator<TModel> =
    Object? Function(
      FieldDefinition field,
      ModelFactoryGenerationContext<TModel> context,
    );

/// Provides backend-aware fallbacks when no bespoke generator is supplied.
abstract class GeneratorProvider {
  const GeneratorProvider();

  Object? generate<TModel>(
    FieldDefinition field,
    ModelFactoryGenerationContext<TModel> context,
  );
}

/// Default generator that returns simple primitives for scalar fields.
class DefaultFieldGeneratorProvider extends GeneratorProvider {
  const DefaultFieldGeneratorProvider();

  @override
  Object? generate<TModel>(
    FieldDefinition field,
    ModelFactoryGenerationContext<TModel> context,
  ) {
    if (field.isNullable && context.random.nextBool()) {
      return null;
    }
    final type = _stripNullability(field.resolvedType);
    if (type == 'int') {
      return context.random.nextInt(1000) + 1;
    }
    if (type == 'double' || type == 'num') {
      return context.random.nextDouble() * 1000;
    }
    if (type == 'bool') {
      return context.random.nextBool();
    }
    if (type == 'DateTime') {
      return DateTime.now().toUtc().add(
        Duration(seconds: context.random.nextInt(60 * 60 * 24)),
      );
    }
    if (type == 'String') {
      final suffix = context.random.nextInt(10000).toString().padLeft(4, '0');
      return '${context.definition.modelName}_${field.name}_$suffix';
    }
    if (type.startsWith('Map<')) {
      return <String, Object?>{};
    }
    if (type.startsWith('List<')) {
      return <Object?>[];
    }
    return null;
  }

  static String _stripNullability(String type) {
    return type.endsWith('?') ? type.substring(0, type.length - 1) : type;
  }
}

/// Builder used by generated factory helpers.
class ModelFactoryBuilder<TModel> {
  ModelFactoryBuilder({
    required this.definition,
    GeneratorProvider? generatorProvider,
  }) : _generatorProvider =
           generatorProvider ?? const DefaultFieldGeneratorProvider();

  final ModelDefinition<TModel> definition;
  final GeneratorProvider _generatorProvider;

  final Map<String, Object?> _overrides = {};
  final Map<String, FieldValueGenerator<TModel>> _fieldGenerators = {};

  int? _seed;
  Map<String, Object?>? _generatedValues;
  Random? _random;

  /// Clears generated values so the next call can pick new ones.
  ModelFactoryBuilder<TModel> reset() {
    _invalidate();
    return this;
  }

  /// Sets a deterministic seed for the factory output.
  ModelFactoryBuilder<TModel> seed(int seed) {
    _seed = seed;
    _invalidate();
    return this;
  }

  /// Supplies field overrides by column name or attribute name.
  ModelFactoryBuilder<TModel> withOverrides(Map<String, Object?> overrides) {
    for (final entry in overrides.entries) {
      final column = _canonicalColumn(entry.key);
      _overrides[column] = entry.value;
    }
    _invalidate();
    return this;
  }

  /// Overrides a single field by column or attribute name.
  ModelFactoryBuilder<TModel> withField(String field, Object? value) {
    return withOverrides({field: value});
  }

  /// Replaces the generator used for a given field by column or attribute name.
  ModelFactoryBuilder<TModel> withGenerator(
    String field,
    FieldValueGenerator<TModel> generator,
  ) {
    final column = _canonicalColumn(field);
    _fieldGenerators[column] = generator;
    _invalidate();
    return this;
  }

  /// Builds the column map the factory would use for a new model.
  Map<String, Object?> values() {
    _ensureValues();
    return Map<String, Object?>.unmodifiable(_generatedValues!);
  }

  /// Returns a single column value from the generated map.
  Object? value(String field) {
    final column = _canonicalColumn(field);
    return values()[column];
  }

  /// Instantiates the model without persisting it.
  TModel make({ValueCodecRegistry? registry}) {
    final payload = values();
    return definition.fromMap(payload, registry: registry);
  }

  /// Persists the generated model through the ORM.
  Future<TModel> create({
    QueryContext? context,
    bool returning = true,
    ValueCodecRegistry? registry,
  }) async {
    final model = make(registry: registry);
    if (context != null && model is Model) {
      model.attachConnectionResolver(context);
    }
    if (model is Model) {
      return model.save(returning: returning) as TModel;
    }
    throw StateError(
      'Cannot persist $TModel because it does not extend Model.',
    );
  }

  void _ensureValues() {
    if (_generatedValues != null) return;
    _random ??= _seed != null ? Random(_seed!) : Random();
    final context = ModelFactoryGenerationContext<TModel>(
      definition: definition,
      random: _random!,
      overrides: Map<String, Object?>.unmodifiable(_overrides),
      seed: _seed,
    );
    final values = <String, Object?>{};
    values.addAll(_overrides);
    for (final field in definition.fields) {
      final column = field.columnName;
      if (values.containsKey(column)) {
        continue;
      }
      if (!_shouldGenerateField(field)) {
        continue;
      }
      final generator =
          _fieldGenerators[column] ?? _fieldGenerators[field.name];
      final value = generator != null
          ? generator(field, context)
          : _generatorProvider.generate(field, context);
      values[column] = value;
    }
    _generatedValues = values;
  }

  bool _shouldGenerateField(FieldDefinition field) {
    if (field.autoIncrement && !_overrides.containsKey(field.columnName)) {
      return false;
    }
    if (field.defaultValueSql != null &&
        !_overrides.containsKey(field.columnName)) {
      return false;
    }
    if (field.codecType != null && !_overrides.containsKey(field.columnName)) {
      return false;
    }
    return true;
  }

  String _canonicalColumn(String key) {
    final fieldByName = definition.fieldByName(key);
    if (fieldByName != null) {
      return fieldByName.columnName;
    }
    final fieldByColumn = definition.fieldByColumn(key);
    if (fieldByColumn != null) {
      return fieldByColumn.columnName;
    }
    return key;
  }

  void _invalidate() {
    _generatedValues = null;
    _random = null;
  }
}

/// Internal registry that associates models with their generated definitions.
class ModelFactoryRegistry {
  ModelFactoryRegistry._();

  static final Map<Type, ModelDefinition<dynamic>> _definitions = {};

  static ModelDefinition<TModel> register<TModel>(
    ModelDefinition<TModel> definition,
  ) {
    _definitions[TModel] = definition;
    return definition;
  }

  /// Registers a definition only if one is not already registered for the type.
  /// Returns the existing or newly registered definition.
  static ModelDefinition<TModel> registerIfAbsent<TModel>(
    ModelDefinition<TModel> definition,
  ) {
    return _definitions.putIfAbsent(TModel, () => definition)
        as ModelDefinition<TModel>;
  }

  static ModelDefinition<TModel> definitionFor<TModel extends Model<TModel>>() {
    final definition = _definitions[TModel];
    if (definition == null) {
      throw StateError(
        'No definition registered for $TModel. Ensure the generated '
        'ORM helper is imported so it can register itself.',
      );
    }
    return definition as ModelDefinition<TModel>;
  }
}
