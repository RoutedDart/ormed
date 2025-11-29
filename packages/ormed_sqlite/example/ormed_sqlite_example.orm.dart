// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'ormed_sqlite_example.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$ExampleUserIdField = FieldDefinition(
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

const FieldDefinition _$ExampleUserEmailField = FieldDefinition(
  name: 'email',
  columnName: 'email',
  dartType: 'String',
  resolvedType: 'String',
  isPrimaryKey: false,
  isNullable: false,
  isUnique: false,
  isIndexed: false,
  autoIncrement: false,
);

final ModelDefinition<ExampleUser> _$ExampleUserModelDefinition =
    ModelDefinition(
      modelName: 'ExampleUser',
      tableName: 'users',
      fields: const [_$ExampleUserIdField, _$ExampleUserEmailField],
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
      codec: _$ExampleUserModelCodec(),
    );

extension ExampleUserOrmDefinition on ExampleUser {
  static ModelDefinition<ExampleUser> get definition =>
      _$ExampleUserModelDefinition;

  static Query<ExampleUser> query({String? connection}) =>
      Model.query<ExampleUser>(connection: connection);
}

class _$ExampleUserModelCodec extends ModelCodec<ExampleUser> {
  const _$ExampleUserModelCodec();

  @override
  Map<String, Object?> encode(ExampleUser model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$ExampleUserIdField, model.id),
      'email': registry.encodeField(_$ExampleUserEmailField, model.email),
    };
  }

  @override
  ExampleUser decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int exampleUserIdValue =
        registry.decodeField<int>(_$ExampleUserIdField, data['id']) ??
        (throw StateError('Field id on ExampleUser cannot be null.'));
    final String exampleUserEmailValue =
        registry.decodeField<String>(_$ExampleUserEmailField, data['email']) ??
        (throw StateError('Field email on ExampleUser cannot be null.'));
    final model = _$ExampleUserModel(
      id: exampleUserIdValue,
      email: exampleUserEmailValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': exampleUserIdValue,
      'email': exampleUserEmailValue,
    });
    return model;
  }
}

class _$ExampleUserModel extends ExampleUser
    with ModelAttributes, ModelConnection, ModelRelations {
  _$ExampleUserModel({required int id, required String email})
    : super.new(id: id, email: email) {
    _attachOrmRuntimeMetadata({'id': id, 'email': email});
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  @override
  String get email => getAttribute<String>('email') ?? super.email;

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$ExampleUserModelDefinition);
  }
}
