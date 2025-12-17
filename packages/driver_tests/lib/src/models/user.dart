/// Test user model for driver integration.
library;

import 'dart:convert';

import 'package:ormed/ormed.dart';

import 'user_profile.dart';

part 'user.orm.dart';

@OrmModel(
  table: 'users',
  hidden: ['profile'],
  fillable: ['email'],
  guarded: ['id'],
  casts: {'createdAt': 'datetime'},
)
class User extends Model<User> with ModelFactoryCapable {
  const User({
    required this.id,
    required this.email,
    this.active = false,
    this.name,
    this.age,
    this.profile,
    this.metadata,
    this.createdAt,
  }) : userProfile = null;

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String email;

  @OrmField(defaultValueSql: '1')
  final bool active;

  final String? name;

  final int? age;

  final DateTime? createdAt;

  @OrmField(codec: JsonMapCodec)
  final Map<String, Object?>? profile;

  @OrmField(codec: JsonMapCodec)
  final Map<String, Object?>? metadata;

  @OrmField(ignore: true)
  @OrmRelation(
    kind: RelationKind.hasOne,
    target: UserProfile,
    foreignKey: 'user_id',
    localKey: 'id',
  )
  final UserProfile? userProfile;
}

class JsonMapCodec extends ValueCodec<Map<String, Object?>> {
  const JsonMapCodec();

  @override
  Object? encode(Map<String, Object?>? value) {
    if (value == null) return null;
    return jsonEncode(value);
  }

  @override
  Map<String, Object?>? decode(Object? value) {
    if (value == null) return null;
    // Handle both Map (from factory/app code) and String (from database)
    if (value is Map<String, Object?>) return value;
    if (value is Map) {
      return value.map((key, dynamic entry) => MapEntry(key.toString(), entry));
    }
    final decoded = jsonDecode(value as String) as Map<String, dynamic>;
    return decoded.map((key, dynamic entry) => MapEntry(key, entry));
  }
}
