import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:test/test.dart';
import 'shared.dart';
import 'package:ormed_mongo/ormed_mongo.dart';

void main() {
  late DataSource dataSource;
  late MongoDriverAdapter driverAdapter;

  setUp(() async {
    await waitForMongoReady();
    await clearDatabase();
    driverAdapter = createAdapter();
    registerDriverTestFactories();
    dataSource = DataSource(DataSourceOptions(
      driver: driverAdapter,
      entities: generatedOrmModelDefinitions,
    ));
    await dataSource.init();
  });

  tearDown(() async {
    await dataSource.dispose();
  });

  test('debug id equals', () async {
    await dataSource.repo<User>().insertMany([
      User(id: 1, email: 'test1@example.com', active: true),
      User(id: 2, email: 'test2@example.com', active: false),
    ]);

    final users = await dataSource.context
        .query<User>()
        .whereEquals('id', 2)
        .get();

    print('DEBUG: id=2 users found: ${users.length}');
    expect(users, hasLength(1));
    expect(users.first.id, equals(2));
  }, skip: 'Temporary debug helper is disabled.');

  test('debug active filter', () async {
    await dataSource.repo<User>().insertMany([
      User(id: 1, email: 'test1@example.com', active: true),
      User(id: 2, email: 'test2@example.com', active: false),
    ]);

    final rows = await dataSource.context
        .query<User>()
        .whereEquals('active', true)
        .orderBy('email', descending: true)
        .limit(1)
        .rows();

    final row = rows.single;
    print('DEBUG: active rows found: ${rows.length} -> ${row.model.id}');
    expect(rows, hasLength(1));
    expect(row.model.active, isTrue);
    expect(row.model.id, equals(1));
  }, skip: 'Temporary debug helper is disabled.');
}
