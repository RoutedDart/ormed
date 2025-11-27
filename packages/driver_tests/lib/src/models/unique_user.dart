import 'package:ormed/ormed.dart';

part 'unique_user.orm.dart';

@OrmModel(table: 'unique_users')
class UniqueUser extends Model<UniqueUser> with ModelFactoryCapable{
  const UniqueUser({
    required this.id,
    required this.email,
    required this.active,
  });

  @OrmField(isPrimaryKey: true)
  final int id;

  final String email;

  final bool active;
}
