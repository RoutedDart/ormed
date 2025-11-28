// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
import 'package:ormed/ormed.dart';

final List<ModelDefinition<dynamic>> _$ormModelDefinitions = [];

ModelRegistry buildOrmRegistry() =>
    ModelRegistry()..registerAll(_$ormModelDefinitions);

List<ModelDefinition<dynamic>> get generatedOrmModelDefinitions =>
    List.unmodifiable(_$ormModelDefinitions);

extension GeneratedOrmModels on ModelRegistry {
  ModelRegistry registerGeneratedModels() {
    registerAll(_$ormModelDefinitions);
    return this;
  }
}
