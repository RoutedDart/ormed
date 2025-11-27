import 'dart:io';

/// Abstraction for drivers that can dump/load the schema via native tooling.
abstract class SchemaState {
  /// Whether the driver supports dumping the schema to disk.
  bool get canDump;

  /// Whether the driver supports loading a dumped schema.
  bool get canLoad;

  /// Writes the schema to [path].
  Future<void> dump(File path);

  /// Loads the schema from [path].
  Future<void> load(File path);
}
