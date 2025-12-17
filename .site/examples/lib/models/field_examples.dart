// Field definition examples for documentation
// ignore_for_file: unused_field

import 'package:ormed/ormed.dart';

part 'field_examples.orm.dart';

// #region primary-key-examples
@OrmModel(table: 'items')
class ItemWithIntPK extends Model<ItemWithIntPK> {
  const ItemWithIntPK({required this.id});

  @OrmField(isPrimaryKey: true)
  final int id;
}

@OrmModel(table: 'auto_items')
class ItemWithAutoIncrement extends Model<ItemWithAutoIncrement> {
  const ItemWithAutoIncrement({required this.id});

  // Auto-increment (default for integer PKs)
  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;
}

@OrmModel(table: 'uuid_items')
class ItemWithUuidPK extends Model<ItemWithUuidPK> {
  const ItemWithUuidPK({required this.id});

  // UUID primary key
  @OrmField(isPrimaryKey: true)
  final String id;
}
// #endregion primary-key-examples

// #region column-options
@OrmModel(table: 'contacts')
class Contact extends Model<Contact> {
  const Contact({
    required this.id,
    required this.email,
    this.active = true,
    this.name,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  // Custom column name
  @OrmField(columnName: 'user_email')
  final String email;

  // Default value in SQL
  @OrmField(defaultValueSql: '1')
  final bool active;

  // Nullable field
  final String? name; // Automatically nullable in DB
}

// #endregion column-options
