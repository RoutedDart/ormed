// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'author.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$AuthorIdField = FieldDefinition(
  name: 'id',
  columnName: 'id',
  dartType: 'int',
  resolvedType: 'int',
  isPrimaryKey: true,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$AuthorNameField = FieldDefinition(
  name: 'name',
  columnName: 'name',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$AuthorActiveField = FieldDefinition(
  name: 'active',
  columnName: 'active',
  dartType: 'bool',
  resolvedType: 'bool',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const RelationDefinition _$AuthorPostsRelation = RelationDefinition(
  name: 'posts',
  kind: RelationKind.hasMany,
  targetModel: 'Post',
  foreignKey: 'author_id',
  localKey: 'id',
);

final ModelDefinition<Author> _$AuthorModelDefinition = ModelDefinition(
  modelName: 'Author',
  tableName: 'authors',
  fields: const [_$AuthorIdField, _$AuthorNameField, _$AuthorActiveField],
  relations: const [_$AuthorPostsRelation],
  softDeleteColumn: 'deleted_at',
  metadata: ModelAttributesMetadata(
    hidden: const <String>[],
    visible: const <String>[],
    fillable: const <String>[],
    guarded: const <String>[],
    casts: const <String, String>{},
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  codec: _$AuthorModelCodec(),
);

extension AuthorOrmDefinition on Author {
  static ModelDefinition<Author> get definition => _$AuthorModelDefinition;
}

class _$AuthorModelCodec extends ModelCodec<Author> {
  const _$AuthorModelCodec();

  @override
  Map<String, Object?> encode(Author model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$AuthorIdField, model.id),
      'name': registry.encodeField(_$AuthorNameField, model.name),
      'active': registry.encodeField(_$AuthorActiveField, model.active),
    };
  }

  @override
  Author decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int authorIdValue =
        registry.decodeField<int>(_$AuthorIdField, data['id']) ??
        (throw StateError('Field id on Author cannot be null.'));
    final String authorNameValue =
        registry.decodeField<String>(_$AuthorNameField, data['name']) ??
        (throw StateError('Field name on Author cannot be null.'));
    final bool authorActiveValue =
        registry.decodeField<bool>(_$AuthorActiveField, data['active']) ??
        (throw StateError('Field active on Author cannot be null.'));
    final model = _$AuthorModel(
      id: authorIdValue,
      name: authorNameValue,
      active: authorActiveValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': authorIdValue,
      'name': authorNameValue,
      'active': authorActiveValue,
    });
    return model;
  }
}

class _$AuthorModel extends Author
    with ModelAttributes, ModelConnection, ModelRelations {
  _$AuthorModel({required int id, required String name, required bool active})
    : super.new(id: id, name: name, active: active) {
    _attachOrmRuntimeMetadata({'id': id, 'name': name, 'active': active});
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  @override
  String get name => getAttribute<String>('name') ?? super.name;

  @override
  bool get active => getAttribute<bool>('active') ?? super.active;

  @override
  List<Post> get posts {
    if (relationLoaded('posts')) {
      return getRelationList<Post>('posts');
    }
    return super.posts;
  }

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$AuthorModelDefinition);
  }
}
