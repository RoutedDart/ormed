import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../blueprint/schema_driver.dart';
import '../blueprint/schema_plan.dart';
import '../blueprint/migration.dart';

/// Exports SQL text files derived from schema plan previews.
///
/// Exporting uses [SchemaDriver.describeSchemaPlan] and NEVER applies the plan.
class MigrationSqlExporter {
  MigrationSqlExporter(this._driver);

  final SchemaDriver _driver;

  /// Renders [plan] to a single SQL text payload using statement previews.
  ///
  /// Statements are separated by a blank line.
  String renderPlan(SchemaPlan plan) {
    final preview = _driver.describeSchemaPlan(plan);
    if (preview.statements.isEmpty) return '';

    final buffer = StringBuffer();
    for (final statement in preview.statements) {
      final sql = statement.sql.trim();
      if (sql.isEmpty) continue;
      if (statement.parameters.isNotEmpty) {
        buffer.writeln('-- parameters: ${_safeJson(statement.parameters)}');
      }
      buffer.writeln(sql);
      buffer.writeln();
    }
    return '${buffer.toString().trimRight()}\n';
  }

  /// Writes `up.sql` and `down.sql` for [descriptor] under [outputRoot].
  ///
  /// Layout: `<outputRoot>/<migration-id>/up.sql` and `down.sql`.
  Future<void> exportDescriptor(
    MigrationDescriptor descriptor, {
    required Directory outputRoot,
    SchemaPlan? upPlan,
    SchemaPlan? downPlan,
  }) async {
    final dir = Directory(p.join(outputRoot.path, descriptor.id.toString()));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final upFile = File(p.join(dir.path, 'up.sql'));
    final downFile = File(p.join(dir.path, 'down.sql'));

    final upText = renderPlan(upPlan ?? descriptor.up);
    final downText = renderPlan(downPlan ?? descriptor.down);

    upFile.writeAsStringSync(upText);
    downFile.writeAsStringSync(downText);
  }
}

String _safeJson(Object? value) {
  try {
    return jsonEncode(value);
  } catch (_) {
    return jsonEncode(value.toString());
  }
}
