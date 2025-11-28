// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
import 'package:ormed/ormed.dart';
import 'src/models/article.dart';
import 'src/models/author.dart';
import 'src/models/comment.dart';
import 'src/models/driver_override_entry.dart';
import 'src/models/image.dart';
import 'src/models/mutation_target.dart';
import 'src/models/photo.dart';
import 'src/models/post.dart';
import 'src/models/post_tag.dart';
import 'src/models/serial_test.dart';
import 'src/models/settings.dart';
import 'src/models/tag.dart';
import 'src/models/unique_user.dart';
import 'src/models/user.dart';

final List<ModelDefinition<dynamic>> _$ormModelDefinitions = [
  ArticleOrmDefinition.definition,
  AuthorOrmDefinition.definition,
  CommentOrmDefinition.definition,
  DriverOverrideEntryOrmDefinition.definition,
  ImageOrmDefinition.definition,
  MutationTargetOrmDefinition.definition,
  PhotoOrmDefinition.definition,
  PostOrmDefinition.definition,
  PostTagOrmDefinition.definition,
  SerialTestOrmDefinition.definition,
  SettingOrmDefinition.definition,
  TagOrmDefinition.definition,
  UniqueUserOrmDefinition.definition,
  UserOrmDefinition.definition,
];

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
