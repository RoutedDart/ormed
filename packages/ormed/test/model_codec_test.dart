import 'dart:convert';

import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  final registry = ValueCodecRegistry.instance
    ..registerCodecFor(JsonMapCodec, const JsonMapCodec());

  test('encodes maps using registered codecs', () {
    final user = User(
      id: 42,
      email: 'user@example.com',
      profile: {'theme': 'dark', 'flags': 2},
      createdAt: DateTime.utc(2024, 5, 1),
    );

    final encoded = UserOrmDefinition.definition.toMap(
      user.toTracked(),
      registry: registry,
    );

    expect(encoded['id'], 42);
    expect(encoded['profile'], jsonEncode({'theme': 'dark', 'flags': 2}));
  });

  test('decodes rows into concrete models with codecs applied', () {
    final now = DateTime.utc(2025, 1, 10);
    final data = <String, Object?>{
      'id': 100,
      'email': 'decode@example.com',
      'profile': jsonEncode({'lang': 'en'}),
      'created_at': now,
    };

    final model = UserOrmDefinition.definition.fromMap(
      data,
      registry: registry,
    );

    expect(model.id, 100);
    expect(model.profile, {'lang': 'en'});
    expect(model.createdAt, now);
  });
}
