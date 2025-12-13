import 'package:meta/meta.dart';

/// Declares a Dart class that should receive ORM metadata/codegen.
@immutable
class OrmModel {
  const OrmModel({
    required this.table,
    this.schema,
    this.generateCodec = true,
    this.hidden = const [],
    this.visible = const [],
    this.fillable = const [],
    this.guarded = const [],
    this.casts = const {},
    this.connection,
    this.softDeletes = false,
    this.softDeletesColumn = 'deleted_at',
    this.driverAnnotations = const [],
    this.primaryKey = const [],
    this.constructor,
  });

  /// Database table/collection name.
  final String table;

  /// Optional schema or namespace qualifier.
  final String? schema;

  /// Whether the generator should emit codec helpers for this model.
  final bool generateCodec;

  /// Columns that should be hidden when serializing.
  final List<String> hidden;

  /// Columns explicitly visible when a hidden list is defined.
  final List<String> visible;

  /// Columns that can be mass assigned.
  final List<String> fillable;

  /// Columns guarded from mass assignment.
  final List<String> guarded;

  /// Column cast hints (e.g., {'profile':'json'}).
  final Map<String, String> casts;

  /// Connection/driver name override.
  final String? connection;

  /// Whether the model tracks soft deletes.
  final bool softDeletes;

  /// Column used for soft delete timestamps.
  final String softDeletesColumn;

  /// Driver names that should take control of this model.
  final List<String> driverAnnotations;

  /// Column names that define the primary key.
  final List<String> primaryKey;

  /// Optional constructor name to use for code generation.
  /// If null, uses the default (unnamed) constructor.
  final String? constructor;
}

/// Additional metadata for a field/column.
@immutable
class OrmField {
  const OrmField({
    this.columnName,
    this.isPrimaryKey = false,
    this.isNullable,
    this.isUnique = false,
    this.isIndexed = false,
    this.autoIncrement = false,
    this.ignore = false,
    this.codec,
    this.columnType,
    this.defaultValueSql,
    this.driverOverrides = const {},
    this.fillable,
    this.guarded,
    this.hidden,
    this.visible,
    this.cast,
    this.insertable,
    this.updatable,
    this.defaultDartValue,
  });

  /// Explicit column name override.
  final String? columnName;

  /// Whether this column acts as the primary key.
  final bool isPrimaryKey;

  /// Force nullable metadata (defaults to Dart type nullability).
  final bool? isNullable;

  /// Marks the column as unique.
  final bool isUnique;

  /// Marks the column as indexed.
  final bool isIndexed;

  /// Whether the column auto-increments.
  final bool autoIncrement;

  /// Skip this field entirely.
  final bool ignore;

  /// Optional codec type used for serialization.
  final Type? codec;

  /// Database column type override (e.g., jsonb, uuid).
  final String? columnType;

  /// Default value SQL snippet.
  final String? defaultValueSql;

  /// Driver-specific overrides keyed by adapter metadata name (e.g., 'postgres').
  final Map<String, OrmDriverFieldOverride> driverOverrides;

  final bool? fillable;
  final bool? guarded;
  final bool? hidden;
  final bool? visible;
  final String? cast;

  /// Whether this field should be included in INSERT statements.
  ///
  /// Defaults to `true`. When `null`, the generator will infer:
  /// - `false` for auto-increment fields
  /// - `false` for database-generated columns
  /// - `true` otherwise
  final bool? insertable;

  /// Whether this field should be included in UPDATE statements.
  ///
  /// Defaults to `true`. When `null`, the generator will infer:
  /// - `false` for primary key fields (typically shouldn't change)
  /// - `false` for database-generated columns
  /// - `true` otherwise
  final bool? updatable;

  /// Default Dart value used when creating new model instances.
  ///
  /// For auto-increment int fields, this typically defaults to a sentinel
  /// value (e.g., -1 or 0) to indicate "not yet assigned".
  ///
  /// Example: `@OrmField(autoIncrement: true, defaultDartValue: -1)`
  final Object? defaultDartValue;
}

/// Describes driver-specific overrides for a model field.
@immutable
class OrmDriverFieldOverride {
  const OrmDriverFieldOverride({
    this.columnType,
    this.defaultValueSql,
    this.codec,
  });

  /// Driver-specific column type (e.g., jsonb when Postgres is active).
  final String? columnType;

  /// Driver-specific default expression.
  final String? defaultValueSql;

  /// Driver-specific codec type override.
  final Type? codec;
}

/// Relationship descriptor applied to fields referencing other models.
@immutable
class OrmRelation {
  const OrmRelation({
    required this.kind,
    required this.target,
    this.foreignKey,
    this.localKey,
    this.through,
    this.pivotForeignKey,
    this.pivotRelatedKey,
    this.morphType,
    this.morphClass,
  });

  final RelationKind kind;
  final Type target;
  final String? foreignKey;
  final String? localKey;
  final String? through;
  final String? pivotForeignKey;
  final String? pivotRelatedKey;
  final String? morphType;
  final String? morphClass;
}

/// Supported relationship kinds mirrored after Eloquent/GORM semantics.
enum RelationKind {
  hasOne,
  hasMany,
  belongsTo,
  manyToMany,
  morphOne,
  morphMany,
}

/// Marks a field as the soft-delete column for a model.
@immutable
class OrmSoftDelete {
  const OrmSoftDelete({this.columnName = 'deleted_at'});

  /// Column used to store soft delete timestamps.
  final String columnName;
}

/// Marker annotation used to flag the driver that should handle this model.
@immutable
class DriverModel {
  const DriverModel(this.driverName);

  final String driverName;
}

/// Marker annotation that enables factory support for a model.
///
/// Apply `@HasFactory()` to your model when you want the generator to emit
/// the factory helper class and register the definition with the factory
/// registry. This is an alternative to using the `ModelFactoryCapable` mixin.
@immutable
class HasFactory {
  const HasFactory();
}

/// Convenience constant for `@HasFactory()`.
const hasFactory = HasFactory();

