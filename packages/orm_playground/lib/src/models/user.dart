import 'package:ormed/ormed.dart';

part 'user.orm.dart';

@OrmModel(table: 'users')
class User {
  const User({
    this.id,
    required this.email,
    required this.name,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  @OrmField(isPrimaryKey: true)
  final int? id;

  final String email;
  final String name;
  final bool active;

  @OrmField(columnName: 'created_at')
  final DateTime? createdAt;

  @OrmField(columnName: 'updated_at')
  final DateTime? updatedAt;
}
