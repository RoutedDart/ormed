// #region model-with-options
import 'package:ormed/ormed.dart';

part 'admin.orm.dart';

@OrmModel(
  table: 'admins',
  hidden: ['password'], // Fields hidden from serialization
  fillable: ['email'], // Fields that can be mass-assigned
  guarded: ['id'], // Fields protected from mass-assignment
  casts: {'createdAt': 'datetime'},
)
class Admin extends Model<Admin> {
  const Admin({
    required this.id,
    required this.email,
    this.password,
    this.createdAt,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String email;
  final String? password;
  final DateTime? createdAt;
}

// #endregion model-with-options
