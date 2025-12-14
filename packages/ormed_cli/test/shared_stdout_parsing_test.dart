import 'package:ormed_cli/src/commands/base/shared.dart';
import 'package:test/test.dart';

void main() {
  group('extractJsonPayloadForTest', () {
    test('strips log prefixes before JSON arrays', () {
      const noisyOutput =
          'Running build hooks...\n'
          'Running build hooks...\n'
          '[{"id":"m_123"}]\n';
      final result = extractJsonPayloadForTest(
        noisyOutput,
        context: 'migration registry',
        expectArray: true,
      );
      expect(result, equals('[{"id":"m_123"}]'));
    });

    test('removes ANSI / OSC noise around JSON objects', () {
      const noisyOutput =
          '\u001B[2KBuilding package executable...\n'
          '\u001B]2;dart run\u0007\n'
          '{"plan":"ok"}\n';
      final result = extractJsonPayloadForTest(
        noisyOutput,
        context: 'migration plan',
        expectArray: false,
      );
      expect(result, equals('{"plan":"ok"}'));
    });

    test('throws when JSON payload is missing', () {
      expect(
        () => extractJsonPayloadForTest(
          'noise only',
          context: 'missing payload',
          expectArray: true,
        ),
        throwsStateError,
      );
    });
  });
}
