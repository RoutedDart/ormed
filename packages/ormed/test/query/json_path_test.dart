import 'package:ormed/json_path.dart';
import 'package:ormed/ormed.dart'
    show JsonUpdateDefinition, Model, ModelAttributes;
import 'package:test/test.dart';

void main() {
  group('JSON path normalization', () {
    test('normalizeJsonPath canonicalizes simple properties', () {
      expect(normalizeJsonPath('mode'), equals(r'$.mode'));
      expect(normalizeJsonPath(r'$.mode'), equals(r'$.mode'));
      expect(normalizeJsonPath('meta.count'), equals(r'$.meta.count'));
    });

    test('normalizeJsonPath preserves array indexes', () {
      expect(normalizeJsonPath(r'$.items[0].id'), equals(r'$.items[0].id'));
      expect(normalizeJsonPath('[0].id'), equals(r'$[0].id'));
      expect(normalizeJsonPath(r'$.items.0.id'), equals(r'$.items[0].id'));
      expect(normalizeJsonPath(r'$.items.12.id'), equals(r'$.items[12].id'));
    });

    test('normalizeJsonPath quotes non-simple property names', () {
      expect(
        normalizeJsonPath(r'$.meta["weird key"]'),
        equals(r'$.meta["weird key"]'),
      );
      expect(
        normalizeJsonPath(r"meta['weird key']"),
        equals(r'$.meta["weird key"]'),
      );
    });

    test('normalizeJsonPath treats dotted numeric segments as indexes', () {
      expect(normalizeJsonPath(r'$.items.01.id'), equals(r'$.items.01.id'));
      expect(normalizeJsonPath(r'$.items["0"].id'), equals(r'$.items["0"].id'));
    });
  });

  group('JSON selector parsing', () {
    test(
      'parseJsonSelectorExpression returns null without selector operator',
      () {
        expect(parseJsonSelectorExpression('metadata'), isNull);
        expect(parseJsonSelectorExpression('metadata.mode'), isNull);
      },
    );

    test(r'parses -> and normalizes missing $. prefix', () {
      final selector = parseJsonSelectorExpression('metadata->mode')!;
      expect(selector.column, equals('metadata'));
      expect(selector.path, equals(r'$.mode'));
      expect(selector.extractsText, isFalse);
    });

    test('parses ->> as text extraction', () {
      final selector = parseJsonSelectorExpression('metadata->>mode')!;
      expect(selector.column, equals('metadata'));
      expect(selector.path, equals(r'$.mode'));
      expect(selector.extractsText, isTrue);
    });

    test(r'parses selector paths with dotted array index segments', () {
      final selector = parseJsonSelectorExpression('metadata->items.0.id')!;
      expect(selector.column, equals('metadata'));
      expect(selector.path, equals(r'$.items[0].id'));
    });

    test(r'accepts explicit $. paths', () {
      final selector = parseJsonSelectorExpression(r'metadata->>$.meta.count')!;
      expect(selector.column, equals('metadata'));
      expect(selector.path, equals(r'$.meta.count'));
      expect(selector.extractsText, isTrue);
    });
  });

  group('JsonUpdateDefinition.selector', () {
    test(r'normalizes selector paths without $. prefix', () {
      final def = JsonUpdateDefinition.selector('payload->mode', 'light');
      expect(def.fieldOrColumn, equals('payload'));
      expect(def.path, equals(r'$.mode'));
      expect(def.value, equals('light'));
    });

    test(r'accepts ->> selectors (text extraction) for path parsing', () {
      final def = JsonUpdateDefinition.selector('payload->>mode', 'light');
      expect(def.fieldOrColumn, equals('payload'));
      expect(def.path, equals(r'$.mode'));
    });
  });

  group('Model.jsonSet queueing', () {
    test(r'queues JSON updates using selector parsing', () {
      final model = _JsonQueueModel();
      model.jsonSet('metadata->mode', 'light');

      final queued = (model as ModelAttributes).takeJsonAttributeUpdates();
      expect(queued, hasLength(1));
      final update = queued.single;
      expect(update.fieldOrColumn, equals('metadata'));
      expect(update.path, equals(r'$.mode'));
      expect(update.value, equals('light'));
      expect(update.patch, isFalse);
    });
  });

  group('JSON path segments', () {
    test('splits normalized json paths into segments', () {
      expect(jsonPathSegments(r'$.meta.count'), equals(['meta', 'count']));
      expect(jsonPathSegments(r'$[0].id'), equals(['0', 'id']));
    });
  });
}

class _JsonQueueModel extends Model<_JsonQueueModel> with ModelAttributes {
  const _JsonQueueModel();
}
