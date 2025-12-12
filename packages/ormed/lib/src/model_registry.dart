import 'dart:async';

import 'exceptions.dart';
import 'model_definition.dart';

/// Simple registry to share model definitions across the app/runtime.
class ModelRegistry {
  final Map<Type, ModelDefinition<dynamic>> _definitions = {};
  final Map<String, ModelDefinition<dynamic>> _definitionsByName = {};
  final Map<String, ModelDefinition<dynamic>> _definitionsByTable = {};
  final StreamController<ModelDefinition<dynamic>> _onRegistered =
      StreamController.broadcast();
  final List<void Function(ModelDefinition<dynamic>)> _onRegisteredCallbacks =
      [];

  Stream<ModelDefinition<dynamic>> get onRegistered => _onRegistered.stream;

  void addOnRegisteredCallback(
    void Function(ModelDefinition<dynamic>) callback,
  ) {
    _onRegisteredCallbacks.add(callback);
  }

  void register<T>(ModelDefinition<T> definition) {
    if (_definitions.containsKey(definition.modelType)) {
      return; // Skip already registered types
    }
    _definitions[definition.modelType] = definition;
    _definitionsByName[definition.modelName] = definition;
    _definitionsByTable[definition.tableName] = definition;
    _onRegistered.add(definition);
    for (final callback in _onRegisteredCallbacks) {
      callback(definition);
    }
  }

  void registerAll(Iterable<ModelDefinition<dynamic>> definitions) {
    for (final definition in definitions) {
      if (_definitions.containsKey(definition.modelType)) {
        continue; // Skip already registered types
      }
      _definitions[definition.modelType] = definition;
      _definitionsByName[definition.modelName] = definition;
      _definitionsByTable[definition.tableName] = definition;
      _onRegistered.add(definition);
      for (final callback in _onRegisteredCallbacks) {
        callback(definition);
      }
    }
  }
  
  /// Register a type alias that maps to an existing definition
  void registerTypeAlias<T>(ModelDefinition existingDefinition) {
    if (_definitions.containsKey(T)) {
      return; // Skip already registered types
    }
    _definitions[T] = existingDefinition;
  }
  
  /// Returns all registered model definitions (deduplicated)
  List<ModelDefinition<dynamic>> get allDefinitions {
    final seen = <String>{};
    final result = <ModelDefinition<dynamic>>[];
    for (final def in _definitions.values) {
      if (seen.add(def.modelName)) {
        result.add(def);
      }
    }
    return result;
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

  /// Returns the model definition for the given [tableName], or null if not found.
  ModelDefinition<dynamic>? findByTableName(String tableName) {
    return _definitionsByTable[tableName];
  }

  /// Returns the model definition for the given [tableName] or throws.
  ModelDefinition<dynamic> expectByTableName(String tableName) {
    final definition = _definitionsByTable[tableName];
    if (definition == null) {
      throw ModelNotRegisteredByTableName(tableName);
    }
    return definition;
  }

  bool contains<T>() => _definitions.containsKey(T);

  Iterable<ModelDefinition<dynamic>> get values => _definitions.values;
}
