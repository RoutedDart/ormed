/// Verifies encoding and decoding for the built-in codec registry entries.
library;

import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  group('ValueCodecRegistry default codecs', () {
    for (final testCase in _codecCases) {
      test('encodes and decodes ${testCase.label}', () {
        final registry = ValueCodecRegistry.standard();
        final field = _field(
          dartType: testCase.codecKey,
          resolvedType: testCase.resolvedType,
          isNullable: testCase.isNullable,
        );

        final encoded = registry.encodeField(field, testCase.value);
        expect(encoded, equals(testCase.value));

        final decoded = registry.decodeField<dynamic>(field, encoded);
        expect(decoded, equals(testCase.value));
      });
    }
  });

  group('ValueCodecRegistry custom codecs', () {
    test('throws when codec missing', () {
      final registry = ValueCodecRegistry.standard();
      final field = _field(dartType: 'NonExisting', resolvedType: 'Object');

      expect(
        () => registry.encodeField(field, 'value'),
        throwsA(isA<CodecNotFound>()),
      );
    });

    test('registerCodecFor wires custom codec by Type name', () {
      final registry = ValueCodecRegistry.standard();
      registry.registerCodecFor(_UpperCaseCodec, const _UpperCaseCodec());

      final field = _field(
        dartType: 'String',
        resolvedType: 'String',
        codecType: '_UpperCaseCodec',
      );

      final encoded = registry.encodeField(field, 'hello');
      expect(encoded, 'HELLO');

      final decoded = registry.decodeField<String>(field, 'world');
      expect(decoded, 'world'.toLowerCase());
    });
  });

  group('ValueCodecRegistry driver-specific overlays', () {
    final field = _field(dartType: 'String', resolvedType: 'String');

    test('registers overlays without affecting base registry', () {
      final registry = ValueCodecRegistry.standard();
      final postgresView = registry.forDriver('postgres');
      postgresView.registerCodec(key: 'String', codec: const _UpperCaseCodec());

      expect(postgresView.encodeField(field, 'test'), equals('TEST'));
      expect(registry.encodeField(field, 'test'), equals('test'));
    });

    test('fork retains driver overlays', () {
      final registry = ValueCodecRegistry.standard();
      registry
          .forDriver('postgres')
          .registerCodec(key: 'String', codec: const _UpperCaseCodec());

      final forked = registry.fork();
      final driverView = forked.forDriver('postgres');
      expect(driverView.encodeField(field, 'fork'), equals('FORK'));
    });

    test('query context injects driver-specific registry views', () {
      final baseRegistry = ValueCodecRegistry.standard();
      baseRegistry
          .forDriver('postgres')
          .registerCodec(key: 'String', codec: const _UpperCaseCodec());
      baseRegistry
          .forDriver('sqlite')
          .registerCodec(key: 'String', codec: const _SuffixCodec('-sqlite'));

      final modelRegistry = ModelRegistry();
      final pgDriver = _PostgresMemoryDriver(registry: baseRegistry.fork());
      final sqliteDriver = _SqliteMemoryDriver(registry: baseRegistry.fork());

      final pgContext = QueryContext(registry: modelRegistry, driver: pgDriver);
      final sqliteContext = QueryContext(
        registry: modelRegistry,
        driver: sqliteDriver,
      );

      expect(pgContext.codecRegistry.encodeField(field, 'hello'), 'HELLO');
      expect(
        sqliteContext.codecRegistry.encodeField(field, 'hello'),
        'hello-sqlite',
      );
    });
  });

  group('Field driver override lookups', () {
    test('prefers driver-specific codec type when available', () {
      final registry = ValueCodecRegistry.standard();
      registry.registerCodec(
        key: 'BaseCodec',
        codec: const _SuffixCodec('-base'),
      );
      final driverView = registry.forDriver('postgres');
      driverView.registerCodec(
        key: 'PgCodec',
        codec: const _SuffixCodec('-pg'),
      );

      final field = _field(
        dartType: 'String',
        resolvedType: 'String',
        codecType: 'BaseCodec',
        driverOverrides: const {
          'postgres': FieldDriverOverride(codecType: 'PgCodec'),
        },
      );

      expect(driverView.encodeField(field, 'value'), 'value-pg');
      expect(registry.encodeField(field, 'value'), 'value-base');
    });
  });
}

