import 'package:meta/meta.dart';

import 'enums.dart';

/// Declarative index metadata.
@immutable
class IndexDefinition {
  const IndexDefinition({
    required this.name,
    required this.type,
    required this.columns,
    this.raw = false,
    this.driverOptions = const {},
  });

  /// Index name used for creation/dropping.
  final String name;

  /// Logical index type guiding SQL generation.
  final IndexType type;

  /// Columns captured by the index.
  final List<String> columns;

  /// Whether the index is defined using raw SQL.
  final bool raw;

  /// Driver-specific options applied when creating the index.
  final Map<String, Map<String, Object?>> driverOptions;

  Map<String, Object?> toJson() => {
    'name': name,
    'type': type.name,
    'columns': columns,
    if (raw) 'raw': true,
    if (driverOptions.isNotEmpty)
      'driverOptions': driverOptions.map(
        (driver, options) =>
            MapEntry(driver, Map<String, Object?>.from(options)),
      ),
  };

  factory IndexDefinition.fromJson(Map<String, Object?> json) =>
      IndexDefinition(
        name: json['name'] as String,
        type: IndexType.values.byName(json['type'] as String),
        columns: (json['columns'] as List).cast<String>(),
        raw: json['raw'] == true,
        driverOptions:
            (json['driverOptions'] as Map?)?.map(
              (key, value) => MapEntry(
                key as String,
                (value as Map).cast<String, Object?>(),
              ),
            ) ??
            const {},
      );

  /// Creates a copy with additional driver-specific options.
  IndexDefinition withDriverOptions(
    String driverName,
    Map<String, Object?> options,
  ) {
    final newDriverOptions = Map<String, Map<String, Object?>>.from(driverOptions);
    newDriverOptions[driverName] = {
      ...?newDriverOptions[driverName],
      ...options,
    };
    return IndexDefinition(
      name: name,
      type: type,
      columns: columns,
      raw: raw,
      driverOptions: newDriverOptions,
    );
  }
}
