import 'package:ormed/migrations.dart';

/// Generates MySQL-compatible SQL for schema mutations.
class MySqlSchemaDialect extends SchemaDialect {
  const MySqlSchemaDialect({this.isMariaDb = false});

  final bool isMariaDb;

  @override
  String get driverName => isMariaDb ? 'mariadb' : 'mysql';

  @override
  List<SchemaStatement> compileMutation(SchemaMutation mutation) {
    switch (mutation.operation) {
      case SchemaMutationOperation.createTable:
        return _compileCreateTable(mutation.blueprint!);
      case SchemaMutationOperation.alterTable:
        return _compileAlterTable(mutation.blueprint!);
      case SchemaMutationOperation.dropTable:
        return [SchemaStatement(_dropTableSql(mutation.dropOptions!))];
      case SchemaMutationOperation.renameTable:
        return [SchemaStatement(_renameTableSql(mutation.rename!))];
      case SchemaMutationOperation.rawSql:
        return [
          SchemaStatement(mutation.sql!, parameters: mutation.parameters),
        ];
      default:
        throw UnimplementedError(
          'Schema mutation operation ${mutation.operation} is not supported by MySqlSchemaDialect.',
        );
    }
  }

  List<SchemaStatement> _compileCreateTable(TableBlueprint blueprint) {
    final definitions = <String>[];
    for (final column in blueprint.columns) {
      if (column.kind == ColumnCommandKind.drop) continue;
      final definition = column.definition;
      if (definition == null) {
        throw StateError('Column ${column.name} is missing a definition.');
      }
      definitions.add(_columnDefinitionSql(definition));
    }

    final constraints = <String>[];
    for (final indexCommand in blueprint.indexes) {
      final definition = indexCommand.definition;
      if (definition == null) continue;
      if (definition.type == IndexType.primary) {
        final isAutoIncrement =
            definition.columns.length == 1 &&
            blueprint.columns.any(
              (c) =>
                  c.name == definition.columns.first &&
                  (c.definition?.autoIncrement ?? false),
            );
        if (!isAutoIncrement) {
          final columns = definition.columns.map(_quote).join(', ');
          constraints.add('PRIMARY KEY ($columns)');
        }
      }
    }

    for (final foreign in blueprint.foreignKeys) {
      final definition = foreign.definition;
      if (definition == null) continue;
      constraints.add(_foreignKeyConstraint(definition));
    }

    final buffer = StringBuffer('CREATE ');
    if (blueprint.temporary) buffer.write('TEMPORARY ');
    buffer
      ..write('TABLE ${_tableNameFromBlueprint(blueprint)} (\n')
      ..write(
        [...definitions, ...constraints].map((line) => '  $line').join(',\n'),
      )
      ..write('\n) ENGINE=InnoDB');

    final statements = <SchemaStatement>[SchemaStatement(buffer.toString())];

    for (final indexCommand in blueprint.indexes) {
      final definition = indexCommand.definition;
      if (definition == null || definition.type == IndexType.primary) continue;
      statements.add(
        // Pass blueprint for schema-aware index creation
        SchemaStatement(_createIndexSqlForBlueprint(blueprint, definition)),
      );
    }

    return statements;
  }

