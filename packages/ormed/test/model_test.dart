import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import 'models/active_user.dart';

void main() {
  group('Model base', () {
    late InMemoryQueryExecutor driver;
    late ModelRegistry registry;
    late QueryContext context;
    final requestedConnections = <String>[];

    setUp(() {
      driver = InMemoryQueryExecutor();
      registry = ModelRegistry()..register(ActiveUserOrmDefinition.definition);
      context = QueryContext(registry: registry, driver: driver);
      requestedConnections.clear();
      Model.bindConnectionResolver(
        resolveConnection: (name) {
          requestedConnections.add(name);
          return context;
        },
        defaultConnection: 'primary',
      );
    });

    tearDown(() {
      Model.unbindConnectionResolver();
      driver.clear();
    });

    test('expectDefinition attaches metadata lazily', () {
      final user = ActiveUser(email: 'one@example.com');
      expect(user.hasDefinition, isFalse);
      final definition = user.expectDefinition();
      expect(definition, ActiveUserOrmDefinition.definition);
      expect(user.hasDefinition, isTrue);
    });

    test('save inserts new model instances via the model helpers', () async {
      final created = await ActiveUser(email: 'new@example.com').save();
      expect(created.id, isNull);
      expect(created.connectionResolver, same(context));
      final rows = await Model.query<ActiveUser>().get();
      expect(rows, hasLength(1));
      expect(rows.first.email, 'new@example.com');
      expect(requestedConnections, contains('analytics'));
    });

    test(
      'save updates existing rows when the primary key is present',
      () async {
        driver.register(ActiveUserOrmDefinition.definition, [
          ActiveUser(id: 1, email: 'before@example.com'),
        ]);
        final seeded = await Model.query<ActiveUser>().firstOrFail();
        final updated = await ActiveUser(
          id: 1,
          email: 'after@example.com',
        ).save();
        expect(updated.email, 'after@example.com');
        final refreshed = await seeded.refresh();
        expect(refreshed.email, 'after@example.com');
      },
    );

    test('delete toggles soft delete metadata by default', () async {
      driver.register(ActiveUserOrmDefinition.definition, [
        ActiveUser(id: 2, email: 'soft@example.com'),
      ]);
      final user = await Model.query<ActiveUser>().firstOrFail();
      await user.delete();
      expect(user.trashed, isTrue);
      final trashed = await Model.query<ActiveUser>().withTrashed().get();
      expect(trashed.single.deletedAt, isNotNull);
    });

    test('forceDelete removes the record entirely', () async {
      driver.register(ActiveUserOrmDefinition.definition, [
        ActiveUser(id: 3, email: 'gone@example.com'),
      ]);
      final user = await Model.query<ActiveUser>().firstOrFail();
      await user.forceDelete();
      final all = await Model.query<ActiveUser>().withTrashed().get();
      expect(all, isEmpty);
    });

    test('restore clears the soft delete timestamp', () async {
      driver.register(ActiveUserOrmDefinition.definition, [
        ActiveUser(id: 4, email: 'restore@example.com'),
      ]);
      final user = await Model.query<ActiveUser>().firstOrFail();
      await user.delete();
      expect(user.trashed, isTrue);
      await user.restore();
      expect(user.trashed, isFalse);
    });

    test('refresh reloads the latest values from the database', () async {
      driver.register(ActiveUserOrmDefinition.definition, [
        ActiveUser(id: 5, email: 'refresh@example.com'),
      ]);
      final user = await Model.query<ActiveUser>().firstOrFail();
      final repo = context.repository<ActiveUser>();
      await repo.updateMany([
        ActiveUser(id: 5, email: 'updated@example.com'),
      ], returning: false);
      final refreshed = await user.refresh();
      expect(refreshed.email, 'updated@example.com');
    });

    test('query dispatches through the configured resolver', () async {
      driver.register(ActiveUserOrmDefinition.definition, [
        ActiveUser(id: 6, email: 'query@example.com'),
      ]);
      final models = await Model.query<ActiveUser>().get();
      expect(models, hasLength(1));
      expect(models.first.email, 'query@example.com');
      expect(requestedConnections, containsAll(['primary', 'analytics']));
    });

    test('jsonSet helpers queue JSON updates for save', () async {
      driver.register(ActiveUserOrmDefinition.definition, [
        ActiveUser(
          id: 7,
          email: 'json@example.com',
          settings: {
            'mode': 'dark',
            'meta': {'count': 1},
          },
        ),
      ]);
      final user = await Model.query<ActiveUser>().whereEquals('id', 7).first();
      expect(user, isNotNull);
      user!.jsonSet('settings->mode', 'light');
      user.jsonSetPath('settings', r'$.meta.count', 5);
      await user.save();

      final refreshed = await Model.query<ActiveUser>()
          .whereEquals('id', 7)
          .firstOrFail();
      expect(refreshed.settings['mode'], 'light');
      final meta = refreshed.settings['meta'] as Map<String, Object?>?;
      expect(meta?['count'], 5);
    });
    test(
      'save inserts new model instances even with user-assigned PK',
      () async {
        final user = ActiveUser(id: 100, email: 'assigned@example.com');
        final saved = await user.save();
        expect(saved.id, 100);

        final rows = await Model.query<ActiveUser>()
            .whereEquals('id', 100)
            .get();
        expect(rows, hasLength(1));
      },
    );

    test('save updates models that were previously saved', () async {
      final user = await ActiveUser(
        id: 101,
        email: 'original@example.com',
      ).save();
      user.email = 'changed@example.com';
      await user.save();

      final rows = await Model.query<ActiveUser>()
          .whereEquals('id', user.id)
          .get();
      expect(rows.single.email, 'changed@example.com');
      expect(rows, hasLength(1));
    });

    test('save falls back to insert if update affects 0 rows', () async {
      final user = await ActiveUser(
        id: 102,
        email: 'fallback@example.com',
      ).save();

      // Simulate external deletion
      await context.repository<ActiveUser>().deleteByKeys([
        {'id': user.id},
      ]);

      // Save should re-insert
      user.email = 'restored@example.com';
      await user.save();

      final rows = await Model.query<ActiveUser>()
          .whereEquals('id', user.id)
          .get();
      expect(rows, hasLength(1));
      expect(rows.single.email, 'restored@example.com');
    });
  });
}
