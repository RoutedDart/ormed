// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
import 'package:ormed/ormed.dart';
import 'models/admin.dart';
import 'events/model_events.dart';
import 'models/comment.dart';
import 'generated_code_usage.dart';
import 'models/factory_user.dart';
import 'models/log_model.dart';
import 'models/post.dart';
import 'models/product.dart';
import 'models/model_scopes.dart';
import 'models/user.dart';
import 'best_practices/best_practices.dart';

final List<ModelDefinition<OrmEntity>> _$ormModelDefinitions = [
  AdminOrmDefinition.definition,
  AuditedUserOrmDefinition.definition,
  CommentOrmDefinition.definition,
  DocumentOrmDefinition.definition,
  FactoryUserOrmDefinition.definition,
  LogOrmDefinition.definition,
  PostOrmDefinition.definition,
  ProductOrmDefinition.definition,
  ScopedUserOrmDefinition.definition,
  UserOrmDefinition.definition,
  ValidatedUserOrmDefinition.definition,
];

ModelRegistry buildOrmRegistry() => ModelRegistry()
  ..registerAll(_$ormModelDefinitions)
  ..registerTypeAlias<Admin>(_$ormModelDefinitions[0])
  ..registerTypeAlias<AuditedUser>(_$ormModelDefinitions[1])
  ..registerTypeAlias<Comment>(_$ormModelDefinitions[2])
  ..registerTypeAlias<Document>(_$ormModelDefinitions[3])
  ..registerTypeAlias<FactoryUser>(_$ormModelDefinitions[4])
  ..registerTypeAlias<Log>(_$ormModelDefinitions[5])
  ..registerTypeAlias<Post>(_$ormModelDefinitions[6])
  ..registerTypeAlias<Product>(_$ormModelDefinitions[7])
  ..registerTypeAlias<ScopedUser>(_$ormModelDefinitions[8])
  ..registerTypeAlias<User>(_$ormModelDefinitions[9])
  ..registerTypeAlias<ValidatedUser>(_$ormModelDefinitions[10])
  ;

List<ModelDefinition<OrmEntity>> get generatedOrmModelDefinitions =>
    List.unmodifiable(_$ormModelDefinitions);

extension GeneratedOrmModels on ModelRegistry {
  ModelRegistry registerGeneratedModels() {
    registerAll(_$ormModelDefinitions);
    registerTypeAlias<Admin>(_$ormModelDefinitions[0]);
    registerTypeAlias<AuditedUser>(_$ormModelDefinitions[1]);
    registerTypeAlias<Comment>(_$ormModelDefinitions[2]);
    registerTypeAlias<Document>(_$ormModelDefinitions[3]);
    registerTypeAlias<FactoryUser>(_$ormModelDefinitions[4]);
    registerTypeAlias<Log>(_$ormModelDefinitions[5]);
    registerTypeAlias<Post>(_$ormModelDefinitions[6]);
    registerTypeAlias<Product>(_$ormModelDefinitions[7]);
    registerTypeAlias<ScopedUser>(_$ormModelDefinitions[8]);
    registerTypeAlias<User>(_$ormModelDefinitions[9]);
    registerTypeAlias<ValidatedUser>(_$ormModelDefinitions[10]);
    return this;
  }
}

/// Registers factory definitions for all models that have factory support.
/// Call this before using [Model.factory<T>()] to ensure definitions are available.
void registerOrmFactories() {
  ModelFactoryRegistry.registerIfAbsent<FactoryUser>(FactoryUserOrmDefinition.definition);
}

/// Combined setup: registers both model registry and factories.
/// Returns a ModelRegistry with all generated models registered.
ModelRegistry buildOrmRegistryWithFactories() {
  registerOrmFactories();
  return buildOrmRegistry();
}

/// Registers generated model event handlers.
void registerModelEventHandlers({EventBus? bus}) {
  final _bus = bus ?? EventBus.instance;
  registerAuditedUserEventHandlers(_bus);
}

/// Registers generated model scopes into a [ScopeRegistry].
void registerModelScopes({ScopeRegistry? scopeRegistry}) {
  final _registry = scopeRegistry ?? ScopeRegistry.instance;
  registerScopedUserScopes(_registry);
}

/// Bootstraps generated ORM pieces: registry, factories, event handlers, and scopes.
ModelRegistry bootstrapOrm({ModelRegistry? registry, EventBus? bus, ScopeRegistry? scopes, bool registerFactories = true, bool registerEventHandlers = true, bool registerScopes = true}) {
  final reg = registry ?? buildOrmRegistry();
  if (registerFactories) {
    registerOrmFactories();
  }
  if (registerEventHandlers) {
    registerModelEventHandlers(bus: bus);
  }
  if (registerScopes) {
    registerModelScopes(scopeRegistry: scopes);
  }
  return reg;
}
