import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaBuilder database management', () {
    test('emits create/drop database mutations', () {
      final builder = SchemaBuilder();

      builder.createDatabase('db_one', options: {'charset': 'utf8mb4'});
      builder.dropDatabase('db_two');
      builder.dropDatabaseIfExists('db_three');

      final plan = builder.build();
      expect(plan.mutations.length, equals(3));

      final create = plan.mutations[0];
      expect(create.operation, SchemaMutationOperation.createDatabase);
      expect(create.documentPayload?['name'], equals('db_one'));
      expect(
        create.documentPayload?['options'],
        equals({'charset': 'utf8mb4'}),
      );

      final drop = plan.mutations[1];
      expect(drop.operation, SchemaMutationOperation.dropDatabase);
      expect(drop.documentPayload?['name'], equals('db_two'));
      expect(drop.documentPayload?['ifExists'], isFalse);

      final dropIfExists = plan.mutations[2];
      expect(dropIfExists.operation, SchemaMutationOperation.dropDatabase);
      expect(dropIfExists.documentPayload?['name'], equals('db_three'));
      expect(dropIfExists.documentPayload?['ifExists'], isTrue);
    });
  });
}
