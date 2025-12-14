// Usage examples for generated code
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';
import 'dart:convert';

import 'models/user.dart';
import 'models/user.orm.dart';

// #region custom-codecs-field
@OrmModel(table: 'documents')
class Document extends Model<Document> {
  const Document({required this.id, this.metadata});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  @OrmField(codec: JsonMapCodec)
  final Map<String, Object?>? metadata;
}

class JsonMapCodec extends ValueCodec<Map<String, Object?>> {
  const JsonMapCodec();

  @override
  Map<String, Object?> decode(Object? value) {
    if (value == null) return {};
    if (value is String) return jsonDecode(value) as Map<String, Object?>;
    return value as Map<String, Object?>;
  }

  @override
  Object? encode(Map<String, Object?> value) => jsonEncode(value);
}
// #endregion custom-codecs-field

// #region tracked-model-usage
void trackedModelUsage() {
  // The generated class
  final user = $User(id: 1, email: 'john@example.com');

  // Modify and track changes
  user.setAttribute('name', 'John Doe');
  print(user.isDirty);  // true
  print(user.dirtyFields);  // ['name']
}
// #endregion tracked-model-usage

// #region definition-usage
void definitionUsage() {
  // Access the model definition
  final definition = UserOrmDefinition.definition;
  print(definition.tableName);  // 'users'
  print(definition.primaryKey.name);  // 'id'
}
// #endregion definition-usage

// #region partial-entity-usage
Future<void> partialEntityUsage(DataSource dataSource) async {
  final partial = await dataSource.query<$User>()
      .select(['id', 'email'])
      .firstPartial();

  print(partial?.id);     // Available
  print(partial?.email);  // Available
  // partial.name is not available (not selected)
}
// #endregion partial-entity-usage

// #region dto-usage
Future<void> dtoUsage(DataSource dataSource) async {
  // Insert DTO
  final insertDto = UserInsertDto(email: 'new@example.com');
  await dataSource.repo<$User>().insert(insertDto);

  // Update DTO
  final updateDto = UserUpdateDto(name: 'New Name');
  await dataSource.repo<$User>().update(updateDto, where: {'id': 1});
}
// #endregion dto-usage
