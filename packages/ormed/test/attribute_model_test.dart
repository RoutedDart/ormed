import 'dart:convert';

import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  group('Generated AttributeUser', () {
    test('metadata drives guards, hidden lists, and casts', () {
      final metadata = AttributeUserOrmDefinition.definition.metadata;
      expect(metadata.hidden, contains('secret'));
      expect(metadata.fillable, containsAll(['email', 'role']));
      expect(metadata.fieldOverrides['secret']?.hidden, isTrue);
      expect(metadata.casts['profile'], 'json');

      final registry = ValueCodecRegistry.standard();
      registry.registerCodec(key: 'json', codec: _JsonCodec());

      final user = AttributeUserOrmDefinition.definition.codec.decode({
        'id': 1,
        'email': 'a@x.dev',
        'secret': 'top',
        'role': null,
        'profile': null,
      }, registry);

      user.fill({
        'email': 'b@x.dev',
        'role': 'admin',
        'profile': '{"bio":"hey"}',
      }, registry: registry);

      expect(user.getAttribute('email'), 'b@x.dev');
      expect(user.getAttribute('role'), 'admin');
      final profile = user.getAttribute<Map<String, Object?>>('profile');
      expect(profile, containsPair('bio', 'hey'));

      final payload = user.toArray(registry: registry);
      expect(payload.containsKey('secret'), isFalse);
      expect(payload['profile'], isA<String>());

      final visible = user.toArray(includeHidden: true, registry: registry);
      expect(visible['secret'], 'top');
    });

    test('fillable guards drop unlisted attributes', () {
      final registry = ValueCodecRegistry.standard();
      final user = AttributeUserOrmDefinition.definition.codec.decode({
        'id': 2,
        'email': 'c@x.dev',
        'secret': 'hidden',
        'role': null,
        'profile': null,
      }, registry);
      user.fill({'id': 5, 'email': 'z@x.dev', 'secret': 'nope'}, strict: false);
      expect(user.getAttribute('id'), 2);
      expect(user.getAttribute('secret'), 'hidden');
      expect(user.getAttribute('email'), 'z@x.dev');
    });

    test('direct setters propagate into attributes', () {
      // Final fields cannot be assigned through the static `AttributeUser`
      // type, so we keep this test to ensure the helper API still syncs the
      // attribute bag when using the generated setter extension.
      final registry = ValueCodecRegistry.standard();
      final user = AttributeUserOrmDefinition.definition.codec.decode({
        'id': 3,
        'email': 'd@x.dev',
        'secret': 'hidden',
        'role': null,
        'profile': null,
      }, registry);
      user.setAttribute('email', 'updated@x.dev');
      user.setAttribute('id', 11);

      expect(user.getAttribute('id'), 11);
      expect(user.email, 'updated@x.dev');
    });
    test('ModelFactory helper exposes definition and codecs', () {
      final registry = ModelRegistry();
      AttributeUserModelFactory.registerWith(registry);
      expect(registry.contains<AttributeUser>(), isTrue);

      final payload = {
        'id': 4,
        'email': 'f@x.dev',
        'secret': 'exposed',
        'role': 'staff',
        'profile': null,
      };
      final user = AttributeUserModelFactory.fromMap(payload);
      expect(user.email, 'f@x.dev');
      expect(AttributeUserModelFactory.codec, isA<ModelCodec<AttributeUser>>());

      final snapshot = AttributeUserModelFactory.toMap(
        user,
        registry: ValueCodecRegistry.standard(),
      );
      expect(snapshot['email'], 'f@x.dev');
      expect(snapshot['secret'], 'exposed');
      expect(
        AttributeUserModelFactory.definition,
        AttributeUserOrmDefinition.definition,
      );
    });

    test(
      'ModelFactory.withConnection binds queries and repositories',
      () async {
        final registry = ModelRegistry()
          ..register(AttributeUserModelFactory.definition);
        final context = QueryContext(
          registry: registry,
          driver: InMemoryQueryExecutor(),
        );

        final binding = AttributeUserModelFactory.withConnection(context);
        final query = binding.query();
        expect(query.definition, AttributeUserModelFactory.definition);

        final repository = binding.repository();
        expect(repository.definition, AttributeUserModelFactory.definition);
        expect(binding.context, context);
      },
    );
  });
}

class _JsonCodec extends ValueCodec<Map<String, Object?>> {
  @override
  Object? encode(Map<String, Object?>? value) =>
      value == null ? null : jsonEncode(value);

  @override
  Map<String, Object?>? decode(Object? value) {
    if (value is! String) return value as Map<String, Object?>?;
    final decoded = jsonDecode(value) as Map<String, Object?>;
    return decoded;
  }
}
