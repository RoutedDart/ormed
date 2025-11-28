import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

// Test model for unit testing ModelRelations
// Model already has ModelRelations, no need to add it again
class TestModel extends Model<TestModel> {
  const TestModel({required this.id, required this.name});
  
  final int id;
  final String name;
}

void main() {
  group('ModelRelations mixin', () {
    test('setRelation and getRelation work correctly', () {
      final model = const TestModel(id: 1, name: 'Test');
      
      expect(model.getRelation<String>('title'), isNull);
      expect(model.relationLoaded('title'), isFalse);
      
      model.setRelation('title', 'Hello World');
      
      expect(model.relationLoaded('title'), isTrue);
      expect(model.getRelation<String>('title'), equals('Hello World'));
    });

    test('getRelationList returns empty list when not loaded', () {
      final model = const TestModel(id: 1, name: 'Test');
      
      expect(model.getRelationList<String>('items'), isEmpty);
      expect(model.relationLoaded('items'), isFalse);
    });

    test('getRelationList returns cached list when loaded', () {
      final model = const TestModel(id: 1, name: 'Test');
      
      final items = ['item1', 'item2', 'item3'];
      
      model.setRelation('items', items);
      
      final retrieved = model.getRelationList<String>('items');
      expect(retrieved, hasLength(3));
      expect(retrieved.first, equals('item1'));
    });

    test('unsetRelation clears data and loaded flag', () {
      final model = const TestModel(id: 1, name: 'Test');
      
      final items = ['item1', 'item2'];
      
      model.setRelation('items', items);
      expect(model.relationLoaded('items'), isTrue);
      
      model.unsetRelation('items');
      expect(model.relationLoaded('items'), isFalse);
      expect(model.getRelation<List<String>>('items'), isNull);
    });

    test('setRelations bulk sets multiple relations', () {
      final model = const TestModel(id: 1, name: 'Test');
      
      model.setRelations({
        'items': ['item1', 'item2'],
        'featured': 'item1',
      });
      
      expect(model.relationLoaded('items'), isTrue);
      expect(model.relationLoaded('featured'), isTrue);
      expect(model.getRelationList<String>('items'), hasLength(2));
      expect(model.getRelation<String>('featured'), equals('item1'));
    });

    test('loadedRelations returns snapshot of all loaded relations', () {
      final model = TestModel(id: 42, name: 'Snapshot');
      
      expect(model.loadedRelations, isEmpty);
      
      final items = ['item1', 'item2'];
      
      model.setRelation('items', items);
      
      final loaded = model.loadedRelations;
      expect(loaded, hasLength(1));
      expect(loaded.containsKey('items'), isTrue);
      expect(loaded['items'], equals(items));
    });

    test('clearRelations removes all cached relations', () {
      final model = TestModel(id: 99, name: 'Clear');
      
      model.setRelations({
        'items': ['item1', 'item2'],
        'featured': 'item1',
      });
      
      expect(model.loadedRelationNames, hasLength(2));
      
      model.clearRelations();
      
      expect(model.loadedRelationNames, isEmpty);
      expect(model.relationLoaded('items'), isFalse);
      expect(model.relationLoaded('featured'), isFalse);
    });
  });

  group('syncRelationsFromQueryRow', () {
    test('syncs relations from QueryRow map', () {
      final model = TestModel(id: 55, name: 'Sync');
      
      final rowRelations = {
        'items': ['item1', 'item2'],
        'featured': 'item1',
      };
      
      model.syncRelationsFromQueryRow(rowRelations);
      
      expect(model.relationLoaded('items'), isTrue);
      expect(model.relationLoaded('featured'), isTrue);
      expect(model.getRelationList<String>('items'), hasLength(2));
      expect(model.getRelation<String>('featured'), equals('item1'));
    });

    test('handles empty relation map', () {
      final model = TestModel(id: 77, name: 'Empty');
      
      model.syncRelationsFromQueryRow({});
      
      expect(model.loadedRelationNames, isEmpty);
    });
  });

  group('Lazy loading prevention', () {
    setUp(() {
      ModelRelations.preventsLazyLoading = false;
    });

    tearDown(() {
      ModelRelations.preventsLazyLoading = false;
    });

    test('preventsLazyLoading can be toggled', () {
      expect(ModelRelations.preventsLazyLoading, isFalse);
      
      ModelRelations.preventsLazyLoading = true;
      expect(ModelRelations.preventsLazyLoading, isTrue);
      
      ModelRelations.preventsLazyLoading = false;
      expect(ModelRelations.preventsLazyLoading, isFalse);
    });
  });
}
