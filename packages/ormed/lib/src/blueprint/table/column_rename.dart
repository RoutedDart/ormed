import 'package:meta/meta.dart';

/// Records the original and new names for a column rename.
@immutable
class ColumnRename {
  const ColumnRename({required this.from, required this.to});

  /// Original column name before the rename.
  final String from;

  /// New column name after the rename.
  final String to;

  Map<String, Object?> toJson() => {'from': from, 'to': to};

  factory ColumnRename.fromJson(Map<String, Object?> json) =>
      ColumnRename(from: json['from'] as String, to: json['to'] as String);
}
