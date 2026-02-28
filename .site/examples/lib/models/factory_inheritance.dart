// Factory inheritance example
import 'package:ormed/ormed.dart';

part 'factory_inheritance.orm.dart';

// #region factory-inheritance
// Base class with factory support
@OrmModel(table: 'base_items')
class BaseItem extends Model<BaseItem> with ModelFactoryCapable {
  const BaseItem({required this.id, this.name});

  @OrmField(isPrimaryKey: true)
  final int id;
  final String? name;
}

// Derived class automatically gets factory support
@OrmModel(table: 'special_items')
class SpecialItem extends BaseItem {
  const SpecialItem({required super.id, super.name, this.tags});
  final List<String>? tags;
}

// #endregion factory-inheritance
