import 'package:meta/meta.dart';

/// Options controlling SQLite spatial indexes.
@immutable
class SqliteSpatialIndexOptions {
  const SqliteSpatialIndexOptions({
    this.boundingColumns,
    this.maintainSync = true,
  });

  final List<String>? boundingColumns;
  final bool maintainSync;

  bool get hasOptions =>
      (boundingColumns != null && boundingColumns!.isNotEmpty) || !maintainSync;

  Map<String, Object?> toJson() => {
    if (boundingColumns != null && boundingColumns!.isNotEmpty)
      'boundingColumns': boundingColumns,
    if (!maintainSync) 'maintainSync': false,
  };
}
