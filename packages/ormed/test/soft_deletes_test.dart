import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import 'models/custom_soft_delete.dart';

void main() {
  group('SoftDeletes mixin', () {
    late ValueCodecRegistry registry;

    setUp(() {
      registry = ValueCodecRegistry.standard();
    });

    test('uses custom column overrides from metadata', () {
      final definition = CustomSoftDeleteOrmDefinition.definition;
      final removedOn = DateTime.utc(2024, 2, 10, 12, 30);

      final model = definition.fromMap({
        'id': 42,
        'title': 'Archived',
        'removed_on': removedOn,
      }, registry: registry);

      expect(model.deletedAt, equals(removedOn));
      final attrs = model as ModelAttributes;
      expect(attrs.getAttribute<DateTime?>('removed_on'), equals(removedOn));
      expect(attrs.getSoftDeleteColumn(), equals('removed_on'));
    });
  });
}
