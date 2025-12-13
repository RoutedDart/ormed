import 'dart:async';

import 'exceptions.dart';
import 'contracts.dart';
import 'model_definition.dart';

/// Simple registry to share model definitions across the app/runtime.
class ModelRegistry {
  final Map<Type, ModelDefinition<OrmEntity>> _definitions = {};
  final Map<String, ModelDefinition<OrmEntity>> _definitionsByName = {};
  final Map<String, ModelDefinition<OrmEntity>> _definitionsByTable = {};
  final StreamController<ModelDefinition<OrmEntity>> _onRegistered =
      StreamController.broadcast();
  final List<void Function(ModelDefinition<OrmEntity>)> _onRegisteredCallbacks =
      [];

  Stream<ModelDefinition<OrmEntity>> get onRegistered => _onRegistered.stream;

  void addOnRegisteredCallback(
    void Function(ModelDefinition<OrmEntity>) callback,
  ) {
    _onRegisteredCallbacks.add(callback);
  }

  void register<T extends OrmEntity>(ModelDefinition<T> definition) {
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

  void registerAll(Iterable<ModelDefinition<OrmEntity>> definitions) {
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
  void registerTypeAlias<T extends OrmEntity>(ModelDefinition<OrmEntity> existingDefinition) {
    if (_definitions.containsKey(T)) {
      return; // Skip already registered types
    }
    _definitions[T] = existingDefinition;
  }
  
  /// Returns all registered model definitions (deduplicated)
  List<ModelDefinition<OrmEntity>> get allDefinitions {
    final seen = <String>{};
    final result = <ModelDefinition<OrmEntity>>[];
    for (final def in _definitions.values) {
      if (seen.add(def.modelName)) {
        result.add(def);
      }
    }
    return result;
  }

  ModelDefinition<T> registerAlias<T extends OrmEntity>(
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

  ModelDefinition<T> expect<T extends OrmEntity>() {
    final definition = _definitions[T];
    if (definition == null) {
      throw ModelNotRegistered(T);
    }
    return definition as ModelDefinition<T>;
  }

  /// Returns the model definition registered under [name] or throws.
  ModelDefinition<OrmEntity> expectByName(String name) {
    final definition = _definitionsByName[name];
    if (definition == null) {
      throw ModelNotRegisteredByName(name);
    }
    return definition;
  }

  /// Returns the model definition for the given [tableName], or null if not found.
  ModelDefinition<OrmEntity>? findByTableName(String tableName) {
    return _definitionsByTable[tableName];
  }

  /// Returns the model definition for the given [tableName] or throws.
  ModelDefinition<OrmEntity> expectByTableName(String tableName) {
    final definition = _definitionsByTable[tableName];
    if (definition == null) {
      throw ModelNotRegisteredByTableName(tableName);
    }
    return definition;
  }

  bool contains<T>() => _definitions.containsKey(T);

  Iterable<ModelDefinition<OrmEntity>> get values => _definitions.values;
}
