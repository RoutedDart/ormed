import 'package:ormed/ormed.dart';
import 'package:ormed_mongo/ormed_mongo.dart';
import 'package:ormed_mongo/src/mongo_schema_dialect.dart';
import 'package:test/test.dart';

void main() {
  test('mongo driver metadata', () async {
    final adapter = MongoDriverAdapter.custom(
      config: const DatabaseConfig(
        driver: 'mongo',
        options: {'database': 'orm_test'},
      ),
    );
    addTearDown(() async => await adapter.close());
    expect(adapter.metadata.name, 'mongo');
  });

  group('plan compiler', () {
    const compiler = MongoPlanCompiler();
    test('builds find payload with filters, sort, and pagination', () {
      final plan = QueryPlan(
        definition: AdHocModelDefinition(tableName: 'users'),
        filters: [
          const FilterClause(
            field: 'active',
            operator: FilterOperator.equals,
            value: true,
          ),
          const FilterClause(
            field: 'age',
            operator: FilterOperator.greaterThan,
            value: 18,
          ),
        ],
        orders: const [OrderClause(field: 'createdAt', descending: true)],
        limit: 5,
        offset: 10,
      );
      final preview = compiler.compileSelect(plan);
      final payload = preview.payload as DocumentStatementPayload;
      expect(payload.command, 'find');
      final args = payload.arguments;
      expect(args['filter'], containsPair('active', true));
      final ageFilter = (args['filter'] as Map<String, Object?>)['age']!;
      expect(ageFilter, containsPair('\$gt', 18));
      expect(args['sort'], containsPair('createdAt', -1));
      expect(args['limit'], equals(5));
      expect(args['skip'], equals(10));
    });

    test('maps insert plans to insertMany command', () {
      final plan = MutationPlan.insert(
        definition: AdHocModelDefinition(tableName: 'users'),
        rows: const [
          {'name': 'alfred', 'active': true},
          {'name': 'bob', 'active': false},
        ],
      );
      final preview = compiler.compileMutation(plan);
      final payload = preview.payload as DocumentStatementPayload;
      expect(payload.command, 'insertMany');
      expect(payload.arguments['documents'], hasLength(2));
    });

    test('returns unsupported command for other mutations', () {
      final plan = MutationPlan.delete(
        definition: AdHocModelDefinition(tableName: 'users'),
        rows: const [],
      );
      final preview = compiler.compileMutation(plan);
      final payload = preview.payload as DocumentStatementPayload;
      expect(payload.command, 'unsupported');
    });
  });

  group('schema dialect', () {
    final compiler = SchemaPlanCompiler(const MongoSchemaDialect());
    test('createCollection produces document payload', () {
      final plan = SchemaPlan(
        mutations: [
          SchemaMutation.createCollection(
            collection: 'users',
            validator: {
              'email': {'\$exists': true},
            },
          ),
        ],
      );
      final preview = compiler.compile(plan);
      final payload =
          preview.statements.single.payload as DocumentStatementPayload;
      expect(payload.command, 'createCollection');
      expect(payload.arguments['collection'], 'users');
    });

    test('createIndex exposes keys and options', () {
      final plan = SchemaPlan(
        mutations: [
          SchemaMutation.createIndex(
            collection: 'users',
            keys: {'email': 1},
            options: {'unique': true},
          ),
        ],
      );
      final payload =
          compiler.compile(plan).statements.single.payload
              as DocumentStatementPayload;
      expect(payload.command, 'createIndex');
      expect(payload.arguments['keys'], equals({'email': 1}));
      expect(payload.arguments['options'], equals({'unique': true}));
    });

    test('dropIndex and dropCollection are emitted sequentially', () {
      final plan = SchemaPlan(
        mutations: [
          SchemaMutation.dropIndex(collection: 'users', name: 'users_email'),
          SchemaMutation.dropCollection(collection: 'users'),
        ],
      );
      final statements = compiler.compile(plan).statements;
      final dropIndexPayload =
          statements.first.payload as DocumentStatementPayload;
      final dropCollectionPayload =
          statements.last.payload as DocumentStatementPayload;

      expect(dropIndexPayload.command, 'dropIndex');
      expect(dropIndexPayload.arguments['name'], 'users_email');
      expect(dropCollectionPayload.command, 'dropCollection');
      expect(dropCollectionPayload.arguments['collection'], 'users');
    });

    test('modifyValidator surfaces validator definition', () {
      final plan = SchemaPlan(
        mutations: [
          SchemaMutation.modifyValidator(
            collection: 'users',
            validator: {
              'email': {'\$type': 'string'},
            },
          ),
        ],
      );
      final payload =
          compiler.compile(plan).statements.single.payload
              as DocumentStatementPayload;
      expect(payload.command, 'modifyValidator');
      expect(
        payload.arguments['validator'],
        equals({
          'email': {'\$type': 'string'},
        }),
      );
    });
  });
}
