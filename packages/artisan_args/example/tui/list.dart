/// TUI List Selection Example
///
/// This example demonstrates an interactive list selection component
/// using the Elm Architecture pattern.
///
/// Run with: dart run example/tui_list.dart
library;

import 'package:artisan_args/tui.dart';

/// The list selection model.
class ListModel implements Model {
  /// Creates a list model with the given items.
  const ListModel({required this.items, this.cursor = 0, this.selected});

  /// The list items to choose from.
  final List<String> items;

  /// The current cursor position.
  final int cursor;

  /// The selected item (null if nothing selected yet).
  final String? selected;

  /// Creates a copy with the given fields replaced.
  ListModel copyWith({List<String>? items, int? cursor, String? selected}) {
    return ListModel(
      items: items ?? this.items,
      cursor: cursor ?? this.cursor,
      selected: selected ?? this.selected,
    );
  }

  @override
  Cmd? init() => null; // No initialization needed

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      // Move cursor up
      KeyMsg(key: Key(type: KeyType.up)) ||
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x6b])) => (
        // 'k'
        copyWith(cursor: (cursor - 1).clamp(0, items.length - 1)),
        null,
      ),

      // Move cursor down
      KeyMsg(key: Key(type: KeyType.down)) ||
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x6a])) => (
        // 'j'
        copyWith(cursor: (cursor + 1).clamp(0, items.length - 1)),
        null,
      ),

      // Select item with Enter or Space
      KeyMsg(key: Key(type: KeyType.enter)) ||
      KeyMsg(
        key: Key(type: KeyType.space),
      ) => (copyWith(selected: items[cursor]), Cmd.quit()),

      // Quit without selection
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) || // 'q'
      KeyMsg(key: Key(type: KeyType.escape)) ||
      KeyMsg(key: Key(ctrl: true, runes: [0x63])) => (
        // Ctrl+C
        this,
        Cmd.quit(),
      ),

      // Jump to first item
      KeyMsg(key: Key(type: KeyType.home)) ||
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x67])) => (
        // 'g'
        copyWith(cursor: 0),
        null,
      ),

      // Jump to last item
      KeyMsg(key: Key(type: KeyType.end)) ||
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x47])) => (
        // 'G'
        copyWith(cursor: items.length - 1),
        null,
      ),

      // Ignore other messages
      _ => (this, null),
    };
  }

  @override
  String view() {
    final buffer = StringBuffer();

    buffer.writeln();
    buffer.writeln('  What would you like to have for lunch?');
    buffer.writeln();

    for (var i = 0; i < items.length; i++) {
      final isSelected = i == cursor;
      final prefix = isSelected ? '▸ ' : '  ';
      final item = items[i];

      if (isSelected) {
        // Highlight selected item
        buffer.writeln('  \x1b[36m$prefix$item\x1b[0m');
      } else {
        buffer.writeln('  $prefix$item');
      }
    }

    buffer.writeln();
    buffer.writeln(
      '  \x1b[2m↑/k: up • ↓/j: down • Enter: select • q: quit\x1b[0m',
    );
    buffer.writeln();

    return buffer.toString();
  }
}

void main() async {
  final model = ListModel(
    items: [
      '🍕 Pizza',
      '🍔 Burger',
      '🌮 Tacos',
      '🍜 Ramen',
      '🥗 Salad',
      '🍣 Sushi',
      '🥪 Sandwich',
      '🍝 Pasta',
    ],
  );

  await runProgram(
    model,
    options: const ProgramOptions(
      altScreen: true,
      useUltravioletRenderer: true,
      useUltravioletInputDecoder: true,
    ),
  );

  // Show result after program exits
  if (model.selected != null) {
    print('You selected: ${model.selected}');
  } else {
    // Access the final model state from the program
    print('No selection made. Maybe next time!');
  }
}
