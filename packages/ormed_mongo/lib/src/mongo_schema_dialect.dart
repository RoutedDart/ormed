import 'package:ormed/ormed.dart';

/// Dialect that emits Mongo-specific schema statements.
class MongoSchemaDialect implements SchemaDialect {
  const MongoSchemaDialect();

  @override
  String get driverName => 'mongo';

  @override
  List<SchemaStatement> compileMutation(SchemaMutation mutation) {
    switch (mutation.operation) {
      case SchemaMutationOperation.createTable:
        return _compileCreateTable(mutation.blueprint!);
      case SchemaMutationOperation.alterTable:
        return _compileAlterTable(mutation.blueprint!);
      case SchemaMutationOperation.createCollection:
      case SchemaMutationOperation.dropCollection:
      case SchemaMutationOperation.createIndex:
      case SchemaMutationOperation.dropIndex:
      case SchemaMutationOperation.modifyValidator:
        return [
          SchemaStatement(
            mutation.operation.name,
            payload: DocumentStatementPayload(
              command: mutation.operation.name,
              arguments: mutation.documentPayload ?? const {},
            ),
          ),
        ];
      default:
        return []; // SQL operations handled elsewhere.
    }
  }

  List<SchemaStatement> _compileCreateTable(TableBlueprint blueprint) {
    final statements = <SchemaStatement>[];
    final collectionName = blueprint.table;

    // Check for JSON Schema definition
    Map<String, Object?>? validator;
    Map<String, Object?>? options;

    final indexes = blueprint.indexes;
    final jsonSchemaIndex = indexes
        .where(
          (cmd) =>
              cmd.kind == IndexCommandKind.add &&
              cmd.definition!.name == '_json_schema_',
        )
        .firstOrNull;

    if (jsonSchemaIndex != null) {
      final driverOptions =
          jsonSchemaIndex.definition!.driverOptions['mongodb'];
      if (driverOptions != null) {
        if (driverOptions.containsKey('jsonSchema')) {
          validator = {'\$jsonSchema': driverOptions['jsonSchema']};
        }
        if (driverOptions.containsKey('validationLevel')) {
          options ??= {};
          options['validationLevel'] = driverOptions['validationLevel'];
        }
        if (driverOptions.containsKey('validationAction')) {
          options ??= {};
          options['validationAction'] = driverOptions['validationAction'];
        }
      }
    }

    // Create collection
    statements.add(
      SchemaStatement(
        'createCollection',
        payload: DocumentStatementPayload(
          command: 'createCollection',
          arguments: {
            'collection': collectionName,
            if (validator != null) 'validator': validator,
            if (options != null) 'options': options,
          },
        ),
      ),
    );

    // Create indexes
    for (final command in indexes) {
      if (command.kind == IndexCommandKind.add) {
        final definition = command.definition!;
        if (definition.name == '_json_schema_') continue;

        final driverOptions = definition.driverOptions['mongodb'];
        final type = driverOptions?['type'];

        if (type == 'search' || type == 'vectorSearch') {
          statements.add(
            SchemaStatement(
              'createSearchIndex',
              payload: DocumentStatementPayload(
                command: 'createSearchIndex',
                arguments: {
                  'collection': collectionName,
                  'name': definition.name,
                  'definition': driverOptions!['definition'],
                  'type': type,
                },
              ),
            ),
          );
        } else if (type == 'dropSearchIndex') {
          // Should not happen in createTable usually, but handle it just in case
          statements.add(
            SchemaStatement(
              'dropSearchIndex',
              payload: DocumentStatementPayload(
                command: 'dropSearchIndex',
                arguments: {
                  'collection': collectionName,
                  'name': definition.name,
                },
              ),
            ),
          );
        } else {
          // Standard index
          final keys = <String, Object?>{};
          for (final column in definition.columns) {
            keys[column] = 1; // Default to ascending
          }

          // Handle specific index types from driver options
          if (type == 'text') {
            keys.clear();
            for (final column in definition.columns) {
              keys[column] = 'text';
            }
          } else if (type == 'hashed') {
            keys.clear();
            for (final column in definition.columns) {
              keys[column] = 'hashed';
            }
          } else if (type == '2d' || type == '2dsphere') {
            keys.clear();
            for (final column in definition.columns) {
              keys[column] = type;
            }
          } else if (type == 'wildcard') {
            keys.clear();
            for (final column in definition.columns) {
              keys[column] =
                  1; // Wildcard uses "$**": 1 usually passed as column name
            }
          }

          final indexOptions = <String, Object?>{
            'name': definition.name,
            if (definition.type == IndexType.unique) 'unique': true,
          };

          if (driverOptions != null) {
            if (driverOptions['sparse'] == true) indexOptions['sparse'] = true;
            if (driverOptions['expireAfterSeconds'] != null) {
              indexOptions['expireAfterSeconds'] =
                  driverOptions['expireAfterSeconds'];
            }
            // Merge other options if needed
          }

          statements.add(
            SchemaStatement(
              'createIndex',
              payload: DocumentStatementPayload(
                command: 'createIndex',
                arguments: {
                  'collection': collectionName,
                  'keys': keys,
                  'name': definition.name,
                  'options': indexOptions,
                },
              ),
            ),
          );
        }
      }
    }

    return statements;
  }

