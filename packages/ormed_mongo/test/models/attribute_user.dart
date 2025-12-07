import 'package:ormed/ormed.dart';

part 'attribute_user.orm.dart';

@OrmModel(
  table: 'attribute_users',
  hidden: ['secret'],
  visible: ['secret'],
  fillable: ['email', 'role', 'profile'],
  guarded: ['_id'],
  casts: {'profile': 'json'},
  driverAnnotations: ['core'],
)
class AttributeUser extends Model<AttributeUser> with ModelFactoryCapable {
  const AttributeUser({
    this.id,
    required this.email,
    required this.secret,
    this.role,
    this.profile,
  });

  @OrmField(isPrimaryKey: true, columnName: '_id')
  final ObjectId? id;

  final String email;

  @OrmField(hidden: true)
  final String secret;

  @OrmField(fillable: true)
  final String? role;

  @OrmField(cast: 'json')
  final Map<String, Object?>? profile;
}
