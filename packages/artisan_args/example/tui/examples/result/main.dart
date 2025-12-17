/// Result example: get final model data after program exit.
library;

import 'package:artisan_args/tui.dart' as tui;

const _choices = ['Taro', 'Coffee', 'Lychee'];

class ResultModel implements tui.Model {
  ResultModel({this.cursor = 0, this.choice = ''});

  final int cursor;
  final String choice;

  ResultModel copyWith({int? cursor, String? choice}) =>
      ResultModel(cursor: cursor ?? this.cursor, choice: choice ?? this.choice);

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      final key = msg.key;
      final isRune = key.type == tui.KeyType.runes && key.runes.isNotEmpty;
      final rune = isRune ? key.runes.first : -1;

      // Quit
      if (key.type == tui.KeyType.escape ||
          (isRune && rune == 0x71) || // q
          (key.ctrl && rune == 0x63)) {
        return (this, tui.Cmd.quit());
      }

      // Enter -> set choice and quit
      if (key.type == tui.KeyType.enter) {
        return (copyWith(choice: _choices[cursor]), tui.Cmd.quit());
      }

      // Down / j
      if (key.type == tui.KeyType.down || (isRune && rune == 0x6a)) {
        final next = (cursor + 1) % _choices.length;
        return (copyWith(cursor: next), null);
      }

      // Up / k
      if (key.type == tui.KeyType.up || (isRune && rune == 0x6b)) {
        final next = (cursor - 1) < 0 ? _choices.length - 1 : cursor - 1;
        return (copyWith(cursor: next), null);
      }
    }
    return (this, null);
  }

  @override
  String view() {
    final buffer = StringBuffer()
      ..writeln('What kind of Bubble Tea would you like to order?\n');

    for (var i = 0; i < _choices.length; i++) {
      buffer.write(cursor == i ? '(•) ' : '( ) ');
      buffer.writeln(_choices[i]);
    }

    buffer.writeln('\n(press q to quit)');
    return buffer.toString();
  }
}

Future<void> main() async {
  final m =
      await tui.runProgramWithResult(
            ResultModel(),
            options: const tui.ProgramOptions(
              altScreen: false,
              hideCursor: false,
            ),
          )
          as ResultModel;

  if (m.choice.isNotEmpty) {
    // Print after program exit.
    // ignore: avoid_print
    print('\n---\nYou chose ${m.choice}!');
  }
}
