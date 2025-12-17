// #region basic-model
// #region intro-model
import 'package:ormed/ormed.dart';

part 'user.orm.dart';

@OrmModel(table: 'users')
class User extends Model<User> {
  const User({
    required this.id,
    required this.email,
    this.name,
    this.createdAt,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String email;
  final String? name;
  final DateTime? createdAt;
}

// #endregion intro-model
// #endregion basic-model
