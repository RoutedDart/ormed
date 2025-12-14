// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
import 'package:ormed/ormed.dart';
import 'models/admin.dart';
import 'models/comment.dart';
import 'generated_code_usage.dart';
import 'models/factory_user.dart';
import 'models/log_model.dart';
import 'models/post.dart';
import 'models/product.dart';
import 'models/user.dart';
import 'best_practices/best_practices.dart';

final List<ModelDefinition<OrmEntity>> _$ormModelDefinitions = [
  AdminOrmDefinition.definition,
  CommentOrmDefinition.definition,
  DocumentOrmDefinition.definition,
  FactoryUserOrmDefinition.definition,
  LogOrmDefinition.definition,
  PostOrmDefinition.definition,
  ProductOrmDefinition.definition,
  UserOrmDefinition.definition,
  ValidatedUserOrmDefinition.definition,
];

ModelRegistry buildOrmRegistry() => ModelRegistry()
  ..registerAll(_$ormModelDefinitions)
  ..registerTypeAlias<Admin>(_$ormModelDefinitions[0])
  ..registerTypeAlias<Comment>(_$ormModelDefinitions[1])
  ..registerTypeAlias<Document>(_$ormModelDefinitions[2])
  ..registerTypeAlias<FactoryUser>(_$ormModelDefinitions[3])
  ..registerTypeAlias<Log>(_$ormModelDefinitions[4])
  ..registerTypeAlias<Post>(_$ormModelDefinitions[5])
  ..registerTypeAlias<Product>(_$ormModelDefinitions[6])
  ..registerTypeAlias<User>(_$ormModelDefinitions[7])
  ..registerTypeAlias<ValidatedUser>(_$ormModelDefinitions[8])
  ;

List<ModelDefinition<OrmEntity>> get generatedOrmModelDefinitions =>
    List.unmodifiable(_$ormModelDefinitions);

extension GeneratedOrmModels on ModelRegistry {
  ModelRegistry registerGeneratedModels() {
    registerAll(_$ormModelDefinitions);
    registerTypeAlias<Admin>(_$ormModelDefinitions[0]);
    registerTypeAlias<Comment>(_$ormModelDefinitions[1]);
    registerTypeAlias<Document>(_$ormModelDefinitions[2]);
    registerTypeAlias<FactoryUser>(_$ormModelDefinitions[3]);
    registerTypeAlias<Log>(_$ormModelDefinitions[4]);
    registerTypeAlias<Post>(_$ormModelDefinitions[5]);
    registerTypeAlias<Product>(_$ormModelDefinitions[6]);
    registerTypeAlias<User>(_$ormModelDefinitions[7]);
    registerTypeAlias<ValidatedUser>(_$ormModelDefinitions[8]);
    return this;
  }
}

/// Registers factory definitions for all models that have factory support.
/// Call this before using Model.factory<T>() to ensure definitions are available.
void registerOrmFactories() {
  ModelFactoryRegistry.registerIfAbsent<FactoryUser>(FactoryUserOrmDefinition.definition);
}

/// Combined setup: registers both model registry and factories.
/// Returns a ModelRegistry with all generated models registered.
ModelRegistry buildOrmRegistryWithFactories() {
  registerOrmFactories();
  return buildOrmRegistry();
}
