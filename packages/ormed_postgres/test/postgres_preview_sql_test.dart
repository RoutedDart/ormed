import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:test/test.dart';

void main() {
  test('ad-hoc inserts keep write fields out of returning projection', () {
    final adapter = PostgresDriverAdapter.custom(
      config: const DatabaseConfig(driver: 'postgres'),
    );
    final definition = AdHocModelDefinition(tableName: 'users');
    final plan = MutationPlan.insert(
      definition: definition,
      rows: const [
        <String, Object?>{'name': 'Carol'},
      ],
      returning: true,
    );

    final preview = adapter.describeMutation(plan);
    final payload = preview.payload as SqlStatementPayload;
    expect(payload.sql, contains('INSERT INTO "users" ("name")'));
    expect(payload.sql, contains('RETURNING *'));
    expect(plan.mutationFields.map((field) => field.columnName), ['name']);
    expect(definition.fields, isEmpty);
  });

  test('preview SQL ignores placeholders inside string literals', () {
    final adapter = PostgresDriverAdapter.custom(
      config: const DatabaseConfig(driver: 'postgres'),
    );
    final definition = AdHocModelDefinition(
      tableName: 'articles',
      columns: const [
        AdHocColumn(name: 'id', columnName: 'id', isPrimaryKey: true),
      ],
    );
    final plan = QueryPlan(
      definition: definition,
      rawSelects: [
        RawSelectExpression(
          sql: "CASE WHEN '?' = '?' THEN 1 ELSE 0 END",
          alias: 'flag',
        ),
      ],
      filters: const [
        FilterClause(field: 'id', operator: FilterOperator.equals, value: 1),
      ],
    );

    final preview = adapter.describeQuery(plan);
    final payload = preview.payload as SqlStatementPayload;
    expect(payload.sql, contains("'?'"));
    expect(payload.sql, contains(r'$1'));
  });
}
