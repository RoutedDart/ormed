import 'dart:async';

import 'package:artisan_args/src/terminal/terminal.dart';
import 'package:artisan_args/src/tui/cmd.dart';
import 'package:artisan_args/src/tui/key.dart';
import 'package:artisan_args/src/tui/model.dart';
import 'package:artisan_args/src/tui/msg.dart';
import 'package:artisan_args/src/tui/program.dart';
import 'package:test/test.dart';

class _QuitOnKeyModel implements Model {
  const _QuitOnKeyModel();

  @override
  Cmd? init() => Cmd.println('printed');

  @override
  (Model, Cmd?) update(Msg msg) {
    if (msg is KeyMsg) return (this, Cmd.quit());
    return (this, null);
  }

  @override
  String view() => 'view';
}

void main() {
  test('PrintLineMsg does not write directly with UltravioletRenderer', () async {
    final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
    final program = Program(
      const _QuitOnKeyModel(),
      options: const ProgramOptions(
        altScreen: false,
        hideCursor: false,
        useUltravioletRenderer: true,
      ),
      terminal: terminal,
    );

    final runFuture = program.run();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // When using UV renderer, PrintLineMsg should not call Terminal.writeln()
    // directly (that desyncs cursor state and causes output to accumulate).
    expect(
      terminal.operations.where((op) => op.startsWith('writeln:')).toList(),
      isEmpty,
    );

    // Printed output still shows up.
    expect(terminal.output, contains('printed'));
    expect(terminal.output, contains('view'));

    terminal.simulateInput([0x71]); // 'q'
    await runFuture;
  });
}

