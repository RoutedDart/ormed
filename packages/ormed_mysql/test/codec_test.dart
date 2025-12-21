import 'dart:io';
import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed_mysql/ormed_mysql.dart';
import 'package:test/test.dart';

void main() {
  test('JsonMapCodec is registered and works', () async {
    final url =
        Platform.environment['MYSQL_URL'] ??
        'mysql://root:secret@localhost:6605/orm_test';

    // Use the shared driver-test registry to ensure all models (including User)
    // are registered exactly as in the shared suites.
    final registry = bootstrapOrm();
    registerOrmFactories();

    final adapter = MySqlDriverAdapter.custom(
      config: DatabaseConfig(
        driver: 'mysql',
        options: {'url': url, 'ssl': true},
      ),
    );

    // Register codecs including JsonMapCodec
    adapter.codecs.registerCodec(
      key: 'JsonMapCodec',
      codec: const JsonMapCodec(),
    );

    final context = QueryContext(registry: registry, driver: adapter);

    // Clean up and create schema
    try {
      await adapter.executeRaw('DROP TABLE IF EXISTS users');
    } catch (_) {}

    await adapter.executeRaw('''
      CREATE TABLE users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        email VARCHAR(255) NOT NULL,
        active BOOLEAN DEFAULT TRUE,
        name VARCHAR(255),
        age INT,
        created_at DATETIME,
        profile JSON,
        metadata JSON
      )
    ''');

    // Test inserting a user with profile (uses JsonMapCodec)
    final user = const User(
      id: 1,
      email: 'test@example.com',
      active: true,
      name: 'Test User',
      age: 30,
      profile: {'theme': 'dark', 'notifications': true},
    );

    final repo = context.repository<User>();
    await repo.insert(user);

    // Test retrieving the user (decoding with JsonMapCodec)
    final retrieved = await context.query<User>().where('id', 1).first();

    expect(retrieved, isNotNull);
    expect(retrieved!.email, equals('test@example.com'));
    expect(retrieved.profile, isNotNull);
    expect(retrieved.profile!['theme'], equals('dark'));
    expect(retrieved.profile!['notifications'], equals(true));

    // Cleanup
    await adapter.executeRaw('DROP TABLE users');
    await adapter.close();
  });
}
