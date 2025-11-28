import 'package:test/test.dart';
import 'package:driver_tests/driver_tests.dart';
import 'support/database_utils.dart';

void main() {
  test('insertMany should insert all records', () async {
    final harness = await SqliteTestHarness.inMemory();
    
    try {
      // Try to insert 3 authors
      await harness.seedAuthors([
        const Author(id: 1, name: 'Alice'),
        const Author(id: 2, name: 'Bob'),
        const Author(id: 3, name: 'Charlie'),
      ]);
      
      // Query to verify all were inserted
      final authors = await harness.context.query<Author>().get();
      
      print('Inserted ${authors.length} authors');
      for (final author in authors) {
        print('  - ${author.id}: ${author.name}');
      }
      
      expect(authors.length, equals(3));
      expect(authors.map((a) => a.name).toList(), containsAll(['Alice', 'Bob', 'Charlie']));
    } finally {
      await harness.dispose();
    }
  });
}
