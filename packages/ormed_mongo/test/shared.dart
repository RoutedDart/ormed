import 'dart:async';
import 'dart:io';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_mongo/ormed_mongo.dart';

final _mongoUrl =
    Platform.environment['MONGO_URL'] ??
    'mongodb://root:example@localhost:27017/?authSource=admin';
final _databaseName = Platform.environment['MONGO_DATABASE'] ?? 'orm_test';
final _databaseUri = _buildDatabaseUri(_mongoUrl, _databaseName);
final _databaseConfig = DatabaseConfig(
  driver: 'mongo',
  options: {'url': _mongoUrl, 'database': _databaseName},
);

final productDefinition = AdHocModelDefinition(
  tableName: 'products',
  columns: const [AdHocColumn(name: '_id', isPrimaryKey: true)],
);

String _buildDatabaseUri(String baseUrl, String database) {
  final uri = Uri.parse(baseUrl);
  final builder = Uri(
    scheme: uri.scheme,
    userInfo: uri.userInfo,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: '/$database',
    query: uri.query.isEmpty ? null : uri.query,
  );
  return builder.toString();
}

Future<void> waitForMongoReady() async {
  const retries = 30;
  for (var attempt = 0; attempt < retries; attempt++) {
    try {
      final db = Db(_databaseUri);
      await db.open();
      await db.close();
      return;
    } catch (error) {
      stderr.writeln(
        'MongoDB readiness check failed (attempt ${attempt + 1}/$retries): '
        '$error',
      );
      await Future.delayed(const Duration(seconds: 1));
    }
  }
  throw StateError('MongoDB did not become ready after $retries attempts.');
}

MongoDriverAdapter createAdapter() =>
    MongoDriverAdapter.custom(config: _databaseConfig);

QueryContext createContext(MongoDriverAdapter adapter) =>
    QueryContext(registry: ModelRegistry(), driver: adapter);

Future<Db> openVerifier() async {
  final db = Db(_databaseUri);
  await db.open();
  return db;
}

Future<void> dropCollection(Db db, String name) async {
  try {
    await db.dropCollection(name);
  } on MongoDartError {
    // ignore missing namespace
  }
}

Future<void> clearDatabase() async {
  final db = Db(_databaseUri);
  await db.open();
  try {
    await db.modernDropDatabase();
  } finally {
    await db.close();
  }
}

ModelDefinition<Map<String, Object?>> buildAnnotatedDefinition(
  String table, {
  List<AdHocColumn> columns = const [],
}) {
  final fieldDefinitions = columns
      .map(
        (column) => FieldDefinition(
          name: column.name,
          columnName: column.columnName ?? column.name,
          dartType: column.dartType ?? 'Object?',
          resolvedType: column.resolvedType ?? column.dartType ?? 'Object?',
          isPrimaryKey: column.isPrimaryKey,
          isNullable: column.isNullable,
        ),
      )
      .toList(growable: false);
  return ModelDefinition<Map<String, Object?>>(
    modelName: 'Annotated<$table>',
    tableName: table,
    fields: fieldDefinitions,
    codec: const _TestMapCodec(),
    metadata: const ModelAttributesMetadata(
      driverAnnotations: [DriverModel('mongo')],
    ),
  );
}

class _TestMapCodec extends ModelCodec<Map<String, Object?>> {
  const _TestMapCodec();

  @override
  Map<String, Object?> encode(
    Map<String, Object?> model,
    ValueCodecRegistry registry,
  ) => Map<String, Object?>.from(model);

  @override
  Map<String, Object?> decode(
    Map<String, Object?> data,
    ValueCodecRegistry registry,
  ) => Map<String, Object?>.from(data);
}
