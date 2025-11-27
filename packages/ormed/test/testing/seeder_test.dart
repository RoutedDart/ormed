import 'package:ormed/ormed.dart';
import '../query/models/author.dart';
import 'package:test/test.dart';

void main() {
  group('OrmSeeder', () {
    late ModelRegistry registry;
    late InMemoryQueryExecutor driver;
    late OrmConnection connection;
    late OrmSeeder seeder;

    setUp(() {
      registry = ModelRegistry()..register(AuthorOrmDefinition.definition);
      driver = InMemoryQueryExecutor();
      connection = OrmConnection(
        config: ConnectionConfig(name: 'testing'),
        driver: driver,
        registry: registry,
      );
      seeder = OrmSeeder(connection);
    });

    test('inserts models via repository', () async {
      await seeder.insert(const Author(id: 1, name: 'Alice', active: true));

      final models = await connection.query<Author>().get();
      expect(models.single.name, 'Alice');
    });

    test('truncate issues raw delete for in-memory driver', () async {
      final trackingDriver = _TrackingDriver();
      final trackedConnection = OrmConnection(
        config: ConnectionConfig(name: 'tracking'),
        driver: trackingDriver,
        registry: registry,
      );
      final trackedSeeder = OrmSeeder(trackedConnection);

      await trackedSeeder.truncate('users');

      expect(trackingDriver.lastSql, 'DELETE FROM "users"');
    });

    test('truncate restarts identity on postgres', () async {
      final trackingDriver = _TrackingDriver(name: 'postgres');
      final trackedConnection = OrmConnection(
        config: ConnectionConfig(name: 'tracking'),
        driver: trackingDriver,
        registry: registry,
      );
      final trackedSeeder = OrmSeeder(trackedConnection);

      await trackedSeeder.truncate('users');

      expect(trackingDriver.lastSql, 'TRUNCATE TABLE "users" RESTART IDENTITY');

      await trackedSeeder.truncate('users', cascade: true);

      expect(
        trackingDriver.lastSql,
        'TRUNCATE TABLE "users" RESTART IDENTITY CASCADE',
      );
    });

    test('truncate issues mysql syntax with quoting', () async {
      final trackingDriver = _TrackingDriver(name: 'mysql');
      final trackedConnection = OrmConnection(
        config: ConnectionConfig(name: 'tracking'),
        driver: trackingDriver,
        registry: registry,
      );
      final trackedSeeder = OrmSeeder(trackedConnection);

      await trackedSeeder.truncate('users');

      expect(trackingDriver.lastSql, 'TRUNCATE TABLE `users`');
    });

    test('truncate resets sqlite auto increment sequence', () async {
      final trackingDriver = _TrackingDriver(name: 'sqlite');
      final trackedConnection = OrmConnection(
        config: ConnectionConfig(name: 'tracking'),
        driver: trackingDriver,
        registry: registry,
      );
      final trackedSeeder = OrmSeeder(trackedConnection);

      await trackedSeeder.truncate('users');

      expect(trackingDriver.executedSql.length, 2);
      expect(trackingDriver.executedSql.first, 'DELETE FROM "users"');
      expect(
        trackingDriver.executedSql.last,
        'DELETE FROM sqlite_sequence WHERE name = ?',
      );
      expect(trackingDriver.executedParameters.last, ['users']);
    });

    test('truncate resets sqlite sequence for attached schemas', () async {
      final trackingDriver = _TrackingDriver(name: 'sqlite');
      final trackedConnection = OrmConnection(
        config: ConnectionConfig(name: 'tracking'),
        driver: trackingDriver,
        registry: registry,
      );
      final trackedSeeder = OrmSeeder(trackedConnection);

      await trackedSeeder.truncate('archive.users');

      expect(trackingDriver.executedSql.length, 2);
      expect(trackingDriver.executedSql.first, 'DELETE FROM "archive"."users"');
      expect(
        trackingDriver.executedSql.last,
        'DELETE FROM "archive".sqlite_sequence WHERE name = ?',
      );
      expect(trackingDriver.executedParameters.last, ['users']);
    });

    test('insert disables returning when driver lacks support', () async {
      final trackingDriver = _MutationTrackingDriver(supportsReturning: false);
      final trackedConnection = OrmConnection(
        config: ConnectionConfig(name: 'tracking'),
        driver: trackingDriver,
        registry: registry,
      );
      final trackedSeeder = OrmSeeder(trackedConnection);

      await trackedSeeder.insert(
        const Author(id: 5, name: 'Bob', active: true),
      );

      expect(trackingDriver.lastPlan, isNotNull);
      expect(trackingDriver.lastPlan!.returning, isFalse);
    });
  });
}

class _TrackingDriver extends InMemoryQueryExecutor {
  _TrackingDriver({this.name = 'in_memory'});

  final String name;
  String? lastSql;
  final List<String> executedSql = [];
  final List<List<Object?>> executedParameters = [];

  @override
  DriverMetadata get metadata => DriverMetadata(name: name);

  @override
  Future<void> executeRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    lastSql = sql;
    executedSql.add(sql);
    executedParameters.add(parameters);
    return super.executeRaw(sql, parameters);
  }
}

class _MutationTrackingDriver extends InMemoryQueryExecutor {
  _MutationTrackingDriver({required bool supportsReturning})
    : _metadata = DriverMetadata(
        name: 'tracking',
        supportsReturning: supportsReturning,
      );

  final DriverMetadata _metadata;
  MutationPlan? lastPlan;

  @override
  DriverMetadata get metadata => _metadata;

  @override
  Future<MutationResult> runMutation(MutationPlan plan) async {
    lastPlan = plan;
    return super.runMutation(plan);
  }
}
