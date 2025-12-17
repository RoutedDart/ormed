import 'package:ormed_mysql/ormed_mysql.dart';
import 'package:test/test.dart';

void main() {
  group('MySqlConnectionInfo', () {
    test('parses host/port/db/user/password from URL', () {
      final info = MySqlConnectionInfo.fromUrl(
        'mysql://root:secret@localhost:6605/app',
      );
      expect(info.host, 'localhost');
      expect(info.port, 6605);
      expect(info.database, 'app');
      expect(info.username, 'root');
      expect(info.password, 'secret');
    });

    test('secureByDefault applies when not specified', () {
      final info = MySqlConnectionInfo.fromUrl(
        'mysql://root@localhost/app',
        secureByDefault: true,
      );
      expect(info.secure, isTrue);
    });

    test('query param secure overrides default', () {
      final info = MySqlConnectionInfo.fromUrl(
        'mysql://root@localhost/app?secure=false',
        secureByDefault: true,
      );
      expect(info.secure, isFalse);
    });

    test('scheme implies TLS', () {
      final info = MySqlConnectionInfo.fromUrl('mysqls://root@localhost/app');
      expect(info.secure, isTrue);
    });
  });

  group('MariaDbConnectionInfo', () {
    test('parses using mariadb scheme', () {
      final info = MariaDbConnectionInfo.fromUrl(
        'mariadb://root:secret@localhost:6604/app',
      );
      expect(info.scheme, 'mariadb');
      expect(info.database, 'app');
    });
  });
}
