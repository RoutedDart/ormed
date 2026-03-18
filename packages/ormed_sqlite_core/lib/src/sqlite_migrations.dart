import 'package:ormed/migrations.dart';

/// SQLite-specific schema helpers.
extension SqliteTableBlueprintExtensions on TableBlueprint {
  /// Adds a BLOB column (alias for [binary]).
  ColumnBuilder blob(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return binary(name, mutation: mutation);
  }

  /// Adds a REAL column (alias for [float]).
  ColumnBuilder real(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
    int? precision,
    int? scale,
  }) {
    return float(name, mutation: mutation, precision: precision, scale: scale);
  }

  /// Adds a NUMERIC column (alias for [decimal]).
  ColumnBuilder numeric(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
    int precision = 10,
    int scale = 0,
  }) {
    return decimal(
      name,
      mutation: mutation,
      precision: precision,
      scale: scale,
    );
  }
}
