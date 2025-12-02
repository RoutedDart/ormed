import 'dart:io';
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed/testing.dart';
import 'package:ormed_mysql/ormed_mysql.dart';
import 'package:test/test.dart';

Future<void> main() async {
  const config = DriverTestConfig(
    driverName: 'MySqlDriverAdapter',
    supportsReturning: false,
    supportsCaseInsensitiveLike: false,
    identifierQuote: '`',
    supportsQueryDeletes: true,
    supportsThreadCount: true,
    supportsAdvancedQueryBuilders: true,
    supportsSqlPreviews: true,
    supportsWhereRaw: true,
    supportsSelectRaw: true,
    supportsRightJoin: true,
    capabilities: {
      DriverCapability.joins,
      DriverCapability.insertUsing,
      DriverCapability.queryDeletes,
      DriverCapability.schemaIntrospection,
      DriverCapability.threadCount,
      DriverCapability.transactions,
      DriverCapability.adHocQueryUpdates,
    },
  );

  final url = Platform.environment['MYSQL_URL'] ?? 
      'mysql://root:secret@localhost:6605/orm_test';

  final codecRegistry = ValueCodecRegistry.standard();
  codecRegistry.registerCodec(key: 'PostgresPayloadCodec', codec: const PostgresPayloadCodec());
  codecRegistry.registerCodec(key: 'SqlitePayloadCodec', codec: const SqlitePayloadCodec());
  codecRegistry.registerCodec(key: 'MariaDbPayloadCodec', codec: const MariaDbPayloadCodec());
  codecRegistry.registerCodec(key: 'JsonMapCodec', codec: const JsonMapCodec());

  final driverAdapter = MySqlDriverAdapter.custom(
    config: DatabaseConfig(driver: 'mysql', options: {'url': url, 'ssl': true}),
    codecRegistry: codecRegistry,
  );

  final customCodecs = <String, ValueCodec<dynamic>>{
    'PostgresPayloadCodec': const PostgresPayloadCodec(),
    'SqlitePayloadCodec': const SqlitePayloadCodec(),
    'MariaDbPayloadCodec': const MariaDbPayloadCodec(),
    'JsonMapCodec': const JsonMapCodec(),
    'bool': const MySqlBoolCodec(),
    'bool?': const MySqlBoolCodec(),
  };

  final dataSource = DataSource(
    DataSourceOptions(
      driver: driverAdapter,
      entities: generatedOrmModelDefinitions,
      codecs: customCodecs,
      logging: true,
    ),
  );
  await dataSource.init();

  tearDownAll(() async {
    await dataSource.dispose();
  });

  runDriverQueryBuilderTests(dataSource: dataSource, config: config);
}
