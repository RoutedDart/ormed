import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import 'package:driver_tests/src/models/derived_for_factory.dart';

void runDriverFactoryInheritanceTests() {
  ormedGroup('factory inheritance', (dataSource) {
    test('multi-level derived factory includes ancestor fields', () {
      final builder = Model.factory<DerivedForFactory>().withOverrides({
        'baseName': 'root',
        'layerOneNotes': {'notes': true},
        'layerTwoFlag': true,
      });
      final values = builder.values();
      expect(values['base_name'], 'root');
      expect(values['layer_one_notes'], {'notes': true});
      expect(values['layer_two_flag'], true);
    });

    test('derived models persist with inherited metadata', () async {
      final derived = Model.factory<DerivedForFactory>()
          .withOverrides({
            'baseName': 'root',
            'layerOneNotes': {'notes': true},
            'layerTwoFlag': true,
          })
          .make(registry: dataSource.context.codecRegistry);

      await dataSource.context.repository<DerivedForFactory>().insert(derived);

      final fetched = await dataSource.context.query<DerivedForFactory>().get();
      expect(fetched, isNotEmpty);
      expect(fetched.first.baseName, 'root');
      expect(fetched.first.layerOneNotes, {'notes': true});
      expect(fetched.first.layerTwoFlag, true);
    });
  });
}
