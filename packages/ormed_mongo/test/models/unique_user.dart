import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:ormed/ormed.dart';

part 'unique_user.orm.dart';

@OrmModel(table: 'unique_users')
class UniqueUser extends Model<UniqueUser> with ModelFactoryCapable {
  const UniqueUser({
    this.id,
    required this.email,
    required this.active,
  });

  @OrmField(isPrimaryKey: true, columnName: '_id')
  final ObjectId? id;

  final String email;

  final bool active;
}
