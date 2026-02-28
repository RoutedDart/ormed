import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:test/test.dart';

void main() {
  group('Postgres Database Creation', () {
    test('Postgres driver can create new database', () async {
      final url =
          OrmedEnvironment().firstNonEmpty(['POSTGRES_URL']) ??
          'postgres://postgres:postgres@localhost:6543/orm_test';

      // Parse URL to connect to postgres system database
      final uri = Uri.parse(url);
      final userInfo = uri.userInfo.split(':');
      final user = userInfo[0];
      final password = userInfo.length > 1 ? userInfo[1] : '';
      final host = uri.host;
      final port = uri.port;

      // Connect to postgres system database
      final systemUrl = 'postgres://$user:$password@$host:$port/postgres';
      final adapter = PostgresDriverAdapter.fromUrl(systemUrl);

      try {
        final testDbName =
            'orm_test_create_${DateTime.now().millisecondsSinceEpoch}';

        // Try to create a new database
        await adapter.executeRaw('CREATE DATABASE "$testDbName"');

        // Verify it was created
        final result = await adapter.queryRaw(
          'SELECT datname FROM pg_database WHERE datname = ?',
          [testDbName],
        );

        expect(result, isNotEmpty, reason: 'Database should be created');
        expect(result.first['datname'], equals(testDbName));

        // Clean up - drop the test database
        await adapter.executeRaw('DROP DATABASE "$testDbName"');
      } finally {
        await adapter.close();
      }
    });

    test('Postgres driver can connect to newly created database', () async {
      final url =
          OrmedEnvironment().firstNonEmpty(['POSTGRES_URL']) ??
          'postgres://postgres:postgres@localhost:6543/orm_test';

      final uri = Uri.parse(url);
      final userInfo = uri.userInfo.split(':');
      final user = userInfo[0];
      final password = userInfo.length > 1 ? userInfo[1] : '';
      final host = uri.host;
      final port = uri.port;

      final systemUrl = 'postgres://$user:$password@$host:$port/postgres';
      final systemAdapter = PostgresDriverAdapter.fromUrl(systemUrl);

      try {
        final testDbName =
            'orm_test_connect_${DateTime.now().millisecondsSinceEpoch}';

        // Create database
        await systemAdapter.executeRaw('CREATE DATABASE "$testDbName"');

        // Connect to the new database
        final testDbUrl = 'postgres://$user:$password@$host:$port/$testDbName';
        final testAdapter = PostgresDriverAdapter.fromUrl(testDbUrl);

        try {
          // Create a table in the new database
          await testAdapter.executeRaw('''
            CREATE TABLE test_users (
              id SERIAL PRIMARY KEY,
              name VARCHAR(255)
            )
          ''');

          // Verify table exists in the new database
          final result = await testAdapter.queryRaw(
            '''
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = ?
          ''',
            ['test_users'],
          );

          expect(result, isNotEmpty);
          expect(result.first['table_name'], equals('test_users'));
        } finally {
          await testAdapter.close();
        }

        // Clean up
        await systemAdapter.executeRaw('DROP DATABASE "$testDbName"');
      } finally {
        await systemAdapter.close();
      }
    });

    test(
      'Postgres driver can create databases with different names for parallel tests',
      () async {
        final url =
            OrmedEnvironment().firstNonEmpty(['POSTGRES_URL']) ??
            'postgres://postgres:postgres@localhost:6543/orm_test';

        final uri = Uri.parse(url);
        final userInfo = uri.userInfo.split(':');
        final user = userInfo[0];
        final password = userInfo.length > 1 ? userInfo[1] : '';
        final host = uri.host;
        final port = uri.port;

        final systemUrl = 'postgres://$user:$password@$host:$port/postgres';
        final adapter = PostgresDriverAdapter.fromUrl(systemUrl);

        try {
          // Simulate creating databases for different test processes
          // (like Laravel's ParallelTesting token approach)
          final testDbs = <String>[];

          for (var i = 1; i <= 3; i++) {
            final testDbName =
                'orm_test_parallel_${DateTime.now().millisecondsSinceEpoch}_$i';
            testDbs.add(testDbName);
            await adapter.executeRaw('CREATE DATABASE "$testDbName"');
          }

          // Verify all databases were created
          for (final dbName in testDbs) {
            final result = await adapter.queryRaw(
              'SELECT datname FROM pg_database WHERE datname = ?',
              [dbName],
            );
            expect(result, isNotEmpty, reason: 'Database $dbName should exist');
          }

          // Clean up all test databases
          for (final dbName in testDbs) {
            await adapter.executeRaw('DROP DATABASE "$dbName"');
          }
        } finally {
          await adapter.close();
        }
      },
    );
  });
}
