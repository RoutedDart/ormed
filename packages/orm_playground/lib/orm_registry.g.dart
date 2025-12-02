// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
import 'package:ormed/ormed.dart';
import 'src/models/author.dart';
import 'src/models/comment.dart';
import 'src/models/post.dart';
import 'src/models/post_tag.dart';
import 'src/models/tag.dart';
import 'src/models/user.dart';

final List<ModelDefinition<dynamic>> _$ormModelDefinitions = [
  AuthorOrmDefinition.definition,
  CommentOrmDefinition.definition,
  PostOrmDefinition.definition,
  PostTagOrmDefinition.definition,
  TagOrmDefinition.definition,
  UserOrmDefinition.definition,
];

ModelRegistry buildOrmRegistry() => ModelRegistry()
  ..registerAll(_$ormModelDefinitions);

List<ModelDefinition<dynamic>> get generatedOrmModelDefinitions =>
    List.unmodifiable(_$ormModelDefinitions);

extension GeneratedOrmModels on ModelRegistry {
  ModelRegistry registerGeneratedModels() {
    registerAll(_$ormModelDefinitions);
    return this;
  }
}
