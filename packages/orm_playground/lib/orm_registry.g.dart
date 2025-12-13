// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
import 'package:ormed/ormed.dart';
import 'src/models/author.dart';
import 'src/models/comment.dart';
import 'src/models/post.dart';
import 'src/models/post_tag.dart';
import 'src/models/tag.dart';
import 'src/models/user.dart';

final List<ModelDefinition<OrmEntity>> _$ormModelDefinitions = [
  AuthorOrmDefinition.definition,
  CommentOrmDefinition.definition,
  PostOrmDefinition.definition,
  PostTagOrmDefinition.definition,
  TagOrmDefinition.definition,
  UserOrmDefinition.definition,
];

ModelRegistry buildOrmRegistry() => ModelRegistry()
  ..registerAll(_$ormModelDefinitions)
  ..registerTypeAlias<Author>(_$ormModelDefinitions[0])
  ..registerTypeAlias<Comment>(_$ormModelDefinitions[1])
  ..registerTypeAlias<Post>(_$ormModelDefinitions[2])
  ..registerTypeAlias<PostTag>(_$ormModelDefinitions[3])
  ..registerTypeAlias<Tag>(_$ormModelDefinitions[4])
  ..registerTypeAlias<User>(_$ormModelDefinitions[5])
  ;

List<ModelDefinition<OrmEntity>> get generatedOrmModelDefinitions =>
    List.unmodifiable(_$ormModelDefinitions);

extension GeneratedOrmModels on ModelRegistry {
  ModelRegistry registerGeneratedModels() {
    registerAll(_$ormModelDefinitions);
    registerTypeAlias<Author>(_$ormModelDefinitions[0]);
    registerTypeAlias<Comment>(_$ormModelDefinitions[1]);
    registerTypeAlias<Post>(_$ormModelDefinitions[2]);
    registerTypeAlias<PostTag>(_$ormModelDefinitions[3]);
    registerTypeAlias<Tag>(_$ormModelDefinitions[4]);
    registerTypeAlias<User>(_$ormModelDefinitions[5]);
    return this;
  }
}

/// Registers factory definitions for all models that have factory support.
/// Call this before using Model.factory<T>() to ensure definitions are available.
void registerOrmFactories() {
}

/// Combined setup: registers both model registry and factories.
/// Returns a ModelRegistry with all generated models registered.
ModelRegistry buildOrmRegistryWithFactories() {
  registerOrmFactories();
  return buildOrmRegistry();
}
