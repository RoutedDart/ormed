import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  group('OrmConnectionFactory', () {
    test('registers and returns handle', () async {
      final manager = ConnectionManager();
      final factory = OrmConnectionFactory(manager: manager);
      final registry = ModelRegistry();
      final config = ConnectionConfig(name: 'test');
      final driver = InMemoryQueryExecutor();

      final handle = factory.register(
        name: 'test',
        connection: config,
        builder: (_) =>
            OrmConnection(config: config, driver: driver, registry: registry),
      );

      expect(handle.name, equals('test'));
      await handle.use((connection) async {
        expect(connection.driver, same(driver));
      });
      await handle.dispose();
    });

    test('invokes release hook for non-singletons', () async {
      final manager = ConnectionManager();
      final factory = OrmConnectionFactory(manager: manager);
      final registry = ModelRegistry();
      final config = ConnectionConfig(name: 'transient');
      var closed = 0;

      final handle = factory.register(
        name: 'transient',
        connection: config,
        singleton: false,
        builder: (_) => OrmConnection(
          config: config,
          driver: _DisposableDriver(onClose: () => closed++),
          registry: registry,
        ),
        onRelease: (connection) async {
          await connection.driver.close();
        },
      );

      await handle.use((_) async {});
      expect(closed, equals(1));
      await handle.dispose();
    });
  });
}

class _DisposableDriver extends DriverAdapter {
  _DisposableDriver({required this.onClose});

  final void Function() onClose;

  @override
  DriverMetadata get metadata => const DriverMetadata(name: 'test');

  @override
  ValueCodecRegistry get codecs => ValueCodecRegistry.standard();

  @override
  Future<void> close() async => onClose();

  @override
  Future<List<Map<String, Object?>>> execute(QueryPlan plan) async => const [];

  @override
  Stream<Map<String, Object?>> stream(QueryPlan plan) =>
      const Stream<Map<String, Object?>>.empty();

  @override
  Future<void> executeRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {}

  @override
  Future<List<Map<String, Object?>>> queryRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async => const [];

  @override
  Future<MutationResult> runMutation(MutationPlan plan) async =>
      const MutationResult(affectedRows: 0);

  @override
  StatementPreview describeQuery(QueryPlan plan) =>
      const StatementPreview(payload: SqlStatementPayload(sql: ''));

  @override
  StatementPreview describeMutation(MutationPlan plan) =>
      const StatementPreview(payload: SqlStatementPayload(sql: ''));

  @override
  PlanCompiler get planCompiler => fallbackPlanCompiler();

  @override
  Future<R> transaction<R>(Future<R> Function() action) => Future.sync(action);

  @override
  Future<int?> threadCount() async => null;
}