  List<SchemaStatement> _compileAlterTable(TableBlueprint blueprint) {
    final statements = <SchemaStatement>[];
    final table = _tableNameFromBlueprint(blueprint);

    for (final column in blueprint.columns) {
      final definition = column.definition;
      switch (column.kind) {
        case ColumnCommandKind.add:
          if (definition == null) {
            throw StateError('Column ${column.name} is missing a definition.');
          }
          statements.add(
            SchemaStatement(
              'ALTER TABLE $table ADD COLUMN ${_columnDefinitionSql(definition)}',
            ),
          );
        case ColumnCommandKind.alter:
          if (definition == null) continue;
          statements.add(
            SchemaStatement(
              'ALTER TABLE $table MODIFY COLUMN ${_columnDefinitionSql(definition)}',
            ),
          );
        case ColumnCommandKind.drop:
          statements.add(
            SchemaStatement(
              'ALTER TABLE $table DROP COLUMN ${_quote(column.name)}',
            ),
          );
      }
    }

    for (final rename in blueprint.renamedColumns) {
      statements.add(
        SchemaStatement(
          'ALTER TABLE $table RENAME COLUMN ${_quote(rename.from)} TO ${_quote(rename.to)}',
        ),
      );
    }

    for (final indexCommand in blueprint.indexes) {
      final definition = indexCommand.definition;
      switch (indexCommand.kind) {
        case IndexCommandKind.add:
          if (definition == null) continue;
          if (definition.type == IndexType.primary) {
            final columns = definition.columns.map(_quote).join(', ');
            statements.add(
              SchemaStatement('ALTER TABLE $table ADD PRIMARY KEY ($columns)'),
            );
          } else {
            statements.add(
              SchemaStatement(_createIndexSqlForBlueprint(blueprint, definition)),
            );
          }
        case IndexCommandKind.drop:
          final keyword = indexCommand.name == 'PRIMARY'
              ? 'DROP PRIMARY KEY'
              : 'DROP INDEX ${_quote(indexCommand.name)}';
          final sql = indexCommand.name == 'PRIMARY'
              ? 'ALTER TABLE $table $keyword'
              : 'DROP INDEX ${_quote(indexCommand.name)} ON $table';
          statements.add(SchemaStatement(sql));
      }
    }

    for (final foreign in blueprint.foreignKeys) {
      final definition = foreign.definition;
      switch (foreign.kind) {
        case ForeignKeyCommandKind.add:
          if (definition == null) continue;
          statements.add(
            SchemaStatement(
              'ALTER TABLE $table ADD ${_foreignKeyConstraint(definition)}',
            ),
          );
        case ForeignKeyCommandKind.drop:
          statements.add(
            SchemaStatement(
              'ALTER TABLE $table DROP FOREIGN KEY ${_quote(foreign.name)}',
            ),
          );
      }
    }

    return statements;
  }

  String _dropTableSql(DropTableOptions options) {
    final buffer = StringBuffer('DROP TABLE ');
    if (options.ifExists) buffer.write('IF EXISTS ');
    buffer.write(_tableName(options.table));
    if (options.cascade) buffer.write(' CASCADE');
    return buffer.toString();
  }

  String _renameTableSql(RenameTableOptions options) {
    return 'RENAME TABLE ${_tableName(options.from)} TO ${_tableName(options.to)}';
  }

  String _createIndexSql(String table, IndexDefinition definition) {
    final keyword = switch (definition.type) {
      IndexType.unique => 'UNIQUE ',
      IndexType.fullText => 'FULLTEXT ',
      IndexType.spatial => 'SPATIAL ',
      _ => '',
    };
    final columns = definition.raw
        ? definition.columns.join(', ')
        : definition.columns.map(_quote).join(', ');
    final name = definition.type == IndexType.primary
        ? 'PRIMARY'
        : _quote(definition.name);
    if (definition.type == IndexType.primary) {
      return 'ALTER TABLE ${_tableName(table)} ADD PRIMARY KEY ($columns)';
    }
    return 'CREATE ${keyword}INDEX $name ON ${_tableName(table)} ($columns)';
  }

  String _createIndexSqlForBlueprint(TableBlueprint blueprint, IndexDefinition definition) {
    final keyword = switch (definition.type) {
      IndexType.unique => 'UNIQUE ',
      IndexType.fullText => 'FULLTEXT ',
      IndexType.spatial => 'SPATIAL ',
      _ => '',
    };
    final columns = definition.raw
        ? definition.columns.join(', ')
        : definition.columns.map(_quote).join(', ');
    final name = definition.type == IndexType.primary
        ? 'PRIMARY'
        : _quote(definition.name);
    final tableName = _tableNameFromBlueprint(blueprint);
    if (definition.type == IndexType.primary) {
      return 'ALTER TABLE $tableName ADD PRIMARY KEY ($columns)';
    }
    return 'CREATE ${keyword}INDEX $name ON $tableName ($columns)';
  }

