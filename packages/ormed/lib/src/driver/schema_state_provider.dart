import '../connection/orm_connection.dart';
import 'schema_state.dart';

/// Optional interface drivers can implement to expose schema dump helpers.
abstract class SchemaStateProvider {
  /// Returns a [SchemaState] capable of dumping/loading the schema for the
  /// provided [ledgerTable], or `null` if the driver cannot produce dumps.
  SchemaState? createSchemaState({
    required OrmConnection connection,
    required String ledgerTable,
  });
}
