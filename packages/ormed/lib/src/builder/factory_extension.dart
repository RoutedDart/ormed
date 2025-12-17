String modelFactoryExtension(String className) {
  final buffer = StringBuffer();
  // Use base class name without doubling "Model" suffix for factory name
  final factoryName = className.endsWith('Model') ? '${className}Factory' : '';
  buffer.writeln('extension ${className}ModelHelpers on $className {');
  buffer.writeln('  // Factory');
  buffer.writeln(
    '  static ModelFactoryBuilder<$className> factory({GeneratorProvider? generatorProvider}) =>',
  );
  buffer.writeln(
    '      $factoryName.factory(generatorProvider: generatorProvider);',
  );
  buffer.writeln();
  buffer.writeln('  // Query builder');
  buffer.writeln('  /// Starts building a query for [$className].');
  buffer.writeln('  ///');
  buffer.writeln('  /// {@macro ormed.query}');
  buffer.writeln('  static Query<$className> query([String? connection]) =>');
  buffer.writeln('      $factoryName.query(connection);');
  buffer.writeln();
  buffer.writeln('  // CRUD operations');
  buffer.writeln(
    '  static Future<List<$className>> all([String? connection]) =>',
  );
  buffer.writeln('      $factoryName.all(connection);');
  buffer.writeln();
  buffer.writeln(
    '  static Future<$className?> find(Object id, [String? connection]) =>',
  );
  buffer.writeln('      $factoryName.find(id, connection);');
  buffer.writeln();
  buffer.writeln(
    '  static Future<$className> findOrFail(Object id, [String? connection]) =>',
  );
  buffer.writeln('      $factoryName.findOrFail(id, connection);');
  buffer.writeln();
  buffer.writeln(
    '  static Future<List<$className>> findMany(List<Object> ids, [String? connection]) =>',
  );
  buffer.writeln('      $factoryName.findMany(ids, connection);');
  buffer.writeln();
  buffer.writeln('  static Future<$className?> first([String? connection]) =>');
  buffer.writeln('      $factoryName.first(connection);');
  buffer.writeln();
  buffer.writeln(
    '  static Future<$className> firstOrFail([String? connection]) =>',
  );
  buffer.writeln('      $factoryName.firstOrFail(connection);');
  buffer.writeln();
  buffer.writeln(
    '  static Future<$className> create(Map<String, dynamic> attributes, [String? connection]) =>',
  );
  buffer.writeln('      $factoryName.create(attributes, connection);');
  buffer.writeln();
  buffer.writeln(
    '  static Future<List<$className>> createMany(List<Map<String, dynamic>> records, [String? connection]) =>',
  );
  buffer.writeln('      $factoryName.createMany(records, connection);');
  buffer.writeln();
  buffer.writeln(
    '  static Future<void> insert(List<Map<String, dynamic>> records, [String? connection]) =>',
  );
  buffer.writeln('      $factoryName.insert(records, connection);');
  buffer.writeln();
  buffer.writeln(
    '  static Future<int> destroy(List<Object> ids, [String? connection]) =>',
  );
  buffer.writeln('      $factoryName.destroy(ids, connection);');
  buffer.writeln();
  buffer.writeln('  static Future<int> count([String? connection]) =>');
  buffer.writeln('      $factoryName.count(connection);');
  buffer.writeln();
  buffer.writeln('  static Future<bool> exists([String? connection]) =>');
  buffer.writeln('      $factoryName.exists(connection);');
  buffer.writeln();
  buffer.writeln(
    '  static Query<$className> where(String column, dynamic value, [String? connection]) =>',
  );
  buffer.writeln('      $factoryName.where(column, value, connection);');
  buffer.writeln();
  buffer.writeln(
    '  static Query<$className> whereIn(String column, List<dynamic> values, [String? connection]) =>',
  );
  buffer.writeln('      $factoryName.whereIn(column, values, connection);');
  buffer.writeln();
  buffer.writeln(
    '  static Query<$className> orderBy(String column, {String direction = "asc", String? connection}) =>',
  );
  buffer.writeln(
    '      $factoryName.orderBy(column, direction: direction, connection: connection);',
  );
  buffer.writeln();
  buffer.writeln(
    '  static Query<$className> limit(int count, [String? connection]) =>',
  );
  buffer.writeln('      $factoryName.limit(count, connection);');
  buffer.writeln();
  buffer.writeln('  // Instance method');
  buffer.writeln('  Future<void> delete([String? connection]) async {');
  buffer.writeln(
    '    final connName = connection ?? $factoryName.definition.metadata.connection;',
  );
  buffer.writeln('    final conn = ConnectionManager.instance.connection(');
  buffer.writeln(
    '      connName ?? ConnectionManager.instance.defaultConnectionName ?? "default",',
  );
  buffer.writeln('    );');
  buffer.writeln('    final repo = conn.context.repository<$className>();');
  buffer.writeln(
    '    final primaryKeys = $factoryName.definition.fields.where((f) => f.isPrimaryKey).toList();',
  );
  buffer.writeln('    if (primaryKeys.isEmpty) {');
  buffer.writeln(
    '    throw StateError("Cannot delete model without primary key");',
  );
  buffer.writeln('    }');
  buffer.writeln('    final keyMap = <String, Object?>{');
  buffer.writeln('      for (final key in primaryKeys)');
  buffer.writeln('        key.columnName: $factoryName.toMap(this)[key.name],');
  buffer.writeln('    };');
  buffer.writeln('    await repo.deleteByKeys([keyMap]);');
  buffer.writeln('  }');
  buffer.writeln('}');
  buffer.writeln();
  return buffer.toString();
}
