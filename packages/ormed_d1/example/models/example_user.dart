library;

import 'package:ormed/ormed.dart';

part 'example_user.orm.dart';

@OrmModel(table: 'example_users')
class ExampleUser extends Model<ExampleUser> with ModelFactoryCapable {
  const ExampleUser({
    required this.id,
    required this.email,
    this.name,
    this.active = false,
    this.createdAt,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String email;

  final String? name;

  final bool active;

  @OrmField(cast: 'datetime')
  final DateTime? createdAt;
}
