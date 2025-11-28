import 'dart:convert';

import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  group('Model attribute helpers', () {
    late _SimpleModel model;

    setUp(() {
      model = _SimpleModel();
    });

    test('fill honors global metadata and field overrides', () {
      final metadata = ModelAttributesMetadata(
        fillable: const ['email', 'name'],
        guarded: const ['id'],
        fieldOverrides: const {'role': FieldAttributeMetadata(fillable: true)},
      );
      model.attachModelDefinition(_definitionWith(metadata));

      model.fill({
        'id': 1,
        'email': 'user@example.com',
        'role': 'editor',
        'extra': 'ignored',
      }, strict: false);

      expect(model.getAttribute('email'), 'user@example.com');
      expect(model.getAttribute('role'), 'editor');
      expect(model.getAttribute('id'), isNull);
      expect(model.attributes.containsKey('extra'), isFalse);
    });

    test('fill throws when extra attributes exist in strict mode', () {
      final metadata = ModelAttributesMetadata(fillable: const ['email']);
      model.attachModelDefinition(_definitionWith(metadata));

      expect(
        () => model.fill({'password': 'secret'}),
        throwsA(isA<MassAssignmentException>()),
      );
    });

    test('forceFill bypasses guards', () {
      final metadata = ModelAttributesMetadata(guarded: const ['role']);
      model.attachModelDefinition(_definitionWith(metadata));

      model.forceFill({'role': 'admin'});

      expect(model.getAttribute('role'), 'admin');
    });

    test('fillIfAbsent only assigns missing entries', () {
      final metadata = ModelAttributesMetadata(
        fillable: const ['email', 'name'],
      );
      model.attachModelDefinition(_definitionWith(metadata));
      model.setAttribute('email', 'existing@example.com');

      model.fillIfAbsent({'email': 'new@example.com', 'name': 'New'});

      expect(model.getAttribute('email'), 'existing@example.com');
      expect(model.getAttribute('name'), 'New');
    });

    test('serializableAttributes respects hidden/visible metadata', () {
      final metadata = ModelAttributesMetadata(
        hidden: const ['password'],
        visible: const ['password'],
      );
      model.attachModelDefinition(_definitionWith(metadata));
      model.setAttribute('password', 'secret');
      model.setAttribute('email', 'user@example.com');

      final payload = model.toArray();
      expect(payload.containsKey('password'), isFalse);
      expect(payload['email'], 'user@example.com');

      final visiblePayload = model.toArray(includeHidden: true);
      expect(visiblePayload['password'], 'secret');
    });

    test('casts map drives fill and serialization', () {
      final metadata = ModelAttributesMetadata(
        casts: const {'profile': 'json'},
      );
      model.attachModelDefinition(_definitionWith(metadata));
      final registry = ValueCodecRegistry.standard();
      registry.registerCodec(key: 'json', codec: _JsonCodec());

      model.fill({'profile': '{"bio":"x"}'}, registry: registry);
      expect(model.getAttribute('profile'), isA<Map<String, Object?>>());

      final payload = model.toArray(registry: registry);
      expect(payload['profile'], isA<String>());
    });

    test('map extension filters attributes', () {
      final metadata = ModelAttributesMetadata(fillable: const ['email']);
      final filtered = <String, Object?>{
        'email': 'x',
        'password': 'secret',
      }.filteredByAttributes(metadata, _simpleFields, strict: false);

      expect(filtered.keys, contains('email'));
      expect(filtered.keys, isNot(contains('password')));
    });
  });
}

class _SimpleModel extends Model<_SimpleModel> {
  _SimpleModel();
}

class _SimpleModelCodec extends ModelCodec<_SimpleModel> {
  const _SimpleModelCodec();

  @override
  Map<String, Object?> encode(
    _SimpleModel model,
    ValueCodecRegistry registry,
  ) => Map<String, Object?>.from(model.attributes);

  @override
  _SimpleModel decode(Map<String, Object?> data, ValueCodecRegistry registry) {
    final model = _SimpleModel();
    model.replaceAttributes(data);
    model.attachModelDefinition(
      _definitionWith(const ModelAttributesMetadata()),
    );
    return model;
  }
}

ModelDefinition<_SimpleModel> _definitionWith(
  ModelAttributesMetadata metadata,
) {
  return ModelDefinition<_SimpleModel>(
    modelName: '_SimpleModel',
    tableName: 'simple_models',
    fields: _simpleFields,
    codec: const _SimpleModelCodec(),
    metadata: metadata,
  );
}

const _simpleFields = <FieldDefinition>[
  FieldDefinition(
    name: 'id',
    columnName: 'id',
    dartType: 'int',
    resolvedType: 'int',
    isPrimaryKey: true,
    isNullable: false,
  ),
  FieldDefinition(
    name: 'email',
    columnName: 'email',
    dartType: 'String',
    resolvedType: 'String',
    isPrimaryKey: false,
    isNullable: false,
  ),
  FieldDefinition(
    name: 'password',
    columnName: 'password',
    dartType: 'String',
    resolvedType: 'String',
    isPrimaryKey: false,
    isNullable: true,
  ),
  FieldDefinition(
    name: 'profile',
    columnName: 'profile',
    dartType: 'Map<String, Object?>',
    resolvedType: 'Map<String, Object?>',
    isPrimaryKey: false,
    isNullable: true,
  ),
];

class _JsonCodec extends ValueCodec<Map<String, Object?>> {
  @override
  Object? encode(Map<String, Object?>? value) =>
      value == null ? null : jsonEncode(value);

  @override
  Map<String, Object?>? decode(Object? value) {
    if (value is! String) return value as Map<String, Object?>?;
    final decoded = jsonDecode(value) as Map<String, Object?>;
    return decoded;
  }
}
