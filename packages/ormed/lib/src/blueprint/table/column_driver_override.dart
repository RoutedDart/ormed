import 'package:meta/meta.dart';

import 'column_default.dart';
import 'column_type.dart';

/// Driver-specific column hints that override the default definition.
@immutable
class ColumnDriverOverride {
  const ColumnDriverOverride({
    this.type,
    this.sqlType,
    this.defaultValue,
    this.collation,
    this.charset,
  }) : assert(
         type == null || sqlType == null,
         'Provide either a logical ColumnType or a raw SQL type, not both.',
       );

  /// Logical column type assigned to this driver override.
  final ColumnType? type;

  /// Raw SQL type string for the driver.
  final String? sqlType;

  /// Default value applied by the driver.
  final ColumnDefault? defaultValue;

  /// Collation override for the column.
  final String? collation;

  /// Character set override for the column.
  final String? charset;

  ColumnDriverOverride merge(ColumnDriverOverride other) {
    return ColumnDriverOverride(
      type: other.type ?? type,
      sqlType: other.sqlType ?? sqlType,
      defaultValue: other.defaultValue ?? defaultValue,
      collation: other.collation ?? collation,
      charset: other.charset ?? charset,
    );
  }

  Map<String, Object?> toJson() => {
    if (type != null) 'type': type!.toJson(),
    if (sqlType != null) 'sqlType': sqlType,
    if (defaultValue != null) 'default': defaultValue!.toJson(),
    if (collation != null) 'collation': collation,
    if (charset != null) 'charset': charset,
  };

  factory ColumnDriverOverride.fromJson(Map<String, Object?> json) {
    return ColumnDriverOverride(
      type: json['type'] == null
          ? null
          : ColumnType.fromJson(json['type'] as Map<String, Object?>),
      sqlType: json['sqlType'] as String?,
      defaultValue: json['default'] == null
          ? null
          : ColumnDefault.fromJson(json['default'] as Map<String, Object?>),
      collation: json['collation'] as String?,
      charset: json['charset'] as String?,
    );
  }
}
