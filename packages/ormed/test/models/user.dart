import 'dart:convert';

import 'package:ormed/ormed.dart';

part 'user.orm.dart';

@OrmModel(
  table: 'users',
  hidden: ['profile'],
  fillable: ['email'],
  guarded: ['id'],
  casts: {'createdAt': 'datetime'},
  connection: 'analytics',
)
class User {
  const User({
    required this.id,
    required this.email,
    this.profile,
    this.createdAt,
  });

  @OrmField(isPrimaryKey: true)
  final String id;

  final String email;

  @OrmField(codec: JsonMapCodec)
  final Map<String, Object?>? profile;

  final DateTime? createdAt;
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
    final decoded = jsonDecode(value as String) as Map<String, dynamic>;
    return decoded.map((key, dynamic entry) => MapEntry(key, entry));
  }
}
