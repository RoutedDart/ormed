import 'dart:io';

import 'package:artisan_args/src/tui/bubbles/anticipate.dart';
import 'package:artisan_args/src/tui/bubbles/confirm.dart';
import 'package:artisan_args/src/tui/bubbles/cursor.dart';
import 'package:artisan_args/src/tui/bubbles/filepicker.dart';
import 'package:artisan_args/src/tui/bubbles/pause.dart';
import 'package:artisan_args/src/tui/bubbles/password.dart';
import 'package:artisan_args/src/tui/bubbles/search.dart';
import 'package:artisan_args/src/tui/bubbles/select.dart';
import 'package:artisan_args/src/tui/bubbles/stopwatch.dart';
import 'package:artisan_args/src/tui/bubbles/table.dart';
import 'package:artisan_args/src/tui/bubbles/timer.dart';
import 'package:artisan_args/src/tui/bubbles/wizard.dart';
import 'package:artisan_args/src/tui/component.dart';
import 'package:artisan_args/src/tui/key.dart';
import 'package:artisan_args/src/tui/msg.dart';
import 'package:test/test.dart';

void main() {
  group('Bubbles ViewComponent migration', () {
    test('models instantiate as ViewComponent', () {
      final models = <ViewComponent>[
        TimerModel(timeout: const Duration(seconds: 1)),
        StopwatchModel(),
        CursorModel(),
        PauseModel(),
        CountdownModel(duration: const Duration(seconds: 1)),
        TableModel(
          columns: [Column(title: 'A', width: 1)],
          rows: [
            ['x'],
          ],
        ),
        AnticipateModel().focus(),
        ConfirmModel(prompt: 'Confirm?'),
        DestructiveConfirmModel(prompt: 'Type YES', confirmText: 'YES'),
        PasswordModel(),
        PasswordConfirmModel(),
        SearchModel<String>(items: const ['a', 'b']),
        SelectModel<String>(items: const ['a', 'b']),
        MultiSelectModel<String>(items: const ['a', 'b']),
        WizardModel(steps: const [TextInputStep(key: 'name', prompt: 'Name')]),
        FilePickerModel(currentDirectory: Directory.systemTemp.path),
      ];

      for (final m in models) {
        expect(m, isA<ViewComponent>());
        // Smoke: update through base type
        final (next, _) = m.update(const KeyMsg(Key(KeyType.escape)));
        expect(next, isA<ViewComponent>());
      }
    });
  });
}

