import 'package:ormed/migrations.dart';

import '../connection/connection.dart';
import '../driver/driver.dart';
import '../model/model_registry.dart';
import '../query/query.dart';

/// Generic SQL ledger that persists migrations inside a driver-managed table.
class SqlMigrationLedger implements MigrationLedger {
  SqlMigrationLedger(
    DriverAdapter driver, {
    String? tableName,
    String? tablePrefix,
  }) : this._(
         _applyTablePrefix(
           tableName ?? 'orm_migrations',
           tablePrefix,
         ),
         _DriverInvoker.direct(driver),
         tablePrefix,
       );

  SqlMigrationLedger.managed({
    required String connectionName,
    ConnectionManager? manager,
    ConnectionRole role = ConnectionRole.primary,
    String? tableName,
    String? tablePrefix,
  }) : this._(
         _applyTablePrefix(
           tableName ?? 'orm_migrations',
           tablePrefix,
         ),
         _DriverInvoker.managed(
           manager ?? ConnectionManager.defaultManager,
           connectionName,
           role,
         ),
         tablePrefix,
       );

  SqlMigrationLedger._(
    this.tableName,
    this._driverInvoker,
    this._tablePrefix,
  );

  final String tableName;
  final _DriverInvoker _driverInvoker;
  final String? _tablePrefix;
  static final ModelRegistry _ledgerRegistry = ModelRegistry()
    ..register(OrmMigrationRecordOrmDefinition.definition);

  Future<T> _withDriver<T>(Future<T> Function(DriverAdapter driver) action) =>
      _driverInvoker.invoke(action);

  QueryContext _contextForDriver(DriverAdapter driver) => QueryContext(
    registry: _ledgerRegistry,
    driver: driver,
    connectionTablePrefix: _tablePrefix,
  );

  @override
  Future<void> ensureInitialized() => _withDriver((driver) async {
    final SchemaDriver? schemaDriver = driver is SchemaDriver
        ? driver as SchemaDriver
        : null;
    if (schemaDriver != null) {
      await _ensureWithSchemaDriver(schemaDriver);
      return;
    }
    await _ensureWithRawSql(driver);
  });

  Future<void> _ensureWithSchemaDriver(SchemaDriver schemaDriver) async {
    final inspector = SchemaInspector(schemaDriver);
    final exists = await inspector.hasTable(tableName);
    if (exists) return;

    final migration = _LedgerTableMigration(tableName);
    final plan = migration.plan(MigrationDirection.up);
    try {
      await schemaDriver.applySchemaPlan(plan);
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (!message.contains('already exists')) {
        rethrow;
      }
      // Ignore duplicate table creation races when parallel setups share the driver.
    }
  }

  Future<void> _ensureWithRawSql(DriverAdapter driver) {
    final table = _quoteIdentifier(driver, tableName);
    final id = _quoteIdentifier(driver, 'id');
    final checksum = _quoteIdentifier(driver, 'checksum');
    final appliedAt = _quoteIdentifier(driver, 'applied_at');
    final batch = _quoteIdentifier(driver, 'batch');
    final sql =
        'CREATE TABLE IF NOT EXISTS $table ('
        '$id TEXT PRIMARY KEY,'
        '$checksum TEXT NOT NULL,'
        '$appliedAt TEXT NOT NULL'
        ',$batch INTEGER NOT NULL'
        ')';
    return driver.executeRaw(sql);
  }

  @override
  Future<List<AppliedMigrationRecord>> readApplied() async =>
      _withDriver((driver) async {
        final context = _contextForDriver(driver);
        final records = await context
            .query<$OrmMigrationRecord>()
            .orderBy('appliedAt')
            .get();
        return records
            .map(
              (record) => AppliedMigrationRecord(
                id: MigrationId.parse(record.id),
                checksum: record.checksum,
                appliedAt: record.appliedAt.toUtc(),
                batch: record.batch,
              ),
            )
            .toList(growable: false);
      });

  @override
  Future<void> logApplied(
    MigrationDescriptor descriptor,
    DateTime appliedAt, {
    required int batch,
  }) => _withDriver((driver) async {
    final context = _contextForDriver(driver);
    final repository = context.repository<$OrmMigrationRecord>();
    await repository.insert(
      $OrmMigrationRecord(
        id: descriptor.id.toString(),
        checksum: descriptor.checksum,
        appliedAt: appliedAt.toUtc(),
        batch: batch,
      ),
    );
  });

  @override
  Future<int> nextBatchNumber() => _withDriver((driver) async {
    final context = _contextForDriver(driver);

    // Find the max batch number by processing records in chunks
    var maxBatch = 0;
    await context.query<$OrmMigrationRecord>().chunk(50, (rows) {
      for (final row in rows) {
        if (row.model.batch > maxBatch) {
          maxBatch = row.model.batch;
        }
      }
      return true; // Continue processing
    });

    return maxBatch + 1;
  });

  @override
  Future<void> remove(MigrationId id) => _withDriver((driver) async {
    final context = _contextForDriver(driver);
    final repository = context.repository<$OrmMigrationRecord>();
    await repository.deleteByKeys([
      {'id': id.toString()},
    ]);
  });
}

String _quoteIdentifier(DriverAdapter driver, String identifier) {
  final name = driver.metadata.name.toLowerCase();
  final quote = switch (name) {
    'mysql' || 'mariadb' => '`',
    _ => '"',
  };
  final escaped = identifier.replaceAll(quote, '$quote$quote');
  return '$quote$escaped$quote';
}

class _DriverInvoker {
  _DriverInvoker.direct(DriverAdapter driver)
    : _driver = driver,
      _manager = null,
      _connectionName = null,
      _role = ConnectionRole.primary;

  _DriverInvoker.managed(
    ConnectionManager manager,
    String connectionName,
    ConnectionRole role,
  ) : _manager = manager,
      _connectionName = connectionName,
      _role = role,
      _driver = null;

  final DriverAdapter? _driver;
  final ConnectionManager? _manager;
  final String? _connectionName;
  final ConnectionRole _role;

  Future<T> invoke<T>(Future<T> Function(DriverAdapter driver) action) {
    final driver = _driver;
    if (driver != null) {
      return action(driver);
    }
    final manager = _manager!;
    return manager.use(
      _connectionName!,
      (connection) => action(connection.driver),
      role: _role,
    );
  }
}

String _applyTablePrefix(String table, String? prefix) {
  if (prefix == null || prefix.isEmpty) {
    return table;
  }
  if (table.contains('.')) {
    return table;
  }
  if (table.startsWith(prefix)) {
    return table;
  }
  return '$prefix$table';
}

class _LedgerTableMigration extends Migration {
  const _LedgerTableMigration(this.table);

  final String table;

  @override
  Future<void> up(SchemaBuilder schema) async {
    schema.create(table, (table) {
      table.string('id').primaryKey();
      table.string('checksum', length: 64);
      table.timestamp('applied_at', timezoneAware: true);
      table.integer('batch');
    });
  }

  @override
  Future<void> down(SchemaBuilder schema) async {
    schema.drop(table, ifExists: true);
  }
}
