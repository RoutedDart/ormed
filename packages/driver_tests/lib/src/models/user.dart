/// Test user model for driver integration.
library;

import 'package:ormed/ormed.dart';

part 'user.orm.dart';

@OrmModel(table: 'users')
class User extends Model<User> with ModelFactoryCapable {
  const User({required this.id, required this.email, required this.active});

  @OrmField(isPrimaryKey: true)
  final int id;

  final String email;

  final bool active;
}
