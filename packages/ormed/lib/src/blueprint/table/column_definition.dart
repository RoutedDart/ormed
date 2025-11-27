import 'package:meta/meta.dart';

import 'column_default.dart';
import 'column_driver_override.dart';
import 'column_type.dart';

/// Declarative column metadata captured by the DSL.
@immutable
class ColumnDefinition {
  const ColumnDefinition({
    required this.name,
    required this.type,
    this.unsigned = false,
    this.nullable = false,
    this.unique = false,
    this.indexed = false,
    this.primaryKey = false,
    this.autoIncrement = false,
    this.defaultValue,
    this.comment,
    this.charset,
    this.collation,
    this.afterColumn,
    this.first = false,
    this.generatedAs,
    this.storedAs,
    this.virtualAs,
    this.useCurrentOnUpdate = false,
    this.invisible = false,
    this.always = false,
    this.allowedValues,
    this.driverOverrides = const {},
  });

  /// Column name as declared in the blueprint.
  final String name;

  /// Logical column type used during SQL generation.
  final ColumnType type;

  /// Whether the column should be unsigned.
  final bool unsigned;

  /// Whether the column accepts `NULL` values.
  final bool nullable;

  /// Whether the column enforces a unique constraint.
  final bool unique;

  /// Whether the column should be implicitly indexed.
  final bool indexed;

  /// Whether the column is part of the primary key.
  final bool primaryKey;

  /// Whether the column auto-increments its values.
  final bool autoIncrement;

  /// Default value provided when a column is inserted.
  final ColumnDefault? defaultValue;

  /// Comment attached to the column.
  final String? comment;

  /// Character set override for the column.
  final String? charset;

  /// Collation override for the column.
  final String? collation;

  /// Column name to place this column after when creating the table.
  final String? afterColumn;

  /// Whether this column is the first column in the table.
  final bool first;

  /// Generated expression for computed columns.
  final String? generatedAs;

  /// Storage expression for computed columns.
  final String? storedAs;

  /// Virtual expression for computed columns.
  final String? virtualAs;

  /// Whether to apply `CURRENT_TIMESTAMP` when the column updates.
  final bool useCurrentOnUpdate;

  /// Whether the column is invisible to queries by default.
  final bool invisible;

  /// Whether the column always evaluates to a value, even on updates.
  final bool always;

  /// Allowed values for enum-like columns.
  final List<String>? allowedValues;

  /// Driver-specific overrides keyed by driver name.
  final Map<String, ColumnDriverOverride> driverOverrides;

  ColumnDefinition copyWith({
    ColumnType? type,
    bool? unsigned,
    bool? nullable,
    bool? unique,
    bool? indexed,
    bool? primaryKey,
    bool? autoIncrement,
    ColumnDefault? defaultValue,
    bool clearDefault = false,
    String? comment,
    String? charset,
    String? collation,
    String? afterColumn,
    bool? first,
    String? generatedAs,
    String? storedAs,
    String? virtualAs,
    bool? useCurrentOnUpdate,
    bool? invisible,
    bool? always,
    List<String>? allowedValues,
    Map<String, ColumnDriverOverride>? driverOverrides,
  }) {
    return ColumnDefinition(
      name: name,
      type: type ?? this.type,
      unsigned: unsigned ?? this.unsigned,
      nullable: nullable ?? this.nullable,
      unique: unique ?? this.unique,
      indexed: indexed ?? this.indexed,
      primaryKey: primaryKey ?? this.primaryKey,
      autoIncrement: autoIncrement ?? this.autoIncrement,
      defaultValue: clearDefault ? null : (defaultValue ?? this.defaultValue),
      comment: comment ?? this.comment,
      charset: charset ?? this.charset,
      collation: collation ?? this.collation,
      afterColumn: afterColumn ?? this.afterColumn,
      first: first ?? this.first,
      generatedAs: generatedAs ?? this.generatedAs,
      storedAs: storedAs ?? this.storedAs,
      virtualAs: virtualAs ?? this.virtualAs,
      useCurrentOnUpdate: useCurrentOnUpdate ?? this.useCurrentOnUpdate,
      invisible: invisible ?? this.invisible,
      always: always ?? this.always,
      allowedValues: allowedValues ?? this.allowedValues,
      driverOverrides: driverOverrides ?? this.driverOverrides,
    );
  }

  Map<String, Object?> toJson() => {
    'name': name,
    'type': type.toJson(),
    if (unsigned) 'unsigned': true,
    if (nullable) 'nullable': true,
    if (unique) 'unique': true,
    if (indexed) 'indexed': true,
    if (primaryKey) 'primaryKey': true,
    if (autoIncrement) 'autoIncrement': true,
    if (defaultValue != null) 'default': defaultValue!.toJson(),
    if (comment != null) 'comment': comment,
    if (charset != null) 'charset': charset,
    if (collation != null) 'collation': collation,
    if (afterColumn != null) 'after': afterColumn,
    if (first) 'first': true,
    if (generatedAs != null) 'generatedAs': generatedAs,
    if (storedAs != null) 'storedAs': storedAs,
    if (virtualAs != null) 'virtualAs': virtualAs,
    if (useCurrentOnUpdate) 'useCurrentOnUpdate': true,
    if (invisible) 'invisible': true,
    if (always) 'always': true,
    if (allowedValues != null) 'allowedValues': allowedValues,
    if (driverOverrides.isNotEmpty)
      'driverOverrides': driverOverrides.map(
        (driver, override) => MapEntry(driver, override.toJson()),
      ),
  };

  factory ColumnDefinition.fromJson(Map<String, Object?> json) {
    final overridesJson =
        (json['driverOverrides'] as Map<String, Object?>?) ?? const {};
    return ColumnDefinition(
      name: json['name'] as String,
      type: ColumnType.fromJson(json['type'] as Map<String, Object?>),
      unsigned: json['unsigned'] as bool? ?? false,
      nullable: json['nullable'] as bool? ?? false,
      unique: json['unique'] as bool? ?? false,
      indexed: json['indexed'] as bool? ?? false,
      primaryKey: json['primaryKey'] as bool? ?? false,
      autoIncrement: json['autoIncrement'] as bool? ?? false,
      defaultValue: json['default'] == null
          ? null
          : ColumnDefault.fromJson(json['default'] as Map<String, Object?>),
      comment: json['comment'] as String?,
      charset: json['charset'] as String?,
      collation: json['collation'] as String?,
      afterColumn: json['after'] as String?,
      first: json['first'] as bool? ?? false,
      generatedAs: json['generatedAs'] as String?,
      storedAs: json['storedAs'] as String?,
      virtualAs: json['virtualAs'] as String?,
      useCurrentOnUpdate: json['useCurrentOnUpdate'] as bool? ?? false,
      invisible: json['invisible'] as bool? ?? false,
      always: json['always'] as bool? ?? false,
      allowedValues: (json['allowedValues'] as List?)?.cast<String>(),
      driverOverrides: Map.unmodifiable(
        overridesJson.map(
          (driver, raw) => MapEntry(
            driver,
            ColumnDriverOverride.fromJson((raw as Map).cast<String, Object?>()),
          ),
        ),
      ),
    );
  }

  ColumnDriverOverride? overrideForDriver(String driver) =>
      driverOverrides[driver];
}
