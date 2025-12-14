import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

/// This test verifies that code generation works correctly with TypeMapper.
/// 
/// The key insight: Generated code uses `registry.encodeField()` and 
/// `registry.decodeField()` which automatically use TypeMapper-registered
/// codecs at runtime based on the driver context.
///
/// Generated model codecs do NOT hardcode specific codecs. Instead they delegate:
///   [registry.encodeField(fieldDef, value)]  →  uses [TypeMapper ]codec
///   [registry.decodeField<T>(fieldDef, data)] →  uses [TypeMapper] codec
void main() {
  group('Code Generation with TypeMapper Integration', () {
    setUpAll(() {
      SqliteDriverAdapter.registerCodecs();
    });

    test('ValueCodecRegistry uses TypeMapper codecs for SQLite bool', () {
      final registry = ValueCodecRegistry.instance.forDriver('sqlite');
      
      // Test bool codec (SQLite stores as INTEGER)
      final boolField = FieldDefinition(
        name: 'active',
        columnName: 'active',
        dartType: 'bool',
        resolvedType: 'bool',
        isPrimaryKey: false,
        isNullable: false,
      );
      
      // Encode: bool → int (what SQLite expects)
      final encoded = registry.encodeField(boolField, true);
      expect(encoded, equals(1));
      expect(registry.encodeField(boolField, false), equals(0));
      
      // Decode: int → bool (what Dart model expects)
      expect(registry.decodeField<bool>(boolField, 1), equals(true));
      expect(registry.decodeField<bool>(boolField, 0), equals(false));
    });

    test('ValueCodecRegistry uses TypeMapper codecs for SQLite DateTime', () {
      final registry = ValueCodecRegistry.instance.forDriver('sqlite');
      
      final dateField = FieldDefinition(
        name: 'created_at',
        columnName: 'created_at',
        dartType: 'DateTime',
        resolvedType: 'DateTime',
        isPrimaryKey: false,
        isNullable: false,
      );
      
      final testDate = DateTime.utc(2024, 1, 1, 12, 30);
      
      // Encode: DateTime → ISO 8601 String (what SQLite expects)
      final encoded = registry.encodeField(dateField, testDate);
      expect(encoded, isA<String>());
      expect(encoded, contains('2024-01-01'));
      
      // Decode: String → DateTime (what Dart model expects)
      final decoded = registry.decodeField<DateTime>(dateField, encoded);
      expect(decoded, isA<DateTime>());
      expect(decoded!.year, equals(2024));
      expect(decoded.month, equals(1));
      expect(decoded.day, equals(1));
    });

    test('Generated code pattern mimics actual code generator output', () {
      // This mimics what ModelCodecEmitter generates:
      //   registry.encodeField(field, value)
      //   registry.decodeField<T>(field, data)
      
      final registry = ValueCodecRegistry.instance.forDriver('sqlite');
      
      final idField = FieldDefinition(
        name: 'id',
        columnName: 'id',
        dartType: 'int',
        resolvedType: 'int',
        isPrimaryKey: true,
        isNullable: false,
      );
      
      final nameField = FieldDefinition(
        name: 'name',
        columnName: 'name',
        dartType: 'String',
        resolvedType: 'String',
        isPrimaryKey: false,
        isNullable: false,
      );
      
      final activeField = FieldDefinition(
        name: 'active',
        columnName: 'active',
        dartType: 'bool',
        resolvedType: 'bool',
        isPrimaryKey: false,
        isNullable: false,
      );
      
      final createdAtField = FieldDefinition(
        name: 'createdAt',
        columnName: 'created_at',
        dartType: 'DateTime',
        resolvedType: 'DateTime',
        isPrimaryKey: false,
        isNullable: false,
      );
      
      // === ENCODE (for INSERT) ===
      // This is what generated codec's encode() method does
      final testDate = DateTime.utc(2024, 6, 15);
      final encoded = <String, Object?>{
        'id': registry.encodeField(idField, 1),
        'name': registry.encodeField(nameField, 'Alice'),
        'active': registry.encodeField(activeField, true),
        'created_at': registry.encodeField(createdAtField, testDate),
      };
      
      // Verify encoding worked correctly
      expect(encoded['id'], equals(1));
      expect(encoded['name'], equals('Alice'));
      expect(encoded['active'], equals(1)); // bool → int for SQLite
      expect(encoded['created_at'], isA<String>()); // DateTime → String for SQLite
      expect(encoded['created_at'], contains('2024-06-15'));
      
      // === DECODE (for SELECT) ===
      // This is what generated codec's decode() method does
      // Simulates data coming back from SQLite
      final rawData = <String, Object?>{
        'id': 1,
        'name': 'Alice',
        'active': 1, // SQLite returns int for bool
        'created_at': '2024-06-15T00:00:00.000Z', // SQLite returns String for DateTime
      };
      
      final id = registry.decodeField<int>(idField, rawData['id']);
      final name = registry.decodeField<String>(nameField, rawData['name']);
      final active = registry.decodeField<bool>(activeField, rawData['active']);
      final createdAt = registry.decodeField<DateTime>(createdAtField, rawData['created_at']);
      
      // Verify decoding worked correctly
      expect(id, equals(1));
      expect(name, equals('Alice'));
      expect(active, equals(true)); // int → bool
      expect(createdAt, isA<DateTime>()); // String → DateTime
      expect(createdAt!.year, equals(2024));
      expect(createdAt.month, equals(6));
      expect(createdAt.day, equals(15));
    });

    test('Nullable fields work correctly with TypeMapper codecs', () {
      final registry = ValueCodecRegistry.instance.forDriver('sqlite');
      
      final nullableBoolField = FieldDefinition(
        name: 'optionalFlag',
        columnName: 'optional_flag',
        dartType: 'bool?',
        resolvedType: 'bool?',
        isPrimaryKey: false,
        isNullable: true,
      );
      
      // Encode null
      expect(registry.encodeField(nullableBoolField, null), isNull);
      
      // Decode null
      expect(registry.decodeField<bool?>(nullableBoolField, null), isNull);
      
      // Encode/decode non-null values
      expect(registry.encodeField(nullableBoolField, true), equals(1));
      expect(registry.decodeField<bool?>(nullableBoolField, 1), equals(true));
    });

    test('TypeMapper integration eliminates codec mismatch errors', () {
      // This test demonstrates the problem that TypeMapper integration solves
      
      final registry = ValueCodecRegistry.instance.forDriver('sqlite');
      
      final boolField = FieldDefinition(
        name: 'active',
        columnName: 'active',
        dartType: 'bool',
        resolvedType: 'bool',
        isPrimaryKey: false,
        isNullable: false,
      );
      
      // Before TypeMapper integration, this would cause:
      //   type 'int' is not a subtype of type 'bool'
      // Because SQLite returns int (1 or 0) but Dart expects bool
      
      // With TypeMapper integration, the codec handles the conversion
      final rawSqliteValue = 1; // SQLite stores bool as INTEGER
      final dartValue = registry.decodeField<bool>(boolField, rawSqliteValue);
      
      // No error! Codec correctly converts int → bool
      expect(dartValue, isA<bool>());
      expect(dartValue, equals(true));
    });
  });
}
