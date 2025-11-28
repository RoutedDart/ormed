import 'package:postgres/postgres.dart';

void main() async {
  final url = 'postgres://postgres:postgres@127.0.0.1:6543/orm_test';

  final connection = await Connection.open(
    Endpoint(
      host: '127.0.0.1',
      port: 6543,
      database: 'orm_test',
      username: 'postgres',
      password: 'postgres',
    ),
    settings: ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    // Create a test table
    await connection.execute('DROP TABLE IF EXISTS json_test');

    await connection.execute(
      'CREATE TABLE json_test (id INT PRIMARY KEY, payload JSONB)',
    );

    print('Table created');

    // Insert test data using TypedValue
    final testData = {
      'mode': 'dark',
      'featured': true,
      'tags': ['alpha', 'beta'],
      'meta': {
        'author': {'name': 'Alicia'},
      },
    };

    print('Inserting: $testData');

    await connection.execute(
      Sql.named('INSERT INTO json_test (id, payload) VALUES (@id, @payload)'),
      parameters: {'id': 1, 'payload': TypedValue(Type.jsonb, testData)},
    );

    print('Data inserted');

    // Query it back
    final result = await connection.execute(
      'SELECT id, payload, pg_typeof(payload) as type FROM json_test WHERE id = 1',
    );

    for (final row in result) {
      print('Row: ${row.toColumnMap()}');
      print('Payload type: ${row[2]}');
      print('Payload value: ${row[1]}');
      print('Payload class: ${row[1].runtimeType}');
    }

    // Try the JSON contains key query
    print('\n--- Testing JSON contains key query ---');
    // payload->meta->author->name
    // target = payload #> '{meta,author}'
    // check ? 'name'
    final keyResult = await connection.execute(
      r'''SELECT id FROM json_test WHERE coalesce((payload #> '{meta,author}')::jsonb ? 'name', false)''',
    );

    print('Key query result: ${keyResult.length} rows');
    for (final row in keyResult) {
      print('  ID: ${row[0]}');
    }

    // Try alternative syntax
    print('\n--- Testing alternative syntax ---');
    final altResult = await connection.execute(
      "SELECT id FROM json_test WHERE payload -> 'tags' @> '[\"beta\"]'::jsonb",
    );

    print('Alternative query result: ${altResult.length} rows');
    for (final row in altResult) {
      print('  ID: ${row[0]}');
    }

    // Check array elements
    print('\n--- Checking tags array ---');
    final tagsResult = await connection.execute(
      "SELECT payload -> 'tags' as tags FROM json_test WHERE id = 1",
    );

    for (final row in tagsResult) {
      print('Tags: ${row[0]}');
      print('Tags type: ${row[0].runtimeType}');
    }
  } finally {
    await connection.close();
  }
}
