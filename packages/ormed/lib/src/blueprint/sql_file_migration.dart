import 'dart:io';

import 'migration.dart';
import 'schema_builder.dart';

/// A [Migration] implementation backed by SQL files (`up.sql` and `down.sql`).
///
/// This migration reads the SQL files synchronously at plan-build time and
/// records the contents as raw schema mutations.
class SqlFileMigration extends Migration {
  SqlFileMigration({required this.upPath, required this.downPath, Uri? baseUri})
    : baseUri = baseUri ?? File.fromUri(Platform.script).parent.uri;

  /// Relative (or absolute) path to the `up.sql` file.
  final String upPath;

  /// Relative (or absolute) path to the `down.sql` file.
  final String downPath;

  /// Base URI used to resolve [upPath] and [downPath] when they are relative.
  ///
  /// Defaults to the directory of the current Dart script (`Platform.script`),
  /// which is appropriate when migrations are executed from a registry file.
  final Uri baseUri;

  @override
  void up(SchemaBuilder schema) {
    final sql = _readRequired(upPath, label: 'up.sql');
    if (sql.trim().isEmpty) return;
    schema.raw(sql);
  }

  @override
  void down(SchemaBuilder schema) {
    final sql = _readRequired(downPath, label: 'down.sql');
    if (sql.trim().isEmpty) return;
    schema.raw(sql);
  }

  String _readRequired(String path, {required String label}) {
    final resolved = _resolve(path);
    final file = File.fromUri(resolved);
    if (!file.existsSync()) {
      throw StateError('Missing $label for SQL migration at ${file.path}.');
    }
    return file.readAsStringSync();
  }

  Uri _resolve(String path) {
    final uri = Uri.parse(path);
    if (uri.isAbsolute) return uri;
    return baseUri.resolve(path);
  }
}
