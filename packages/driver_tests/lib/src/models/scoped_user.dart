library;

import 'package:ormed/ormed.dart';

part 'scoped_user.orm.dart';

@OrmModel(table: 'scoped_users')
class ScopedUser extends Model<ScopedUser> {
  const ScopedUser({
    required this.id,
    required this.email,
    required this.active,
    this.name,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String email;

  final bool active;

  final String? name;

  @OrmScope(global: true)
  static Query<$ScopedUser> activeOnly(Query<$ScopedUser> query) =>
      query.whereEquals('active', true);

  @OrmScope()
  static Query<$ScopedUser> emailDomain(
    Query<$ScopedUser> query,
    String domain,
  ) =>
      query.whereLike('email', '%@$domain');

  @OrmScope()
  static Query<$ScopedUser> named(
    Query<$ScopedUser> query, {
    required String name,
  }) =>
      query.whereEquals('name', name);
}
