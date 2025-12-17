// Factory-capable model example
import 'package:ormed/ormed.dart';

part 'factory_user.orm.dart';

// #region factory-capable-model
@OrmModel(table: 'users')
class FactoryUser extends Model<FactoryUser> with ModelFactoryCapable {
  const FactoryUser({required this.id, required this.email, this.name});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String email;
  final String? name;
}
// #endregion factory-capable-model
