import 'package:driver_tests/driver_tests.dart';
import 'package:test/test.dart';

void main() {
  group('ModelDefinition', () {
    test('captures table, fields, and codec metadata', () {
      final definition = UserOrmDefinition.definition;

      expect(definition.tableName, 'users');
      expect(definition.fields, hasLength(7));

      final idField = definition.fieldByName('id');
      expect(idField?.isPrimaryKey, isTrue);
      expect(idField?.isNullable, isFalse);

      final profileField = definition.fieldByName('profile');
      expect(profileField?.codecType, 'JsonMapCodec');
      expect(profileField?.isNullable, isTrue);

      expect(definition.metadata.hidden, contains('profile'));
      expect(definition.metadata.fillable, contains('email'));
      expect(definition.metadata.guarded, contains('id'));
      expect(definition.metadata.casts['createdAt'], 'datetime');
    });
  });
}
