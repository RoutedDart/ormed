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
  resolvedType: 'int?',
  isPrimaryKey: true,
  isNullable: true,
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

const FieldDefinition _$AuthorCreatedAtField = FieldDefinition(
  name: 'createdAt',
  columnName: 'created_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

const FieldDefinition _$AuthorUpdatedAtField = FieldDefinition(
  name: 'updatedAt',
  columnName: 'updated_at',
  dartType: 'DateTime',
  resolvedType: 'DateTime?',
  isPrimaryKey: false,
  isNullable: true,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<Author> _$AuthorModelDefinition = ModelDefinition(
  modelName: 'Author',
  tableName: 'authors',
  fields: const [
    _$AuthorIdField,
    _$AuthorNameField,
    _$AuthorCreatedAtField,
    _$AuthorUpdatedAtField,
  ],
  relations: const [],
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

class Authors {
  const Authors._();

  static Query<Author> query([String? connection]) =>
      Model.query<Author>(connection: connection);

  static Future<Author?> find(Object id, {String? connection}) =>
      Model.find<Author>(id, connection: connection);

  static Future<Author> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<Author>(id, connection: connection);

  static Future<List<Author>> all({String? connection}) =>
      Model.all<Author>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<Author>(connection: connection);

  static Future<bool> exists({String? connection}) =>
      Model.exists<Author>(connection: connection);

  static Query<Author> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<Author>(column, operator, value, connection: connection);

  static Query<Author> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<Author>(column, values, connection: connection);

  static Query<Author> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<Author>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<Author> limit(int count, {String? connection}) =>
      Model.limit<Author>(count, connection: connection);
}

class AuthorModelFactory {
  const AuthorModelFactory._();

  static ModelDefinition<Author> get definition => _$AuthorModelDefinition;

  static ModelCodec<Author> get codec => definition.codec;

  static Author fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Author model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model, registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryBuilder<Author> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Author>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$AuthorModelCodec extends ModelCodec<Author> {
  const _$AuthorModelCodec();

  @override
  Map<String, Object?> encode(Author model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$AuthorIdField, model.id),
      'name': registry.encodeField(_$AuthorNameField, model.name),
      'created_at': registry.encodeField(
        _$AuthorCreatedAtField,
        model.createdAt,
      ),
      'updated_at': registry.encodeField(
        _$AuthorUpdatedAtField,
        model.updatedAt,
      ),
    };
  }

  @override
  Author decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int? authorIdValue = registry.decodeField<int?>(
      _$AuthorIdField,
      data['id'],
    );
    final String authorNameValue =
        registry.decodeField<String>(_$AuthorNameField, data['name']) ??
        (throw StateError('Field name on Author cannot be null.'));
    final DateTime? authorCreatedAtValue = registry.decodeField<DateTime?>(
      _$AuthorCreatedAtField,
      data['created_at'],
    );
    final DateTime? authorUpdatedAtValue = registry.decodeField<DateTime?>(
      _$AuthorUpdatedAtField,
      data['updated_at'],
    );
    final model = _$AuthorModel(
      id: authorIdValue,
      name: authorNameValue,
      createdAt: authorCreatedAtValue,
      updatedAt: authorUpdatedAtValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': authorIdValue,
      'name': authorNameValue,
      'created_at': authorCreatedAtValue,
      'updated_at': authorUpdatedAtValue,
    });
    return model;
  }
}

class _$AuthorModel extends Author {
  _$AuthorModel({
    int? id,
    required String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super.new(
         id: id,
         name: name,
         createdAt: createdAt,
         updatedAt: updatedAt,
       ) {
    _attachOrmRuntimeMetadata({
      'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    });
  }

  @override
  int? get id => getAttribute<int?>('id') ?? super.id;

  set id(int? value) => setAttribute('id', value);

  @override
  String get name => getAttribute<String>('name') ?? super.name;

  set name(String value) => setAttribute('name', value);

  @override
  DateTime? get createdAt =>
      getAttribute<DateTime?>('created_at') ?? super.createdAt;

  set createdAt(DateTime? value) => setAttribute('created_at', value);

  @override
  DateTime? get updatedAt =>
      getAttribute<DateTime?>('updated_at') ?? super.updatedAt;

  set updatedAt(DateTime? value) => setAttribute('updated_at', value);

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$AuthorModelDefinition);
  }
}

extension AuthorAttributeSetters on Author {
  set id(int? value) => setAttribute('id', value);
  set name(String value) => setAttribute('name', value);
  set createdAt(DateTime? value) => setAttribute('created_at', value);
  set updatedAt(DateTime? value) => setAttribute('updated_at', value);
}
