import 'package:ormed/ormed.dart';

/// Dialect that emits Mongo-specific schema statements.
class MongoSchemaDialect implements SchemaDialect {
  const MongoSchemaDialect();

  @override
  String get driverName => 'mongo';

  @override
  List<SchemaStatement> compileMutation(SchemaMutation mutation) {
    switch (mutation.operation) {
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
}
