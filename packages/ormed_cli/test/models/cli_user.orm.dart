// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'cli_user.dart';

// **************************************************************************
// OrmModelGenerator
// **************************************************************************

const FieldDefinition _$CliUserIdField = FieldDefinition(
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

const FieldDefinition _$CliUserEmailField = FieldDefinition(
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

const FieldDefinition _$CliUserActiveField = FieldDefinition(
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

final ModelDefinition<CliUser> _$CliUserModelDefinition = ModelDefinition(
  modelName: 'CliUser',
  tableName: 'users',
  fields: const [_$CliUserIdField, _$CliUserEmailField, _$CliUserActiveField],
  relations: const [],
  softDeleteColumn: 'deleted_at',
  metadata: const ModelAttributesMetadata(
    hidden: <String>[],
    visible: <String>[],
    fillable: <String>[],
    guarded: <String>[],
    casts: <String, String>{},
    softDeletes: false,
    softDeleteColumn: 'deleted_at',
  ),
  codec: const _$CliUserModelCodec(),
);

extension CliUserOrmDefinition on CliUser {
  static ModelDefinition<CliUser> get definition => _$CliUserModelDefinition;
}

class _$CliUserModelCodec extends ModelCodec<CliUser> {
  const _$CliUserModelCodec();

  @override
  Map<String, Object?> encode(CliUser model, ValueCodecRegistry registry) {
    return <String, Object?>{
      'id': registry.encodeField(_$CliUserIdField, model.id),
      'email': registry.encodeField(_$CliUserEmailField, model.email),
      'active': registry.encodeField(_$CliUserActiveField, model.active),
    };
  }

  @override
  CliUser decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final int cliUserIdValue =
        registry.decodeField<int>(_$CliUserIdField, data['id']) ??
        (throw StateError('Field id on CliUser cannot be null.'));
    final String cliUserEmailValue =
        registry.decodeField<String>(_$CliUserEmailField, data['email']) ??
        (throw StateError('Field email on CliUser cannot be null.'));
    final bool cliUserActiveValue =
        registry.decodeField<bool>(_$CliUserActiveField, data['active']) ??
        (throw StateError('Field active on CliUser cannot be null.'));
    final model = _$CliUserModel(
      id: cliUserIdValue,
      email: cliUserEmailValue,
      active: cliUserActiveValue,
    );
    model._attachOrmRuntimeMetadata({
      'id': cliUserIdValue,
      'email': cliUserEmailValue,
      'active': cliUserActiveValue,
    });
    return model;
  }
}

class _$CliUserModel extends CliUser with ModelAttributes, ModelConnection {
  _$CliUserModel({required int id, required String email, required bool active})
    : super(id: id, email: email, active: active) {
    _attachOrmRuntimeMetadata({'id': id, 'email': email, 'active': active});
  }

  @override
  int get id => getAttribute<int>('id') ?? super.id;

  @override
  String get email => getAttribute<String>('email') ?? super.email;

  @override
  bool get active => getAttribute<bool>('active') ?? super.active;

  void _attachOrmRuntimeMetadata(Map<String, Object?> values) {
    replaceAttributes(values);
    attachModelDefinition(_$CliUserModelDefinition);
  }
}
