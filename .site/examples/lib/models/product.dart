// #region field-annotations
import 'dart:convert';

import 'package:ormed/ormed.dart';

part 'product.orm.dart';

@OrmModel(table: 'products')
class Product extends Model<Product> {
  const Product({
    required this.id,
    required this.sku,
    this.active = false,
    this.metadata,
  });

  // Primary key with auto-increment
  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  // Custom column name in database
  @OrmField(column: 'product_sku')
  final String sku;

  // Default value in SQL
  @OrmField(defaultValueSql: '1')
  final bool active;

  // Custom codec for complex types
  @OrmField(codec: JsonMapCodec)
  final Map<String, Object?>? metadata;
}
// #endregion field-annotations

// #region custom-codec
class JsonMapCodec extends ValueCodec<Map<String, Object?>> {
  const JsonMapCodec();

  @override
  Object? encode(Map<String, Object?>? value) {
    if (value == null) return null;
    return jsonEncode(value);
  }

  @override
  Map<String, Object?>? decode(Object? value) {
    if (value == null) return null;
    if (value is Map<String, Object?>) return value;
    if (value is Map) {
      return value.map((key, dynamic entry) => MapEntry(key.toString(), entry));
    }
    return jsonDecode(value as String) as Map<String, Object?>;
  }
}

// #endregion custom-codec
