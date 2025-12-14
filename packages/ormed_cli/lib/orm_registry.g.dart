// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
import 'package:ormed/ormed.dart';

final List<ModelDefinition<OrmEntity>> _$ormModelDefinitions = [];

ModelRegistry buildOrmRegistry() =>
    ModelRegistry()..registerAll(_$ormModelDefinitions);

List<ModelDefinition<OrmEntity>> get generatedOrmModelDefinitions =>
    List.unmodifiable(_$ormModelDefinitions);

extension GeneratedOrmModels on ModelRegistry {
  ModelRegistry registerGeneratedModels() {
    registerAll(_$ormModelDefinitions);
    return this;
  }
}

/// Registers factory definitions for all models that have factory support.
/// Call this before using Model.factory<T>() to ensure definitions are available.
void registerOrmFactories() {}

/// Combined setup: registers both model registry and factories.
/// Returns a ModelRegistry with all generated models registered.
ModelRegistry buildOrmRegistryWithFactories() {
  registerOrmFactories();
  return buildOrmRegistry();
}
