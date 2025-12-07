/// Script to convert driver_tests models to use ObjectId instead of int id.
import 'dart:io';

void main() async {
  final sourceDir = Directory('../driver_tests/lib/src/models');
  final targetDir = Directory('test/models');

  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }

  await for (final entity in sourceDir.list()) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.orm.dart')) continue;

    final content = await entity.readAsString();
    final fileName = entity.uri.pathSegments.last;

    // Skip if already converted
    final targetFile = File('${targetDir.path}/$fileName');

    // Convert int id to ObjectId _id
    var converted = content;

    // Add ObjectId import if there's an id field
    if (converted.contains('final int id;') ||
        converted.contains('final int? id;')) {
      // Add import after library declaration
      converted = converted.replaceFirst(
        RegExp(r'(library.*;?\s+)'),
        '\\nimport \'package:mongo_dart/mongo_dart.dart\' show ObjectId;\n',
      );

      // Convert id field declarations
      converted = converted.replaceAll(
        RegExp(
          r'@OrmField\(isPrimaryKey: true,\s*autoIncrement:\s*true\)\s+final int id;',
        ),
        '@OrmField(isPrimaryKey: true, columnName: \'_id\')\n  final ObjectId? id;',
      );

      converted = converted.replaceAll(
        RegExp(r'@OrmField\(isPrimaryKey: true\)\s+final int id;'),
        '@OrmField(isPrimaryKey: true, columnName: \'_id\')\n  final ObjectId? id;',
      );

      converted = converted.replaceAll(
        RegExp(r'final int id;'),
        '@OrmField(isPrimaryKey: true, columnName: \'_id\')\n  final ObjectId? id;',
      );

      // Make id optional in constructors
      converted = converted.replaceAll(
        RegExp(r'required this\.id,'),
        'this.id,',
      );

      // Update guarded fields
      converted = converted.replaceAll(
        RegExp(r"guarded:\s*\['id'\]"),
        "guarded: ['_id']",
      );
    }

    await targetFile.writeAsString(converted);
    print('Converted: $fileName');
  }

  print(
    '\nDone! Run: dart run build_runner build --delete-conflicting-outputs',
  );
}
