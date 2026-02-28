import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  group('OrmedEnvironment', () {
    test('reads first non-empty values', () {
      final env = OrmedEnvironment({'A': '', 'B': '  value  '});

      expect(env.value('A'), isNull);
      expect(env.value('B'), equals('value'));
      expect(env.firstNonEmpty(['A', 'B']), equals('value'));
      expect(env.firstNonEmpty(['C']), isNull);
    });

    test('parses int and bool with fallbacks', () {
      final env = OrmedEnvironment({
        'PORT': '8080',
        'DEBUG': 'true',
        'SSL': 'disable',
      });

      expect(env.intValue('PORT', fallback: 3000), equals(8080));
      expect(env.intValue('MISSING', fallback: 3000), equals(3000));
      expect(env.boolValue('DEBUG', fallback: false), isTrue);
      expect(env.boolValue('SSL', fallback: true), isFalse);
      expect(env.boolValue('MISSING', fallback: false), isFalse);
      expect(env.firstBool(['MISSING', 'SSL'], fallback: true), isFalse);
      expect(env.firstBool(['MISSING', 'UNKNOWN'], fallback: true), isTrue);
    });

    test('requires mandatory values', () {
      final env = OrmedEnvironment({'A': '', 'B': 'value'});

      expect(env.require('B'), equals('value'));
      expect(env.requireAny(['A', 'B']), equals('value'));
      expect(
        () => env.require('A'),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Missing required env var: A'),
          ),
        ),
      );
      expect(
        () => env.requireAny(['A', 'C']),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Missing required env vars: A or C'),
          ),
        ),
      );
    });

    test('interpolates strings with optional fallbacks', () {
      final env = OrmedEnvironment({'DB_HOST': 'localhost'});

      final expanded = env.interpolate(
        r'postgres://${DB_HOST}:${DB_PORT:-5432}/${DB_NAME:-app}',
      );
      expect(expanded, equals('postgres://localhost:5432/app'));
    });

    test(
      'uses fallback when value is blank and resolves nested placeholders',
      () {
        final env = OrmedEnvironment({'DB_PORT': '', 'DEFAULT_PORT': '15432'});

        final expanded = env.interpolate(
          r'postgres://localhost:${DB_PORT:-${DEFAULT_PORT:-5432}}/app',
        );

        expect(expanded, equals('postgres://localhost:15432/app'));
      },
    );

    test('resolves placeholders inside environment variable values', () {
      final env = OrmedEnvironment({
        'ROOT': '/srv/app',
        'DB_PATH': r'${ROOT}/database/app.sqlite',
      });

      final expanded = env.interpolate(r'sqlite://${DB_PATH}');
      expect(expanded, equals('sqlite:///srv/app/database/app.sqlite'));
    });

    test('avoids recursive self-references and falls back safely', () {
      final env = OrmedEnvironment({'A': r'${A}'});

      final expanded = env.interpolate(r'value=${A:-safe}');
      expect(expanded, equals('value=safe'));
    });
  });
}
