/// HasOne test model for driver integration.
library;

import 'package:ormed/ormed.dart';

part 'user_profile.orm.dart';

@OrmModel(table: 'user_profiles')
class UserProfile extends Model<UserProfile> with ModelFactoryCapable {
  const UserProfile({
    required this.id,
    required this.userId,
    required this.bio,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  @OrmField(columnName: 'user_id')
  final int userId;

  final String bio;
}
