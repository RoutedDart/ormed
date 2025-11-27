import 'package:meta/meta.dart';

import 'enums.dart';

/// Declarative column type metadata.
@immutable
class ColumnType {
  const ColumnType(
    this.name, {
    this.length,
    this.precision,
    this.scale,
    this.customName,
    this.timezoneAware = false,
  });

  const ColumnType.string({int length = 255})
    : this(ColumnTypeName.string, length: length);

  const ColumnType.text() : this(ColumnTypeName.text);

  const ColumnType.longText() : this(ColumnTypeName.longText);

  const ColumnType.integer() : this(ColumnTypeName.integer);

  const ColumnType.smallInteger() : this(ColumnTypeName.smallInteger);

  const ColumnType.mediumInteger() : this(ColumnTypeName.mediumInteger);

  const ColumnType.tinyInteger() : this(ColumnTypeName.tinyInteger);

  const ColumnType.bigInteger() : this(ColumnTypeName.bigInteger);

  const ColumnType.boolean() : this(ColumnTypeName.boolean);

  const ColumnType.floatType() : this(ColumnTypeName.float);

  const ColumnType.doubleType() : this(ColumnTypeName.doublePrecision);

  const ColumnType.timestamp({bool timezoneAware = false})
    : this(ColumnTypeName.dateTime, timezoneAware: timezoneAware);

  const ColumnType.date({bool timezoneAware = false})
    : this(ColumnTypeName.date, timezoneAware: timezoneAware);

  const ColumnType.time({bool timezoneAware = false})
    : this(ColumnTypeName.time, timezoneAware: timezoneAware);

  const ColumnType.decimal({int precision = 10, int scale = 0})
    : this(ColumnTypeName.decimal, precision: precision, scale: scale);

  const ColumnType.json() : this(ColumnTypeName.json);

  const ColumnType.jsonb() : this(ColumnTypeName.jsonb);

  const ColumnType.enumType() : this(ColumnTypeName.enumType);

  const ColumnType.setType() : this(ColumnTypeName.setType);

  const ColumnType.uuid() : this(ColumnTypeName.uuid);

  const ColumnType.geometry() : this(ColumnTypeName.geometry);

  const ColumnType.geography() : this(ColumnTypeName.geography);

  const ColumnType.vector({int? dimensions})
    : this(ColumnTypeName.vector, length: dimensions);

  const ColumnType.binary() : this(ColumnTypeName.binary);

  const ColumnType.custom(String name)
    : this(ColumnTypeName.custom, customName: name);

  /// Logical type recognized by the DSL.
  final ColumnTypeName name;

  /// Character length qualifier for string/vector types.
  final int? length;

  /// Precision for numeric types.
  final int? precision;

  /// Scale for numeric types.
  final int? scale;

  /// Custom driver type name when [name] is [ColumnTypeName.custom].
  final String? customName;

  /// Whether the type stores timezone-aware timestamps.
  final bool timezoneAware;

  Map<String, Object?> toJson() => {
    'name': name.name,
    if (length != null) 'length': length,
    if (precision != null) 'precision': precision,
    if (scale != null) 'scale': scale,
    if (customName != null) 'customName': customName,
    if (timezoneAware) 'timezoneAware': timezoneAware,
  };

  factory ColumnType.fromJson(Map<String, Object?> json) {
    final typeName = ColumnTypeName.values.byName(json['name'] as String);
    return ColumnType(
      typeName,
      length: json['length'] as int?,
      precision: json['precision'] as int?,
      scale: json['scale'] as int?,
      customName: json['customName'] as String?,
      timezoneAware: json['timezoneAware'] as bool? ?? false,
    );
  }
}
