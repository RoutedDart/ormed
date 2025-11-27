import '../src/connection/orm_connection.dart';
import '../src/driver/driver.dart';
import '../src/repository/repository.dart';

/// Convenience helper for inserting and truncating data during tests or demos.
class OrmSeeder {
  OrmSeeder(this.connection)
    : _driverSupportsReturning = connection.driver.metadata.supportsReturning;

  final OrmConnection connection;
  final bool _driverSupportsReturning;

  Repository<T> _repository<T>() => connection.repository<T>();

  Future<T> insert<T>(T model, {bool returning = true}) => _repository<T>()
      .insert(model, returning: returning && _driverSupportsReturning);

  Future<List<T>> insertMany<T>(List<T> models, {bool returning = true}) =>
      _repository<T>().insertMany(
        models,
        returning: returning && _driverSupportsReturning,
      );

  Future<void> truncate(String table, {bool cascade = false}) async {
    final driver = connection.driver;
    final qualified = _qualifyTable(table);
    final quoted = _quote(driver, qualified);
    final name = driver.metadata.name.toLowerCase();
    switch (name) {
      case 'postgres':
      case 'postgresql':
        final cascadeClause = cascade ? ' CASCADE' : '';
        await driver.executeRaw(
          'TRUNCATE TABLE $quoted RESTART IDENTITY$cascadeClause',
        );
        break;
      case 'mysql':
      case 'mariadb':
        await driver.executeRaw('TRUNCATE TABLE $quoted');
        break;
      case 'sqlite':
        final segments = _splitSchemaAndTable(qualified);
        await driver.executeRaw('DELETE FROM $quoted');
        final schemaPrefix = segments.schema == null
            ? ''
            : '${_quote(driver, segments.schema!)}.';
        final sequenceTable = '${schemaPrefix}sqlite_sequence';
        final sequenceName = segments.schema == null
            ? qualified
            : _tableWithPrefix(segments.table);
        await driver.executeRaw('DELETE FROM $sequenceTable WHERE name = ?', [
          sequenceName,
        ]);
        break;
      default:
        await driver.executeRaw('DELETE FROM $quoted');
        break;
    }
  }

  String _qualifyTable(String table) {
    if (table.contains('.')) return table;
    return _tableWithPrefix(table);
  }

  String _tableWithPrefix(String table) {
    final prefix = connection.tablePrefix;
    return prefix.isEmpty ? table : '$prefix$table';
  }
}

String _quote(DriverAdapter driver, String identifier) {
  final name = driver.metadata.name.toLowerCase();
  final quote = switch (name) {
    'mysql' || 'mariadb' => '`',
    _ => '"',
  };
  final segments = identifier.split('.');
  final quoted = segments
      .map((segment) {
        final trimmed = segment.trim();
        final escaped = trimmed.replaceAll(quote, '$quote$quote');
        return '$quote$escaped$quote';
      })
      .join('.');
  return quoted;
}

_QualifiedTableName _splitSchemaAndTable(String identifier) {
  final index = identifier.indexOf('.');
  if (index == -1) {
    return _QualifiedTableName(schema: null, table: identifier);
  }
  final schema = identifier.substring(0, index);
  final table = identifier.substring(index + 1);
  return _QualifiedTableName(schema: schema, table: table);
}

class _QualifiedTableName {
  const _QualifiedTableName({this.schema, required this.table});

  final String? schema;
  final String table;
}