  String _columnDefinitionSql(ColumnDefinition definition) {
    final override = definition.overrideForDriver(driverName);
    final buffer = StringBuffer()
      ..write(
        '${_quote(definition.name)} ${_resolvedType(definition, override)}',
      );
    if (definition.unsigned) buffer.write(' UNSIGNED');
    if (!definition.nullable) buffer.write(' NOT NULL');
    if (definition.unique) buffer.write(' UNIQUE');
    if (definition.autoIncrement) buffer.write(' AUTO_INCREMENT');
    if (definition.primaryKey && definition.autoIncrement) {
      buffer.write(' PRIMARY KEY');
    }

    final defaultValue = override?.defaultValue ?? definition.defaultValue;
    if (defaultValue != null) {
      buffer.write(' DEFAULT ${_defaultExpression(defaultValue)}');
    }

    if (definition.useCurrentOnUpdate) {
      buffer.write(' ON UPDATE CURRENT_TIMESTAMP');
    }

    final charset = override?.charset ?? definition.charset;
    if (charset != null && charset.isNotEmpty) {
      buffer.write(' CHARACTER SET $charset');
    }

    final collation = override?.collation ?? definition.collation;
    if (collation != null && collation.isNotEmpty) {
      buffer.write(' COLLATE $collation');
    }

    if (definition.comment != null && definition.comment!.isNotEmpty) {
      buffer.write(" COMMENT '${definition.comment!.replaceAll("'", "''")}'");
    }

    if (definition.first) buffer.write(' FIRST');
    if (definition.afterColumn != null) {
      buffer.write(' AFTER ${_quote(definition.afterColumn!)}');
    }

    if (definition.invisible) buffer.write(' INVISIBLE');

    if (definition.virtualAs != null || definition.storedAs != null) {
      final expression = definition.virtualAs ?? definition.storedAs;
      final storage = definition.storedAs != null ? 'STORED' : 'VIRTUAL';
      final modifier = definition.always ? 'GENERATED ALWAYS' : 'GENERATED';
      buffer
        ..write(' $modifier AS (${expression!}) ')
        ..write(storage);
    } else if (definition.generatedAs != null) {
      buffer.write(' GENERATED ALWAYS AS (${definition.generatedAs}) VIRTUAL');
    }

    return buffer.toString();
  }

  String _foreignKeyConstraint(ForeignKeyDefinition definition) {
    final columns = definition.columns.map(_quote).join(', ');
    final referenced = definition.referencedColumns.map(_quote).join(', ');
    final buffer = StringBuffer('CONSTRAINT ${_quote(definition.name)} ')
      ..write('FOREIGN KEY ($columns) ')
      ..write(
        'REFERENCES ${_tableName(definition.referencedTable)} ($referenced)',
      );
    if (definition.onDelete != ReferenceAction.noAction) {
      buffer.write(' ON DELETE ${_referentialAction(definition.onDelete)}');
    }
    if (definition.onUpdate != ReferenceAction.noAction) {
      buffer.write(' ON UPDATE ${_referentialAction(definition.onUpdate)}');
    }
    return buffer.toString();
  }

  String _referentialAction(ReferenceAction action) {
    switch (action) {
      case ReferenceAction.cascade:
        return 'CASCADE';
      case ReferenceAction.setNull:
        return 'SET NULL';
      case ReferenceAction.restrict:
        return 'RESTRICT';
      case ReferenceAction.noAction:
        return 'NO ACTION';
    }
  }

  String _resolvedType(
    ColumnDefinition definition,
    ColumnDriverOverride? override,
  ) {
    if (override?.sqlType != null) {
      return override!.sqlType!;
    }
    final type = override?.type ?? definition.type;
    switch (type.name) {
      case ColumnTypeName.bigInteger:
        return 'BIGINT';
      case ColumnTypeName.binary:
        return 'LONGBLOB';
      case ColumnTypeName.boolean:
        return 'TINYINT(1)';
      case ColumnTypeName.date:
        return 'DATE';
      case ColumnTypeName.time:
        return 'TIME(6)';
      case ColumnTypeName.dateTime:
        return type.timezoneAware ? 'TIMESTAMP(6)' : 'DATETIME(6)';
      case ColumnTypeName.decimal:
        final precision = type.precision ?? 10;
        final scale = type.scale ?? 0;
        return 'DECIMAL($precision, $scale)';
      case ColumnTypeName.doublePrecision:
        return 'DOUBLE';
      case ColumnTypeName.float:
        return 'FLOAT';
      case ColumnTypeName.integer:
        return 'INT';
      case ColumnTypeName.mediumInteger:
        return 'MEDIUMINT';
      case ColumnTypeName.smallInteger:
        return 'SMALLINT';
      case ColumnTypeName.tinyInteger:
        return 'TINYINT';
      case ColumnTypeName.json:
      case ColumnTypeName.jsonb:
        return 'JSON';
      case ColumnTypeName.longText:
        return 'LONGTEXT';
      case ColumnTypeName.text:
        return 'TEXT';
      case ColumnTypeName.string:
        final length = type.length ?? 255;
        return 'VARCHAR($length)';
      case ColumnTypeName.enumType:
        final values = definition.allowedValues ?? const [];
        if (values.isEmpty) {
          throw StateError('ENUM columns require allowed values.');
        }
        final quoted = values.map(_quoteString).join(', ');
        return 'ENUM($quoted)';
      case ColumnTypeName.setType:
        final values = definition.allowedValues ?? const [];
        if (values.isEmpty) {
          throw StateError('SET columns require allowed values.');
        }
        final quoted = values.map(_quoteString).join(', ');
        return 'SET($quoted)';
      case ColumnTypeName.uuid:
        return 'CHAR(36)';
      case ColumnTypeName.geometry:
        return 'GEOMETRY';
      case ColumnTypeName.geography:
        return 'GEOMETRY';
      case ColumnTypeName.vector:
        if (isMariaDb) {
          // MariaDB doesn't support the MySQL VECTOR type yet.
          return 'JSON';
        }
        final dimensions = type.length;
        if (dimensions != null && dimensions > 0) {
          return 'VECTOR($dimensions)';
        }
        return 'JSON';
      case ColumnTypeName.custom:
        return type.customName ?? 'TEXT';
    }
  }

  String _defaultExpression(ColumnDefault defaultValue) {
    if (defaultValue.useCurrentTimestamp) {
      return 'CURRENT_TIMESTAMP';
    }
    if (defaultValue.expression != null) {
      return defaultValue.expression!;
    }
    final value = defaultValue.value;
    if (value == null) return 'NULL';
    if (value is num) return value.toString();
    if (value is bool) return value ? '1' : '0';
    return _quoteString(value.toString());
  }

  String _quote(String identifier) {
    final escaped = identifier.replaceAll('`', '``');
    return '`$escaped`';
  }

  String _quoteString(String value) => "'${value.replaceAll("'", "''")}'";

  String _tableName(String table, {String? schema}) {
    if (schema != null && schema.isNotEmpty) {
      return '${_quote(schema)}.${_quote(table)}';
    }
    if (table.contains('.')) {
      return table.split('.').map(_quote).join('.');
    }
    return _quote(table);
  }
  
  String _tableNameFromBlueprint(TableBlueprint blueprint) {
    return _tableName(blueprint.table, schema: blueprint.schema);
  }
}
