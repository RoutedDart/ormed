import 'package:ormed_mysql/ormed_mysql.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  group('MySQL/MariaDB Database Creation', () {
    test('MySQL driver can create new database', () async {
      final url =
          Platform.environment['MYSQL_URL'] ??
          'mysql://root:secret@localhost:6605/orm_test';

      // Parse URL to connect without database specified
      final uri = Uri.parse(url);
      final userInfo = uri.userInfo.split(':');
      final user = userInfo[0];
      final password = userInfo.length > 1 ? userInfo[1] : '';
      final host = uri.host;
      final port = uri.port;

      // Connect to MySQL without specifying a database
      final systemUrl = 'mysql://$user:$password@$host:$port/mysql?secure=true';
      final adapter = MySqlDriverAdapter.fromUrl(systemUrl);

      try {
        final testDbName =
            'orm_test_create_${DateTime.now().millisecondsSinceEpoch}';

        // Try to create a new database
        await adapter.executeRaw('CREATE DATABASE `$testDbName`');

        // Verify it was created
        final result = await adapter.queryRaw(
          'SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = ?',
          [testDbName],
        );

        expect(result, isNotEmpty, reason: 'Database should be created');
        final schemaName =
            result.first['SCHEMA_NAME'] ?? result.first['schema_name'];
        expect(schemaName, equals(testDbName));

        // Clean up - drop the test database
        await adapter.executeRaw('DROP DATABASE `$testDbName`');
      } finally {
        await adapter.close();
      }
    });

    test('MariaDB driver can create new database', () async {
      final url =
          Platform.environment['MARIADB_URL'] ??
          'mysql://root:secret@localhost:6604/orm_test';

      // Parse URL to connect without database specified
      final uri = Uri.parse(url);
      final userInfo = uri.userInfo.split(':');
      final user = userInfo[0];
      final password = userInfo.length > 1 ? userInfo[1] : '';
      final host = uri.host;
      final port = uri.port;

      // Connect to MariaDB without specifying a database
      final systemUrl = 'mysql://$user:$password@$host:$port/mysql?secure=true';
      final adapter = MySqlDriverAdapter.fromUrl(systemUrl);

      try {
        final testDbName =
            'orm_test_create_${DateTime.now().millisecondsSinceEpoch}';
        // Try to create a new database
        await adapter.executeRaw('CREATE DATABASE `$testDbName`');

        // Verify it was created
        final result = await adapter.queryRaw(
          'SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = ?',
          [testDbName],
        );

        expect(result, isNotEmpty, reason: 'Database should be created');
        final schemaName =
            result.first['SCHEMA_NAME'] ?? result.first['schema_name'];
        expect(schemaName, equals(testDbName));

        // Clean up - drop the test database
        await adapter.executeRaw('DROP DATABASE `$testDbName`');
      } finally {
        await adapter.close();
      }
    });

    test('MySQL driver can switch to newly created database', () async {
      final url =
          Platform.environment['MYSQL_URL'] ??
          'mysql://root:secret@localhost:6605/orm_test';

      // Parse URL to connect without database specified
      final uri = Uri.parse(url);
      final userInfo = uri.userInfo.split(':');
      final user = userInfo[0];
      final password = userInfo.length > 1 ? userInfo[1] : '';
      final host = uri.host;
      final port = uri.port;

      final systemUrl = 'mysql://$user:$password@$host:$port/mysql?secure=true';
      final adapter = MySqlDriverAdapter.fromUrl(systemUrl);

      try {
        final testDbName =
            'orm_test_switch_${DateTime.now().millisecondsSinceEpoch}';

        // Create database
        await adapter.createDatabase(testDbName);

        // Switch to new database
        await adapter.executeRaw('USE `$testDbName`');

        // Create a table in the new database
        await adapter.executeRaw('''
          CREATE TABLE test_users (
            id INT PRIMARY KEY AUTO_INCREMENT,
            name VARCHAR(255)
          )
        ''');

        // Verify table exists in the new database
        final result = await adapter.queryRaw(
          '''
          SELECT TABLE_NAME 
          FROM information_schema.TABLES 
          WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?
        ''',
          [testDbName, 'test_users'],
        );

        expect(result, isNotEmpty);
        final tableName =
            result.first['TABLE_NAME'] ?? result.first['table_name'];
        expect(tableName, equals('test_users'));

        // Clean up
        await adapter.dropDatabase(testDbName);
      } finally {
        await adapter.close();
      }
    });
  });
}
