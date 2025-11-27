import '../lib/src/commands/schema_command.dart';
import '../../driver_tests/lib/driver_tests.dart';
import '../../ormed_mongo/test/support/mongo_harness.dart';
import 'package:test/test.dart';

void main() {
  late MongoTestHarness harness;

  setUpAll(() async {
    harness = await MongoTestHarness.create();
    await seedGraph(harness);
  });

  tearDownAll(() async {
    await harness.dispose();
  });

  test('schema metadata includes Mongo collections', () async {
    final metadata = await schemaMetadata(harness.adapter);
    expect(metadata, isNotEmpty);
    final posts = metadata.cast<Map<String, Object?>>().firstWhere(
      (table) => table['name'] == 'posts',
      orElse: () => <String, Object?>{},
    );
    expect(posts['indexCount'], isNotNull);
  });
}
