import 'package:ormed/ormed.dart';

part 'cli_user.orm.dart';

@OrmModel(table: 'users')
class CliUser {
  const CliUser({required this.id, required this.email, required this.active});

  @OrmField(isPrimaryKey: true)
  final int id;

  final String email;

  final bool active;
}
