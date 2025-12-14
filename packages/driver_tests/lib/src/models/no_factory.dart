library;

import 'package:ormed/ormed.dart';

part 'no_factory.orm.dart';

@OrmModel(table: 'active_users', softDeletes: true, connection: 'analytics')
class NoFactory extends Model<NoFactory> {
  const NoFactory({this.id});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int? id;
}
