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
      codec: _$ExampleUserModelCodec(),
    );

extension ExampleUserOrmDefinition on ExampleUser {
  static ModelDefinition<ExampleUser> get definition =>
      _$ExampleUserModelDefinition;
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
    return ExampleUser(
      id:
          registry.decodeField<int>(_$ExampleUserIdField, data['id']) ??
          (throw StateError('Field id on ExampleUser cannot be null.')),
      email:
          registry.decodeField<String>(
            _$ExampleUserEmailField,
            data['email'],
          ) ??
          (throw StateError('Field email on ExampleUser cannot be null.')),
    );
  }
}