  List<SchemaStatement> _compileAlterTable(TableBlueprint blueprint) {
    final statements = <SchemaStatement>[];
    final collectionName = blueprint.table;

    final indexes = blueprint.indexes;

    // Check for JSON Schema update
    final jsonSchemaIndex = indexes
        .where(
          (cmd) =>
              cmd.kind == IndexCommandKind.add &&
              cmd.definition!.name == '_json_schema_',
        )
        .firstOrNull;
    if (jsonSchemaIndex != null) {
      final driverOptions =
          jsonSchemaIndex.definition!.driverOptions['mongodb'];
      if (driverOptions != null && driverOptions.containsKey('jsonSchema')) {
        final validator = {'\$jsonSchema': driverOptions['jsonSchema']};
        final options = <String, Object?>{};
        if (driverOptions.containsKey('validationLevel')) {
          options['validationLevel'] = driverOptions['validationLevel'];
        }
        if (driverOptions.containsKey('validationAction')) {
          options['validationAction'] = driverOptions['validationAction'];
        }

        statements.add(
          SchemaStatement(
            'modifyValidator',
            payload: DocumentStatementPayload(
              command: 'modifyValidator',
              arguments: {
                'collection': collectionName,
                'validator': validator,
                if (options.isNotEmpty) 'options': options,
              },
            ),
          ),
        );
      }
    }

    for (final command in indexes) {
      if (command.kind == IndexCommandKind.add) {
        final definition = command.definition!;
        if (definition.name == '_json_schema_') continue;

        final driverOptions = definition.driverOptions['mongodb'];
        final type = driverOptions?['type'];

        if (type == 'search' || type == 'vectorSearch') {
          statements.add(
            SchemaStatement(
              'createSearchIndex',
              payload: DocumentStatementPayload(
                command: 'createSearchIndex',
                arguments: {
                  'collection': collectionName,
                  'name': definition.name,
                  'definition': driverOptions!['definition'],
                  'type': type,
                },
              ),
            ),
          );
        } else if (type == 'dropSearchIndex') {
          statements.add(
            SchemaStatement(
              'dropSearchIndex',
              payload: DocumentStatementPayload(
                command: 'dropSearchIndex',
                arguments: {
                  'collection': collectionName,
                  'name': definition.name,
                },
              ),
            ),
          );
        } else {
          // Standard index creation logic (duplicated from createTable, could be refactored)
          final keys = <String, Object?>{};
          for (final column in definition.columns) {
            keys[column] = 1;
          }

          if (type == 'text') {
            keys.clear();
            for (final column in definition.columns) {
              keys[column] = 'text';
            }
          } else if (type == 'hashed') {
            keys.clear();
            for (final column in definition.columns) {
              keys[column] = 'hashed';
            }
          } else if (type == '2d' || type == '2dsphere') {
            keys.clear();
            for (final column in definition.columns) {
              keys[column] = type;
            }
          } else if (type == 'wildcard') {
            keys.clear();
            for (final column in definition.columns) {
              keys[column] = 1;
            }
          }

          final indexOptions = <String, Object?>{
            'name': definition.name,
            if (definition.type == IndexType.unique) 'unique': true,
          };

          if (driverOptions != null) {
            if (driverOptions['sparse'] == true) indexOptions['sparse'] = true;
            if (driverOptions['expireAfterSeconds'] != null) {
              indexOptions['expireAfterSeconds'] =
                  driverOptions['expireAfterSeconds'];
            }
          }

          statements.add(
            SchemaStatement(
              'createIndex',
              payload: DocumentStatementPayload(
                command: 'createIndex',
                arguments: {
                  'collection': collectionName,
                  'keys': keys,
                  'name': definition.name,
                  'options': indexOptions,
                },
              ),
            ),
          );
        }
      } else if (command.kind == IndexCommandKind.drop) {
        statements.add(
          SchemaStatement(
            'dropIndex',
            payload: DocumentStatementPayload(
              command: 'dropIndex',
              arguments: {'collection': collectionName, 'name': command.name},
            ),
          ),
        );
      }
    }

    return statements;
  }
}
