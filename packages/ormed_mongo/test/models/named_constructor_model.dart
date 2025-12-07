import 'package:ormed/ormed.dart';

part 'named_constructor_model.orm.dart';

/// Test model that uses a named constructor for ORM generation.
/// This demonstrates the `constructor` parameter in @OrmModel annotation.
@OrmModel(
  table: 'named_constructor_models',
  constructor: 'fromDatabase', // Specify which constructor to use
)
class NamedConstructorModel extends Model<NamedConstructorModel> {
  // Default constructor - NOT used by the generator
  const NamedConstructorModel({
    this.id,
    required this.name,
    required this.value,
  });

  // Named constructor that the generator will use
  // This allows for different parameter ordering or naming
  const NamedConstructorModel.fromDatabase({
    this.id,
    required this.name,
    required this.value,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int? id;

  final String name;

  final int value;
}
