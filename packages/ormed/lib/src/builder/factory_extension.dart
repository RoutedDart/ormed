String modelFactoryExtension(String className) {
  final buffer = StringBuffer();
  buffer.writeln('extension ${className}ModelHelpers on $className {');
  buffer.writeln('  // Factory');
  buffer.writeln(
    '  static ModelFactoryBuilder<$className> factory({GeneratorProvider? generatorProvider}) =>',
  );
  buffer.writeln(
    '      ${className}ModelFactory.factory(generatorProvider: generatorProvider);',
  );
  buffer.writeln();
  buffer.writeln('  // Query builder');
  buffer.writeln('  static Query<$className> query([String? connection]) =>');
  buffer.writeln('      ${className}ModelFactory.query(connection);');
  buffer.writeln();
  buffer.writeln('  // CRUD operations');
  buffer.writeln(
    '  static Future<List<$className>> all([String? connection]) =>',
  );
  buffer.writeln('      ${className}ModelFactory.all(connection);');
  buffer.writeln();
  buffer.writeln(
    '  static Future<$className?> find(Object id, [String? connection]) =>',
  );
  buffer.writeln('      ${className}ModelFactory.find(id, connection);');
  buffer.writeln();
  buffer.writeln(
    '  static Future<$className> findOrFail(Object id, [String? connection]) =>',
  );
  buffer.writeln('      ${className}ModelFactory.findOrFail(id, connection);');
  buffer.writeln();
  buffer.writeln(
    '  static Future<List<$className>> findMany(List<Object> ids, [String? connection]) =>',
  );
  buffer.writeln('      ${className}ModelFactory.findMany(ids, connection);');
  buffer.writeln();
  buffer.writeln('  static Future<$className?> first([String? connection]) =>');
  buffer.writeln('      ${className}ModelFactory.first(connection);');
  buffer.writeln();
  buffer.writeln(
    '  static Future<$className> firstOrFail([String? connection]) =>',
  );
  buffer.writeln('      ${className}ModelFactory.firstOrFail(connection);');
  buffer.writeln();
  buffer.writeln(
    '  static Future<$className> create(Map<String, dynamic> attributes, [String? connection]) =>',
  );
  buffer.writeln(
    '      ${className}ModelFactory.create(attributes, connection);',
  );
  buffer.writeln();
  buffer.writeln(
    '  static Future<List<$className>> createMany(List<Map<String, dynamic>> records, [String? connection]) =>',
  );
  buffer.writeln(
    '      ${className}ModelFactory.createMany(records, connection);',
  );
  buffer.writeln();
  buffer.writeln(
    '  static Future<void> insert(List<Map<String, dynamic>> records, [String? connection]) =>',
  );
  buffer.writeln('      ${className}ModelFactory.insert(records, connection);');
  buffer.writeln();
  buffer.writeln(
    '  static Future<int> destroy(List<Object> ids, [String? connection]) =>',
  );
  buffer.writeln('      ${className}ModelFactory.destroy(ids, connection);');
  buffer.writeln();
  buffer.writeln('  static Future<int> count([String? connection]) =>');
  buffer.writeln('      ${className}ModelFactory.count(connection);');
  buffer.writeln();
  buffer.writeln('  static Future<bool> exists([String? connection]) =>');
  buffer.writeln('      ${className}ModelFactory.exists(connection);');
  buffer.writeln();
  buffer.writeln(
    '  static Query<$className> where(String column, dynamic value, [String? connection]) =>',
  );
  buffer.writeln(
    '      ${className}ModelFactory.where(column, value, connection);',
  );
  buffer.writeln();
  buffer.writeln(
    '  static Query<$className> whereIn(String column, List<dynamic> values, [String? connection]) =>',
  );
  buffer.writeln(
    '      ${className}ModelFactory.whereIn(column, values, connection);',
  );
  buffer.writeln();
  buffer.writeln(
    '  static Query<$className> orderBy(String column, {String direction = "asc", String? connection}) =>',
  );
  buffer.writeln(
    '      ${className}ModelFactory.orderBy(column, direction: direction, connection: connection);',
  );
  buffer.writeln();
  buffer.writeln(
    '  static Query<$className> limit(int count, [String? connection]) =>',
  );
  buffer.writeln('      ${className}ModelFactory.limit(count, connection);');
  buffer.writeln();
  buffer.writeln('  // Instance method');
  buffer.writeln('  Future<void> delete([String? connection]) async {');
  buffer.writeln(
    '    final connName = connection ?? ${className}ModelFactory.definition.metadata.connection;',
  );
  buffer.writeln('    final conn = ConnectionManager.instance.connection(');
  buffer.writeln(
    '      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",',
  );
  buffer.writeln('    );');
  buffer.writeln('    final repo = conn.context.repository<$className>();');
  buffer.writeln(
    '    final primaryKeys = ${className}ModelFactory.definition.fields.where((f) => f.isPrimaryKey).toList();',
  );
  buffer.writeln('    if (primaryKeys.isEmpty) {');
  buffer.writeln(
    '    throw StateError("Cannot delete model without primary key");',
  );
  buffer.writeln('    }');
  buffer.writeln('    final keyMap = <String, Object?>{');
  buffer.writeln('      for (final key in primaryKeys)');
  buffer.writeln(
    '        key.columnName: ${className}ModelFactory.toMap(this)[key.name],',
  );
  buffer.writeln('    };');
  buffer.writeln('    await repo.deleteByKeys([keyMap]);');
  buffer.writeln('  }');
  buffer.writeln('}');
  buffer.writeln();
  return buffer.toString();
}
