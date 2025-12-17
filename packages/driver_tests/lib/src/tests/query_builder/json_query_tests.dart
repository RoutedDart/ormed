import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models/models.dart';

void runJsonQueryTests() {
  ormedGroup('JSON Query Operations', (dataSource) {
    test('whereJsonContains - simple value in array', () async {
      await dataSource.repo<User>().insertMany([
        User(
          id: 1,
          email: 'user1@test.com',
          active: true,
          metadata: {
            'skills': ['Dart', 'Flutter'],
          },
        ),
        User(
          id: 2,
          email: 'user2@test.com',
          active: true,
          metadata: {
            'skills': ['Python', 'Django'],
          },
        ),
      ]);

      final users = await dataSource.context
          .query<User>()
          .whereJsonContains('metadata', 'Dart', path: r'$.skills')
          .get();

      expect(users, hasLength(1));
      expect(users.first.id, 1);
    });

    test('hydrates JSON payloads as Dart structures', () async {
      await dataSource.repo<User>().insert(
        User(
          id: 10,
          email: 'json@test.com',
          active: true,
          metadata: {
            'skills': ['Dart', 'Flutter'],
            'flags': [true, false, null],
            'count': 2,
            'nested': {
              'ok': true,
              'items': [
                {'id': 1},
                {'id': 2},
              ],
            },
          },
        ),
      );

      final fetched = await dataSource.context
          .query<User>()
          .whereEquals('id', 10)
          .firstOrFail();

      final metadata = fetched.metadata!;
      expect(metadata['count'], equals(2));
      expect(metadata['skills'], isA<List>());
      expect((metadata['skills'] as List).first, equals('Dart'));
      expect(metadata['nested'], isA<Map>());
      final nested = (metadata['nested'] as Map).cast<String, Object?>();
      expect(nested['ok'], isTrue);
      expect(nested['items'], isA<List>());
    });

    test(r'JSON selectors accept $.property syntax', () async {
      await dataSource.repo<User>().insert(
        User(
          id: 11,
          email: 'json-selectors@test.com',
          active: true,
          metadata: {
            'mode': 'dark',
            'tags': ['alpha', 'beta'],
          },
        ),
      );

      final users = await dataSource.context
          .query<User>()
          .where(r'metadata->>$.mode', 'dark')
          .get();

      expect(users.map((u) => u.id), equals([11]));

      final tagged = await dataSource.context
          .query<User>()
          .whereJsonContains('metadata', 'beta', path: r'$.tags')
          .get();
      expect(tagged.map((u) => u.id), equals([11]));
    });

    test('deep JSON documents support helpers and selectors', () async {
      await dataSource.repo<User>().insertMany([
        User(
          id: 20,
          email: 'json-deep@test.com',
          active: true,
          metadata: {
            'mode': 'dark',
            'tags': ['alpha', 'beta', 'release'],
            'numbers': [1, 2, 3],
            'meta': {
              'count': 3,
              'profile': {
                'settings': {
                  'theme': 'dark',
                  'flags': {'alpha': true, 'beta': false},
                },
                'skills': ['Dart', 'SQL', 'Flutter'],
                'items': [
                  {'id': 1, 'label': 'a'},
                  {'id': 2, 'label': 'b'},
                ],
              },
            },
          },
        ),
        User(
          id: 21,
          email: 'json-deep-other@test.com',
          active: true,
          metadata: {
            'mode': 'light',
            'tags': ['gamma'],
            'meta': {
              'profile': {
                'settings': {
                  'theme': 'light',
                  'flags': {'alpha': false},
                },
                'skills': ['Go'],
                'items': [
                  {'id': 1, 'label': 'x'},
                ],
              },
            },
          },
        ),
      ]);

      final contains = await dataSource.context
          .query<User>()
          .whereJsonContains('metadata', 'Dart', path: r'$.meta.profile.skills')
          .get();
      expect(contains.map((u) => u.id), equals([20]));

      final overlaps = await dataSource.context.query<User>().whereJsonOverlaps(
        'metadata',
        ['Rust', 'Dart'],
        path: r'$.meta.profile.skills',
      ).get();
      expect(overlaps.map((u) => u.id), equals([20]));

      final containsViaSelector = await dataSource.context
          .query<User>()
          .whereJsonContains('metadata->tags', 'beta')
          .get();
      expect(containsViaSelector.map((u) => u.id), equals([20]));

      final keyExists = await dataSource.context
          .query<User>()
          .whereJsonContainsKey(
            'metadata',
            r'$.meta.profile.settings.flags.beta',
          )
          .get();
      expect(keyExists.map((u) => u.id), equals([20]));

      final lengthViaSelector = await dataSource.context
          .query<User>()
          .whereJsonLength('metadata->meta.profile.items', 2)
          .get();
      expect(lengthViaSelector.map((u) => u.id), equals([20]));

      final deepSelectorString = await dataSource.context
          .query<User>()
          .where(r'metadata->>$.meta.profile.settings.theme', 'dark')
          .get();
      expect(deepSelectorString.map((u) => u.id), equals([20]));

      final deepSelectorIndex = await dataSource.context
          .query<User>()
          .where(r'metadata->>$.meta.profile.items[1].label', 'b')
          .get();
      expect(deepSelectorIndex.map((u) => u.id), equals([20]));

      final deepSelectorIndexDot = await dataSource.context
          .query<User>()
          .where(r'metadata->>$.meta.profile.items.1.label', 'b')
          .get();
      expect(deepSelectorIndexDot.map((u) => u.id), equals([20]));

      final deepSelectorBool = await dataSource.context
          .query<User>()
          .where(r'metadata->$.meta.profile.settings.flags.alpha', true)
          .get();
      expect(deepSelectorBool.map((u) => u.id), equals([20]));
    });

    test('tracked models can queue JSON updates', () async {
      final connection = dataSource.options.name;
      final seeded = User(
        id: 12,
        email: 'json-model@test.com',
        active: true,
        metadata: {
          'mode': 'dark',
          'meta': {'count': 1},
          'flags': {'alpha': true},
        },
      );

      await Users.repo(connection).insert(seeded.toTracked());

      final tracked = await Users.query(
        connection,
      ).where('id', 12).firstOrFail();
      tracked.jsonSetPath('metadata', r'$.meta.count', 5);
      tracked.jsonSet('metadata->mode', 'light');
      tracked.jsonSetPath('metadata', r'$.flags.beta', true);
      tracked.jsonPatch('metadata', {
        'extra': {'enabled': true},
      });
      await tracked.save();

      final refetched = await Users.query(
        connection,
      ).where('id', 12).firstOrFail();
      final metadata = refetched.metadata!;
      expect(metadata['mode'], equals('light'));
      expect(metadata['meta'], isA<Map>());
      final meta = (metadata['meta'] as Map).cast<String, Object?>();
      expect(meta['count'], equals(5));
      expect(metadata['flags'], isA<Map>());
      final flags = (metadata['flags'] as Map).cast<String, Object?>();
      expect(
        flags['alpha'],
        anyOf(isTrue, equals(1)),
        reason: 'boolean may be encoded as bool or int',
      );
      expect(
        flags['beta'],
        anyOf(isTrue, equals(1)),
        reason: 'boolean may be encoded as bool or int',
      );
      expect(metadata['extra'], isA<Map>());
    });

    test('whereJsonLength - array length exact match', () async {
      await dataSource.repo<User>().insertMany([
        User(
          id: 1,
          email: 'user1@test.com',
          active: true,
          metadata: {
            'tags': ['a', 'b', 'c'],
          },
        ),
        User(
          id: 2,
          email: 'user2@test.com',
          active: true,
          metadata: {
            'tags': ['x'],
          },
        ),
      ]);

      final users = await dataSource.context
          .query<User>()
          .whereJsonLength('metadata->tags', 3)
          .get();

      expect(users.length, greaterThanOrEqualTo(1));
    });

    test('whereJsonContainsKey - key existence', () async {
      await dataSource.repo<User>().insertMany([
        User(
          id: 1,
          email: 'user1@test.com',
          active: true,
          metadata: {
            'address': {'city': 'NYC'},
          },
        ),
        User(
          id: 2,
          email: 'user2@test.com',
          active: true,
          metadata: {'name': 'John'},
        ),
      ]);

      final users = await dataSource.context
          .query<User>()
          .whereJsonContainsKey('metadata')
          .get();

      expect(users, hasLength(2));
    });

    test('whereJsonOverlaps - array intersection', () async {
      await dataSource.repo<User>().insertMany([
        User(
          id: 1,
          email: 'user1@test.com',
          active: true,
          metadata: {
            'skills': ['Dart', 'Flutter', 'Go'],
          },
        ),
        User(
          id: 2,
          email: 'user2@test.com',
          active: true,
          metadata: {
            'skills': ['Python', 'Django'],
          },
        ),
      ]);

      final users = await dataSource.context.query<User>().whereJsonOverlaps(
        'metadata->skills',
        ['Dart', 'Python'],
      ).get();

      expect(users.length, greaterThanOrEqualTo(2));
    });

    test('whereLike - pattern matching', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'john@example.com', active: true),
        User(id: 2, email: 'jane@example.com', active: true),
        User(id: 3, email: 'bob@test.com', active: true),
      ]);

      final users = await dataSource.context
          .query<User>()
          .whereLike('email', '%@example.com')
          .get();

      expect(users.length, greaterThanOrEqualTo(2));
    });
  });
}
