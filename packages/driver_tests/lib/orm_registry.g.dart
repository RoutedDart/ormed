// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
import 'package:ormed/ormed.dart';
import 'src/models/active_user.dart';
import 'src/models/article.dart';
import 'src/models/attribute_user.dart';
import 'src/models/author.dart';
import 'src/models/comment.dart';
import 'src/models/custom_soft_delete.dart';
import 'src/models/derived_for_factory.dart';
import 'src/models/driver_override_entry.dart';
import 'src/models/driver_override.dart';
import 'src/models/image.dart';
import 'src/models/mutation_target.dart';
import 'src/models/named_constructor_model.dart';
import 'src/models/photo.dart';
import 'src/models/post.dart';
import 'src/models/post_tag.dart';
import 'src/models/serial_test.dart';
import 'src/models/settings.dart';
import 'src/models/tag.dart';
import 'src/models/unique_user.dart';
import 'src/models/user.dart';

final List<ModelDefinition<dynamic>> _$ormModelDefinitions = [
  ActiveUserOrmDefinition.definition,
  ArticleOrmDefinition.definition,
  AttributeUserOrmDefinition.definition,
  AuthorOrmDefinition.definition,
  CommentOrmDefinition.definition,
  CustomSoftDeleteOrmDefinition.definition,
  DerivedForFactoryOrmDefinition.definition,
  DriverOverrideEntryOrmDefinition.definition,
  DriverOverrideModelOrmDefinition.definition,
  ImageOrmDefinition.definition,
  MutationTargetOrmDefinition.definition,
  NamedConstructorModelOrmDefinition.definition,
  PhotoOrmDefinition.definition,
  PostOrmDefinition.definition,
  PostTagOrmDefinition.definition,
  SerialTestOrmDefinition.definition,
  SettingOrmDefinition.definition,
  TagOrmDefinition.definition,
  UniqueUserOrmDefinition.definition,
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
