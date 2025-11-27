import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import 'package:ormed/test_models/derived_for_factory.dart';
import '../config.dart';
import '../harness/driver_test_harness.dart';

void runDriverFactoryInheritanceTests({
  required DriverHarnessBuilder<DriverTestHarness> createHarness,
  required DriverTestConfig config,
}) {
  group('${config.driverName} factory inheritance', () {
    late DriverTestHarness harness;

    setUp(() async {
      harness = await createHarness();
    });

    tearDown(() async => harness.dispose());

    test('multi-level derived factory includes ancestor fields', () {
      final builder = Model.factory<DerivedForFactory>().withOverrides({
        'baseName': 'root',
        'layerOneNotes': {'notes': true},
        'layerTwoFlag': true,
      });
      final values = builder.values();
      expect(values['baseName'], 'root');
      expect(values['layerOneNotes'], {'notes': true});
      expect(values['layerTwoFlag'], true);
    });

    test('derived models persist with inherited metadata', () async {
      final derived = Model.factory<DerivedForFactory>().withOverrides({
        'baseName': 'root',
        'layerOneNotes': {'notes': true},
        'layerTwoFlag': true,
      }).make();

      await harness.context.repository<DerivedForFactory>().insert(derived);

      final fetched = await harness.context.query<DerivedForFactory>().get();
      expect(fetched, isNotEmpty);
      expect(fetched.first.baseName, 'root');
      expect(fetched.first.layerOneNotes, {'notes': true});
      expect(fetched.first.layerTwoFlag, true);
    });
  });
}
