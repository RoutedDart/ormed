import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaBuilder document operations', () {
    test('createCollection captures validator and options', () {
      final builder = SchemaBuilder();
      builder.createCollection(
        'users',
        validator: {
          'email': {'\$exists': true},
        },
        options: {'capped': true},
      );
      final plan = builder.build();

      expect(plan.mutations, hasLength(1));
      final mutation = plan.mutations.single;
      expect(mutation.operation, SchemaMutationOperation.createCollection);
      expect(mutation.documentPayload, containsPair('collection', 'users'));
      expect(
        mutation.documentPayload?['validator'],
        equals({
          'email': {'\$exists': true},
        }),
      );
      expect(mutation.documentPayload?['options'], equals({'capped': true}));
    });

    test('createIndex records keys and options', () {
      final builder = SchemaBuilder();
      builder.createIndex(
        collection: 'users',
        keys: {'email': 1},
        options: {'unique': true},
      );
      final plan = builder.build();

      final mutation = plan.mutations.single;
      expect(mutation.operation, SchemaMutationOperation.createIndex);
      expect(mutation.documentPayload, containsPair('collection', 'users'));
      expect(mutation.documentPayload?['keys'], equals({'email': 1}));
      expect(mutation.documentPayload?['options'], equals({'unique': true}));
    });

    test('dropIndex and dropCollection preserve payload', () {
      final builder = SchemaBuilder();
      builder.dropIndex(collection: 'users', name: 'users_email');
      builder.dropCollection('users');
      final plan = builder.build();

      expect(plan.mutations, hasLength(2));
      final dropIndex = plan.mutations.first;
      expect(dropIndex.operation, SchemaMutationOperation.dropIndex);
      expect(dropIndex.documentPayload?['name'], equals('users_email'));

      final dropCollection = plan.mutations.last;
      expect(dropCollection.operation, SchemaMutationOperation.dropCollection);
      expect(dropCollection.documentPayload?['collection'], equals('users'));
    });

    test('modifyValidator carries validator definition', () {
      final builder = SchemaBuilder();
      builder.modifyValidator(
        collection: 'users',
        validator: {
          'email': {'\$type': 'string'},
        },
      );
      final plan = builder.build();

      final mutation = plan.mutations.single;
      expect(mutation.operation, SchemaMutationOperation.modifyValidator);
      expect(
        mutation.documentPayload?['validator'],
        equals({
          'email': {'\$type': 'string'},
        }),
      );
    });

    test('document mutations survive serialization round-trip', () {
      final builder = SchemaBuilder();
      builder.createCollection(
        'emails',
        validator: {
          'domain': {'\$exists': true},
        },
      );
      final plan = builder.build();
      final json = plan.toJson();
      final recreated = SchemaPlan.fromJson(json);

      expect(recreated.mutations, hasLength(1));
      final mutation = recreated.mutations.single;
      expect(mutation.operation, SchemaMutationOperation.createCollection);
      expect(
        mutation.documentPayload?['validator'],
        equals({
          'domain': {'\$exists': true},
        }),
      );
    });
  });
}
