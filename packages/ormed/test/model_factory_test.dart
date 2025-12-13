import 'package:driver_tests/driver_tests.dart';
import 'package:driver_tests/orm_registry.g.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';


void main() {

  group('ModelFactoryBuilder', () {

    registerOrmFactories();
    setUpAll(() {
      ModelFactoryRegistry.register(AttributeUserOrmDefinition.definition);
      ModelFactoryRegistry.register(DerivedForFactoryOrmDefinition.definition);
    });

    test('generates values and respects overrides', () {
      final builder = Model.factory<AttributeUser>().withOverrides({'id': 42});
      final values = builder.values();
      expect(values['id'], 42);
      expect(values['email'], isNotNull);
      expect(builder.value('email'), values['email']);
    });

    test('uses deterministic seed', () {
      final first = Model.factory<AttributeUser>().seed(42).values();
      final second = Model.factory<AttributeUser>().seed(42).values();
      expect(second['email'], first['email']);
      expect(second['createdAt'], first['createdAt']);
    });

    test('withGenerator overrides individual fields', () {
      final builder = Model.factory<AttributeUser>().withGenerator(
        'email',
        (_, _) => 'forced@example.com',
      );
      final values = builder.values();
      expect(values['email'], 'forced@example.com');
    });

    test('make returns a hydrated model', () {
      final builder = Model.factory<AttributeUser>().seed(7).withOverrides({
        'role': 'admin',
      });
      final user = builder.make();
      expect(user, isA<AttributeUser>());
      expect(user.role, 'admin');
      expect(user.email, isNotNull);
    });

    test('value can seed another payload', () {
      final email = Model.factory<AttributeUser>().seed(3).value('email');
      final other = {
        'authorEmail': email,
        'reference': Model.factory<AttributeUser>().value('id'),
      };
      expect(other['authorEmail'], email);
      expect(other['reference'], isA<int>());
    });

    test('non-opt-in models cannot resolve factories', () {
      expect(() => Model.factory<NoFactory>().values(), throwsStateError);
    });

    test('derived model inherits factory via mixin base', () {
      final values = Model.factory<DerivedForFactory>().withOverrides({
        'baseName': 'root',
        'layerOneNotes': 'notes',
        'layerTwoFlag': true,
      }).values();
      expect(values['baseName'], 'root');
      expect(values['layerOneNotes'], 'notes');
      expect(values['layerTwoFlag'], true);
    });

    test('derived metadata includes ancestor attributes', () {
      final overrides =
          DerivedForFactoryOrmDefinition.definition.metadata.fieldOverrides;
      expect(overrides['id']?.hidden, isTrue);
      expect(overrides['baseName']?.fillable, isTrue);
      expect(overrides['layerOneNotes']?.cast, 'json');
      expect(overrides['layerTwoFlag']?.guarded, isTrue);
    });
  });
}
