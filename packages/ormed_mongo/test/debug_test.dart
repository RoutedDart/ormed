import 'package:test/test.dart';
import 'package:driver_tests/src/models/models.dart';
import 'support/mongo_harness.dart';

void main() {
  late MongoTestHarness harness;

  setUp(() async {
    harness = await MongoTestHarness.create();
  });

  tearDown(() async {
    await harness.dispose();
  });

  test('debug id equals', () async {
    await harness.seedUsers([
      User(id: 1, email: 'test1@example.com', active: true),
      User(id: 2, email: 'test2@example.com', active: false),
    ]);

    final users = await harness.context
        .query<User>()
        .whereEquals('id', 2)
        .get();

    print('DEBUG: id=2 users found: ${users.length}');
    expect(users, hasLength(1));
    expect(users.first.id, equals(2));
  });
}