class _CodecCase {
  const _CodecCase(
    this.codecKey,
    this.value, {
    required this.label,
    String? resolvedType,
    this.isNullable = false,
  }) : resolvedType = resolvedType ?? codecKey;

  final String codecKey;
  final Object? value;
  final String resolvedType;
  final bool isNullable;
  final String label;
}

final _codecCases = <_CodecCase>[
  const _CodecCase('Object', 'plain', label: 'Object'),
  const _CodecCase('Object?', null, label: 'Object?', isNullable: true),
  const _CodecCase('String', 'text', label: 'String'),
  const _CodecCase('int', 42, label: 'int'),
  const _CodecCase('double', 3.14, label: 'double'),
  const _CodecCase('num', 9.5, label: 'num'),
  const _CodecCase('bool', true, label: 'bool'),
  _CodecCase('DateTime', DateTime.utc(2025, 1, 1, 12, 0), label: 'DateTime'),
  _CodecCase(
    'Map<String, Object?>',
    <String, Object?>{'a': 1, 'b': null},
    label: 'Map<String, Object?>',
    resolvedType: 'Map<String, Object?>?',
    isNullable: true,
  ),
  _CodecCase(
    'Map<String, dynamic>',
    <String, dynamic>{'a': 1, 'b': []},
    label: 'Map<String, dynamic>',
    resolvedType: 'Map<String, dynamic>?',
    isNullable: true,
  ),
  _CodecCase(
    'List<Object?>',
    <Object?>['a', 2, true],
    label: 'List<Object?>',
    resolvedType: 'List<Object?>?',
    isNullable: true,
  ),
  _CodecCase(
    'List<dynamic>',
    <dynamic>['a', 2, true],
    label: 'List<dynamic>',
    resolvedType: 'List<dynamic>?',
    isNullable: true,
  ),
];

FieldDefinition _field({
  required String dartType,
  required String resolvedType,
  bool isNullable = false,
  String? codecType,
  Map<String, FieldDriverOverride> driverOverrides =
      const <String, FieldDriverOverride>{},
}) => FieldDefinition(
  name: 'value',
  columnName: 'value',
  dartType: dartType,
  resolvedType: resolvedType,
  isPrimaryKey: false,
  isNullable: isNullable,
  codecType: codecType,
  driverOverrides: driverOverrides,
);

class _UpperCaseCodec extends ValueCodec<String> {
  const _UpperCaseCodec();

  @override
  Object? encode(String? value) => value?.toUpperCase();

  @override
  String? decode(Object? value) => (value as String?)?.toLowerCase();
}

class _SuffixCodec extends ValueCodec<String> {
  const _SuffixCodec(this._suffix);

  final String _suffix;

  @override
  Object? encode(String? value) => value == null ? null : '$value$_suffix';

  @override
  String? decode(Object? value) {
    final casted = value as String?;
    if (casted == null) return null;
    if (casted.endsWith(_suffix)) {
      return casted.substring(0, casted.length - _suffix.length);
    }
    return casted;
  }
}

class _PostgresMemoryDriver extends InMemoryQueryExecutor {
  _PostgresMemoryDriver({required ValueCodecRegistry registry})
    : super(codecRegistry: registry);

  @override
  DriverMetadata get metadata =>
      const DriverMetadata(name: 'postgres', supportsReturning: true);
}

class _SqliteMemoryDriver extends InMemoryQueryExecutor {
  _SqliteMemoryDriver({required ValueCodecRegistry registry})
    : super(codecRegistry: registry);

  @override
  DriverMetadata get metadata => const DriverMetadata(name: 'sqlite');
}
