import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:orm_playground/orm_playground.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('defaults to database.sqlite under current directory', () {
    final database = PlaygroundDatabase();
    final expected = p.normalize(
      p.join(Directory.current.path, 'database.sqlite'),
    );
    expect(database.databasePath, expected);
  });

  test('model registry registers generated definitions', () {
    final registry = buildOrmRegistry();
    expect(registry.contains<User>(), isTrue);
    expect(registry.contains<Post>(), isTrue);
    expect(registry.contains<Comment>(), isTrue);
  });

  test('open registers every tenant configured in orm.yaml', () async {
    final database = PlaygroundDatabase();
    final defaultConnection = await database.open();
    final analyticsConnection = await database.open(tenant: 'analytics');
    try {
      final manager = ConnectionManager.defaultManager;
      expect(manager.isRegistered(defaultConnection.name), isTrue);
      expect(manager.isRegistered(analyticsConnection.name), isTrue);
    } finally {
      await database.dispose();
    }
    final manager = ConnectionManager.defaultManager;
    expect(manager.isRegistered(defaultConnection.name), isFalse);
    expect(manager.isRegistered(analyticsConnection.name), isFalse);
  });
}
