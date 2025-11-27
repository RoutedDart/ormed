/// Shared enums used by the table blueprint DSL.
library;

/// Determines whether a blueprint is creating a new table or mutating an existing one.
enum TableOperationKind {
  /// Create a new table.
  create,

  /// Alter an existing table.
  alter,
}

/// Describes whether a column command adds or alters a column.
enum ColumnMutation { add, alter }

/// Low-level column command kinds surfaced through [TableBlueprint].
enum ColumnCommandKind { add, alter, drop }

/// Index command kinds supported by the fluent DSL.
enum IndexCommandKind { add, drop }

/// Foreign-key command kinds supported by the fluent DSL.
enum ForeignKeyCommandKind { add, drop }

/// Logical index types that influence naming and SQL generation.
enum IndexType {
  /// Regular non-unique index.
  regular,

  /// Unique index.
  unique,

  /// Primary key backed index.
  primary,

  /// Full text search index.
  fullText,

  /// Spatial index.
  spatial,
}

/// Reference actions that control cascading behavior for foreign keys.
enum ReferenceAction { noAction, cascade, restrict, setNull }

/// Morph key variants supported by helper methods like [TableBlueprint.morphs].
enum MorphKeyType { numeric, uuid, ulid }

/// Logical column type names recognized by the DSL.
enum ColumnTypeName {
  /// Large integer.
  bigInteger,

  /// Raw binary blobs.
  binary,

  /// Boolean flag.
  boolean,

  /// Date without time component.
  date,

  /// Time without date component.
  time,

  /// Combined date and time value.
  dateTime,

  /// Arbitrary precision decimal.
  decimal,

  /// Double precision floating point.
  doublePrecision,

  /// Single precision floating point.
  float,

  /// Standard integer type.
  integer,

  /// Smaller integer range.
  smallInteger,

  /// Medium-size integer.
  mediumInteger,

  /// Tiny integer range.
  tinyInteger,

  /// JSON column without binary optimization.
  json,

  /// Binary-optimized JSON column.
  jsonb,

  /// Variable-length string.
  string,

  /// Text column for large strings.
  text,

  /// Extra-long text column.
  longText,

  /// Enum column backed by a set of strings.
  enumType,

  /// Set column storing multiple string values.
  setType,

  /// UUID column.
  uuid,

  /// Geometry data type.
  geometry,

  /// Geography data type.
  geography,

  /// Vector column for math/ML use cases.
  vector,

  /// Custom type represented by a driver-specific name.
  custom,
}
