// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'comment.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$CommentIdField = FieldDefinition(
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

const FieldDefinition _$CommentBodyField = FieldDefinition(
  name: 'body',
  columnName: 'body',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$CommentDeletedAtField = FieldDefinition(
  name: 'deletedAt',
  columnName: 'deleted_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<Comment> _$CommentModelDefinition = ModelDefinition(
  modelName: 'Comment',
  tableName: 'comments',
  fields: const [_$CommentIdField, _$CommentBodyField, _$CommentDeletedAtField],
  relations: const [],
  softDeleteColumn: 'deleted_at',
  metadata: ModelAttributesMetadata(
    hidden: const <String>[],
    visible: const <String>[],
    fillable: const <String>[],
    guarded: const <String>[],
    casts: const <String, String>{},
    softDeletes: true,
    softDeleteColumn: 'deleted_at',
  ),
  codec: _$CommentModelCodec(),
);

// ignore: unused_element
final _CommentModelDefinitionRegistration =
    ModelFactoryRegistry.register<Comment>(_$CommentModelDefinition);

extension CommentOrmDefinition on Comment {
  static ModelDefinition<Comment> get definition => _$CommentModelDefinition;
}

class CommentModelFactory {
  const CommentModelFactory._();

  static ModelDefinition<Comment> get definition =>
      CommentOrmDefinition.definition;

  static ModelCodec<Comment> get codec => definition.codec;

  static Comment fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Comment model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Comment> withConnection(QueryContext context) =>
      ModelFactoryConnection<Comment>(definition: definition, context: context);

  static ModelFactoryBuilder<Comment> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Comment>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

extension CommentModelFactoryExtension on Comment {
  static ModelFactoryBuilder<Comment> factory({
    GeneratorProvider? generatorProvider,
  }) => CommentModelFactory.factory(generatorProvider: generatorProvider);
}

class _$CommentModelCodec extends ModelCodec<Comment> {
  const _$CommentModelCodec();

  @override
  Map<String, Object?> encode(Comment model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$CommentIdField, model.id),
      'body': registry.encodeField(_$CommentBodyField, model.body),
      'deleted_at': registry.encodeField(
        _$CommentDeletedAtField,
        model.getAttribute<DateTime?>('deleted_at'),
      ),
    };
  }

  @override
  Comment decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int commentIdValue =
        registry.decodeField<int>(_$CommentIdField, data['id']) ??
        (throw StateError('Field id on Comment cannot be null.'));
    final String commentBodyValue =
        registry.decodeField<String>(_$CommentBodyField, data['body']) ??
        (throw StateError('Field body on Comment cannot be null.'));
    final DateTime? commentDeletedAtValue = registry.decodeField<DateTime?>(
      _$CommentDeletedAtField,
      data['deleted_at'],
    );
    final model = _$CommentModel(id: commentIdValue, body: commentBodyValue);
    model._attachOrmRuntimeMetadata({
      'id': commentIdValue,
      'body': commentBodyValue,
      'deleted_at': commentDeletedAtValue,
    });
    return model;
  }
}

class _$CommentModel extends Comment {
  _$CommentModel({required int id, required String body})
    : super.new(id: id, body: body) {
    _attachOrmRuntimeMetadata({'id': id, 'body': body});
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  set id(int value) => setAttribute('id', value);

  @override
  String get body => getAttribute<String>('body') ?? super.body;

  set body(String value) => setAttribute('body', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$CommentModelDefinition);
    attachSoftDeleteColumn('deleted_at');
  }
}

extension CommentAttributeSetters on Comment {
  set id(int value) => setAttribute('id', value);
  set body(String value) => setAttribute('body', value);
}
