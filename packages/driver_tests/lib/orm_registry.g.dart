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
import 'src/models/no_factory.dart';
import 'src/models/photo.dart';
import 'src/models/post.dart';
import 'src/models/post_tag.dart';
import 'src/models/serial_test.dart';
import 'src/models/settings.dart';
import 'src/models/tag.dart';
import 'src/models/unique_user.dart';
import 'src/models/user.dart';

final List<ModelDefinition<OrmEntity>> _$ormModelDefinitions = [
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
  NoFactoryOrmDefinition.definition,
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
  ..registerAll(_$ormModelDefinitions)
  ..registerTypeAlias<ActiveUser>(_$ormModelDefinitions[0])
  ..registerTypeAlias<Article>(_$ormModelDefinitions[1])
  ..registerTypeAlias<AttributeUser>(_$ormModelDefinitions[2])
  ..registerTypeAlias<Author>(_$ormModelDefinitions[3])
  ..registerTypeAlias<Comment>(_$ormModelDefinitions[4])
  ..registerTypeAlias<CustomSoftDelete>(_$ormModelDefinitions[5])
  ..registerTypeAlias<DerivedForFactory>(_$ormModelDefinitions[6])
  ..registerTypeAlias<DriverOverrideEntry>(_$ormModelDefinitions[7])
  ..registerTypeAlias<DriverOverrideModel>(_$ormModelDefinitions[8])
  ..registerTypeAlias<Image>(_$ormModelDefinitions[9])
  ..registerTypeAlias<MutationTarget>(_$ormModelDefinitions[10])
  ..registerTypeAlias<NamedConstructorModel>(_$ormModelDefinitions[11])
  ..registerTypeAlias<NoFactory>(_$ormModelDefinitions[12])
  ..registerTypeAlias<Photo>(_$ormModelDefinitions[13])
  ..registerTypeAlias<Post>(_$ormModelDefinitions[14])
  ..registerTypeAlias<PostTag>(_$ormModelDefinitions[15])
  ..registerTypeAlias<SerialTest>(_$ormModelDefinitions[16])
  ..registerTypeAlias<Setting>(_$ormModelDefinitions[17])
  ..registerTypeAlias<Tag>(_$ormModelDefinitions[18])
  ..registerTypeAlias<UniqueUser>(_$ormModelDefinitions[19])
  ..registerTypeAlias<User>(_$ormModelDefinitions[20]);

List<ModelDefinition<OrmEntity>> get generatedOrmModelDefinitions =>
    List.unmodifiable(_$ormModelDefinitions);

extension GeneratedOrmModels on ModelRegistry {
  ModelRegistry registerGeneratedModels() {
    registerAll(_$ormModelDefinitions);
    registerTypeAlias<ActiveUser>(_$ormModelDefinitions[0]);
    registerTypeAlias<Article>(_$ormModelDefinitions[1]);
    registerTypeAlias<AttributeUser>(_$ormModelDefinitions[2]);
    registerTypeAlias<Author>(_$ormModelDefinitions[3]);
    registerTypeAlias<Comment>(_$ormModelDefinitions[4]);
    registerTypeAlias<CustomSoftDelete>(_$ormModelDefinitions[5]);
    registerTypeAlias<DerivedForFactory>(_$ormModelDefinitions[6]);
    registerTypeAlias<DriverOverrideEntry>(_$ormModelDefinitions[7]);
    registerTypeAlias<DriverOverrideModel>(_$ormModelDefinitions[8]);
    registerTypeAlias<Image>(_$ormModelDefinitions[9]);
    registerTypeAlias<MutationTarget>(_$ormModelDefinitions[10]);
    registerTypeAlias<NamedConstructorModel>(_$ormModelDefinitions[11]);
    registerTypeAlias<NoFactory>(_$ormModelDefinitions[12]);
    registerTypeAlias<Photo>(_$ormModelDefinitions[13]);
    registerTypeAlias<Post>(_$ormModelDefinitions[14]);
    registerTypeAlias<PostTag>(_$ormModelDefinitions[15]);
    registerTypeAlias<SerialTest>(_$ormModelDefinitions[16]);
    registerTypeAlias<Setting>(_$ormModelDefinitions[17]);
    registerTypeAlias<Tag>(_$ormModelDefinitions[18]);
    registerTypeAlias<UniqueUser>(_$ormModelDefinitions[19]);
    registerTypeAlias<User>(_$ormModelDefinitions[20]);
    return this;
  }
}

/// Registers factory definitions for all models that have factory support.
/// Call this before using [Model.factory<T>()]to ensure definitions are available.
void registerOrmFactories() {
  ModelFactoryRegistry.registerIfAbsent<ActiveUser>(
    ActiveUserOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<Article>(
    ArticleOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<AttributeUser>(
    AttributeUserOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<Author>(AuthorOrmDefinition.definition);
  ModelFactoryRegistry.registerIfAbsent<Comment>(
    CommentOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<CustomSoftDelete>(
    CustomSoftDeleteOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<DerivedForFactory>(
    DerivedForFactoryOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<DriverOverrideEntry>(
    DriverOverrideEntryOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<Image>(ImageOrmDefinition.definition);
  ModelFactoryRegistry.registerIfAbsent<MutationTarget>(
    MutationTargetOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<NamedConstructorModel>(
    NamedConstructorModelOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<Photo>(PhotoOrmDefinition.definition);
  ModelFactoryRegistry.registerIfAbsent<Post>(PostOrmDefinition.definition);
  ModelFactoryRegistry.registerIfAbsent<PostTag>(
    PostTagOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<SerialTest>(
    SerialTestOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<Setting>(
    SettingOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<Tag>(TagOrmDefinition.definition);
  ModelFactoryRegistry.registerIfAbsent<UniqueUser>(
    UniqueUserOrmDefinition.definition,
  );
  ModelFactoryRegistry.registerIfAbsent<User>(UserOrmDefinition.definition);
}

/// Combined setup: registers both model registry and factories.
/// Returns a ModelRegistry with all generated models registered.
ModelRegistry buildOrmRegistryWithFactories() {
  registerOrmFactories();
  return buildOrmRegistry();
}
