import 'exceptions.dart';
import 'model_definition.dart';

/// Simple registry to share model definitions across the app/runtime.
class ModelRegistry {
  final Map<Type, ModelDefinition<dynamic>> _definitions = {};
  final Map<String, ModelDefinition<dynamic>> _definitionsByName = {};

  void register<T>(ModelDefinition<T> definition) {
    _definitions[definition.modelType] = definition;
    _definitionsByName[definition.modelName] = definition;
  }

  void registerAll(Iterable<ModelDefinition<dynamic>> definitions) {
    for (final definition in definitions) {
      _definitions[definition.modelType] = definition;
      _definitionsByName[definition.modelName] = definition;
    }
  }

  ModelDefinition<T> registerAlias<T>(
    ModelDefinition<T> base, {
    required String aliasModelName,
    String? tableName,
    String? schema,
  }) {
    final aliased = base.copyWith(
      modelName: aliasModelName,
      tableName: tableName ?? base.tableName,
      schema: schema ?? base.schema,
    );
    _definitionsByName[aliasModelName] = aliased;
    return aliased;
  }

  ModelDefinition<T> expect<T>() {
    final definition = _definitions[T];
    if (definition == null) {
      throw ModelNotRegistered(T);
    }
    return definition as ModelDefinition<T>;
  }

  /// Returns the model definition registered under [name] or throws.
  ModelDefinition<dynamic> expectByName(String name) {
    final definition = _definitionsByName[name];
    if (definition == null) {
      throw ModelNotRegisteredByName(name);
    }
    return definition;
  }

  bool contains<T>() => _definitions.containsKey(T);

  Iterable<ModelDefinition<dynamic>> get values => _definitions.values;
}
