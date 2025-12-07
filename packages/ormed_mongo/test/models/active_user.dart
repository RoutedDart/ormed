import 'package:ormed/ormed.dart';

part 'active_user.orm.dart';

@OrmModel(table: 'active_users', softDeletes: true, connection: 'analytics')
class ActiveUser extends Model<ActiveUser> with SoftDeletes {
  const ActiveUser({
    this.id,
    required this.email,
    this.name,
    this.settings = const <String, Object?>{},
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int? id;

  final String email;

  final String? name;

  @OrmField(columnType: 'json')
  final Map<String, Object?> settings;
}
