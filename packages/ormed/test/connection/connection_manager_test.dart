import 'package:driver_tests/orm_registry.g.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';
import 'package:driver_tests/driver_tests.dart';

void main() {
  ModelRegistry registry = buildOrmRegistry();

  registerOrmFactories();
  group('ConnectionManager', () {
    test('registers and resolves default connection', () {
      final manager = ConnectionManager();
      manager.register(
        'primary',
        ConnectionConfig(name: 'primary'),
        (config) => OrmConnection(
          config: config,
          driver: InMemoryQueryExecutor(),
          registry: registry,
        ),
      );

      final conn = manager.connection('primary');
      expect(conn.name, 'primary');
      expect(conn.role, ConnectionRole.primary);
      expect(identical(conn, manager.connection('primary')), isTrue);
    });

    test('supports role-specific resolution with fallback', () {
      final manager = ConnectionManager();
      manager
        ..register(
          'db',
          ConnectionConfig(name: 'db'),
          (config) => OrmConnection(
            config: config,
            driver: InMemoryQueryExecutor(),
            registry: registry,
          ),
        )
        ..register(
          'db',
          ConnectionConfig(name: 'db'),
          (config) => OrmConnection(
            config: config,
            driver: InMemoryQueryExecutor(),
            registry: registry,
          ),
          role: ConnectionRole.read,
        );

      final read = manager.connection('db', role: ConnectionRole.read);
      expect(read.role, ConnectionRole.read);

      final write = manager.connection('db', role: ConnectionRole.write);
      expect(write.role, ConnectionRole.primary);
    });

    test('use wraps transient connections and invokes release hooks', () async {
      final manager = ConnectionManager();
      var builds = 0;
      var releases = 0;
      manager.register(
        'temp',
        ConnectionConfig(name: 'temp'),
        (config) {
          builds++;
          return OrmConnection(
            config: config,
            driver: InMemoryQueryExecutor(),
            registry: registry,
          );
        },
        singleton: false,
        onRelease: (connection) {
          releases++;
        },
      );

      await manager.use('temp', (conn) async {
        await conn.query<Author>().firstOrNull();
      });

      expect(builds, 1);
      expect(releases, 1);
    });

    test('useSync throws when release hook is async', () {
      final manager = ConnectionManager();
      manager.register(
        'temp',
        ConnectionConfig(name: 'temp'),
        (config) => OrmConnection(
          config: config,
          driver: InMemoryQueryExecutor(),
          registry: registry,
        ),
        singleton: false,
        onRelease: (connection) async {
          await Future<void>.delayed(Duration.zero);
        },
      );

      expect(
        () => manager.useSync('temp', (conn) => conn.name),
        throwsStateError,
      );
    });

    test('throws descriptive error when connection missing', () {
      final manager = ConnectionManager();
      expect(() => manager.connection('unknown'), throwsStateError);
    });
  });
}
