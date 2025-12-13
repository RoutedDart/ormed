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

final ModelDefinition<$Author> _$AuthorDefinition = ModelDefinition(
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
  codec: _$AuthorCodec(),
);

extension AuthorOrmDefinition on Author {
  static ModelDefinition<$Author> get definition => _$AuthorDefinition;
}

class Authors {
  const Authors._();

  static Query<$Author> query([String? connection]) =>
      Model.query<$Author>(connection: connection);

  static Future<$Author?> find(Object id, {String? connection}) =>
      Model.find<$Author>(id, connection: connection);

  static Future<$Author> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<$Author>(id, connection: connection);

  static Future<List<$Author>> all({String? connection}) =>
      Model.all<$Author>(connection: connection);

  static Future<int> count({String? connection}) =>
      Model.count<$Author>(connection: connection);

  static Future<bool> anyExist({String? connection}) =>
      Model.anyExist<$Author>(connection: connection);

  static Query<$Author> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<$Author>(column, operator, value, connection: connection);

  static Query<$Author> whereIn(
    String column,
    List<dynamic> values, {
    String? connection,
  }) => Model.whereIn<$Author>(column, values, connection: connection);

  static Query<$Author> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<$Author>(
    column,
    direction: direction,
    connection: connection,
  );

  static Query<$Author> limit(int count, {String? connection}) =>
      Model.limit<$Author>(count, connection: connection);

  static Repository<$Author> repo([String? connection]) =>
      Model.repository<$Author>(connection: connection);
}

class AuthorModelFactory {
  const AuthorModelFactory._();

  static ModelDefinition<$Author> get definition => _$AuthorDefinition;

  static ModelCodec<$Author> get codec => definition.codec;

  static Author fromMap(
    Map<String, Object?> data, {
    ValueCodecRegistry? registry,
  }) => definition.fromMap(data, registry: registry);

  static Map<String, Object?> toMap(
    Author model, {
    ValueCodecRegistry? registry,
  }) => definition.toMap(model.toTracked(), registry: registry);

  static void registerWith(ModelRegistry registry) =>
      registry.register(definition);

  static ModelFactoryConnection<Author> withConnection(QueryContext context) =>
      ModelFactoryConnection<Author>(definition: definition, context: context);

  static ModelFactoryBuilder<Author> factory({
    GeneratorProvider? generatorProvider,
  }) => ModelFactoryBuilder<Author>(
    definition: definition,
    generatorProvider: generatorProvider,
  );
}

class _$AuthorCodec extends ModelCodec<$Author> {
  const _$AuthorCodec();
  @override
  Map<String, Object?> encode($Author model, ValueCodecRegistry registry) {
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
  $Author decode(Map<String, Object?> data, ValueCodecRegistry registry) {
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
    final model = $Author(
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

/// Insert DTO for [Author].
///
/// Auto-increment/DB-generated fields are omitted by default.
class AuthorInsertDto implements InsertDto<$Author> {
  const AuthorInsertDto({this.id, this.name, this.createdAt, this.updatedAt});
  final int? id;
  final String? name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }
}

/// Update DTO for [Author].
///
/// All fields are optional; only provided entries are used in SET clauses.
class AuthorUpdateDto implements UpdateDto<$Author> {
  const AuthorUpdateDto({this.id, this.name, this.createdAt, this.updatedAt});
  final int? id;
  final String? name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }
}

/// Partial projection for [Author].
///
/// All fields are nullable; intended for subset SELECTs.
class AuthorPartial implements PartialEntity<$Author> {
  const AuthorPartial({this.id, this.name, this.createdAt, this.updatedAt});

  /// Creates a partial from a database row map.
  ///
  /// The [row] keys should be column names (snake_case).
  /// Missing columns will result in null field values.
  factory AuthorPartial.fromRow(Map<String, Object?> row) {
    return AuthorPartial(
      id: row['id'] as int?,
      name: row['name'] as String?,
      createdAt: row['created_at'] as DateTime?,
      updatedAt: row['updated_at'] as DateTime?,
    );
  }

  final int? id;
  final String? name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  $Author toEntity() {
    // Basic required-field check: non-nullable fields must be present.
    final String? nameValue = name;
    if (nameValue == null) throw StateError('Missing required field: name');
    return $Author(
      id: id,
      name: nameValue,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }
}

/// Generated tracked model class for [Author].
///
/// This class extends the user-defined [Author] model and adds
/// attribute tracking, change detection, and relationship management.
/// Instances of this class are returned by queries and repositories.
///
/// **Do not instantiate this class directly.** Use queries, repositories,
/// or model factories to create tracked model instances.
class $Author extends Author with ModelAttributes implements OrmEntity {
  $Author({
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

  /// Creates a tracked model instance from a user-defined model instance.
  factory $Author.fromModel(Author model) {
    return $Author(
      id: model.id,
      name: model.name,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
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
    attachModelDefinition(_$AuthorDefinition);
  }
}

extension AuthorOrmExtension on Author {
  /// The Type of the generated ORM-managed model class.
  /// Use this when you need to specify the tracked model type explicitly,
  /// for example in generic type parameters.
  static Type get trackedType => $Author;

  /// Converts this immutable model to a tracked ORM-managed model.
  /// The tracked model supports attribute tracking, change detection,
  /// and persistence operations like save() and touch().
  $Author toTracked() {
    return $Author.fromModel(this);
  }
}
