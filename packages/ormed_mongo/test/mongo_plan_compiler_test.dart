import 'package:ormed/ormed.dart';
import 'package:ormed_mongo/ormed_mongo.dart';
import 'package:test/test.dart';

void main() {
  group('MongoPlanCompiler filters', () {
    test('contains filters emit \$regex selectors', () {
      final filter = MongoPlanCompiler.buildFilter(const [
        FilterClause(
          field: 'name',
          operator: FilterOperator.contains,
          value: 'widget',
        ),
      ]);

      expect(
        filter,
        equals({
          'name': {'\$regex': 'widget'},
        }),
      );
    });

    test('isNull filters check for null values', () {
      final filter = MongoPlanCompiler.buildFilter(const [
        FilterClause(
          field: 'description',
          operator: FilterOperator.isNull,
          value: null,
        ),
      ]);

      expect(
        filter,
        anyOf(
          equals({'description': null}),
          equals({
            'description': {'\$eq': null},
          }),
        ),
      );
    });

    test('isNotNull filters ensure existing values', () {
      final filter = MongoPlanCompiler.buildFilter(const [
        FilterClause(
          field: 'price',
          operator: FilterOperator.isNotNull,
          value: null,
        ),
      ]);

      expect(
        filter,
        equals({
          'price': {'\$ne': null},
        }),
      );
    });
  });
}
