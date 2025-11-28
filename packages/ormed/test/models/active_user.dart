library;

import 'package:ormed/ormed.dart';

part 'active_user.orm.dart';

@OrmModel(table: 'active_users', connection: 'analytics', softDeletes: true)
class ActiveUser extends Model<ActiveUser> with SoftDeletes {
  ActiveUser({
    this.id,
    required this.email,
    this.name,
    this.settings = const <String, Object?>{},
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  int? id;

  String email;

  String? name;

  @OrmField(columnType: 'json')
  Map<String, Object?> settings;
}
