import 'package:test/test.dart';

import '../../models/models.dart';
import '../../harness/driver_test_harness.dart';
import '../../config.dart';

void runLimitOffsetClausesTests(
  DriverHarnessBuilder<DriverTestHarness> createHarness,
  DriverTestConfig config,
) {
  group('Limit/Offset Clauses tests', () {
    late DriverTestHarness harness;

    setUp(() async {
      harness = await createHarness();
    });

    tearDown(() async => harness.dispose());

    test('limit', () async {
      await harness.seedUsers([
        User(id: 1, email: 'a@example.com', active: true),
        User(id: 2, email: 'b@example.com', active: false),
      ]);

      final users = await harness.context.query<User>().limit(1).get();
      expect(users, hasLength(1));
    });

    test('offset', () async {
      await harness.seedUsers([
        User(id: 1, email: 'a@example.com', active: true),
        User(id: 2, email: 'b@example.com', active: false),
      ]);

      final users = await harness.context
          .query<User>()
          .orderBy('id')
          .offset(1)
          .get();
      expect(users, hasLength(1));
      expect(users.first.id, 2);
    });

    test('paginate', () async {
      await harness.seedUsers([
        User(id: 1, email: 'a@example.com', active: true),
        User(id: 2, email: 'b@example.com', active: false),
        User(id: 3, email: 'c@example.com', active: true),
      ]);

      final page1 = await harness.context
          .query<User>()
          .orderBy('id')
          .paginate(perPage: 2, page: 1);
      expect(page1.items, hasLength(2));
      expect(page1.items.first.model.id, 1);
      expect(page1.total, 3);
      expect(page1.lastPage, 2);

      final page2 = await harness.context
          .query<User>()
          .orderBy('id')
          .paginate(perPage: 2, page: 2);
      expect(page2.items, hasLength(1));
      expect(page2.items.first.model.id, 3);
      expect(page2.total, 3);
    });

    test('simplePaginate', () async {
      await harness.seedUsers([
        User(id: 1, email: 'a@example.com', active: true),
        User(id: 2, email: 'b@example.com', active: false),
        User(id: 3, email: 'c@example.com', active: true),
      ]);

      final page1 = await harness.context
          .query<User>()
          .orderBy('id')
          .simplePaginate(perPage: 2, page: 1);
      expect(page1.items, hasLength(2));
      expect(page1.hasMorePages, isTrue);

      final page2 = await harness.context
          .query<User>()
          .orderBy('id')
          .simplePaginate(perPage: 2, page: 2);
      expect(page2.items, hasLength(1));
      expect(page2.hasMorePages, isFalse);
    });
  });
}
