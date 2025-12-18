import 'package:artisan_args/src/tui/bubbles/list.dart';
import 'package:artisan_args/src/tui/component.dart';
import 'package:artisan_args/tui.dart' show Key, KeyMsg, KeyType;
import 'package:test/test.dart';

void main() {
  group('ListModel (ViewComponent)', () {
    test('updates via base type', () {
      final list = ListModel(items: [StringItem('a'), StringItem('b')]);
      ViewComponent model = list;

      final beforeCursor = list.cursor;
      final (updated, _) = model.update(const KeyMsg(Key(KeyType.down)));

      expect(updated, isA<ListModel>());
      expect((updated as ListModel).cursor, greaterThanOrEqualTo(beforeCursor));
    });
  });
}

