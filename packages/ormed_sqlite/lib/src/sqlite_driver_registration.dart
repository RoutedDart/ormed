import 'package:ormed/ormed.dart';

import 'sqlite_driver_registration_stub.dart'
    if (dart.library.io) 'sqlite_driver_registration_io.dart'
    as impl;

typedef SqliteConnectionRegistrar =
    OrmConnectionHandle Function({
      required String name,
      required DatabaseConfig database,
      required ModelRegistry registry,
      ConnectionConfig? connection,
      ConnectionManager? manager,
      bool singleton,
    });

void registerSqliteProjectDriver(SqliteConnectionRegistrar registrar) {
  impl.registerSqliteProjectDriver(registrar);
}
