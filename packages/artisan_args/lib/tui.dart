/// Interactive TUI runtime using the Elm Architecture pattern.
///
/// This library provides a Bubble Tea-style framework for building
/// interactive terminal applications in Dart.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:artisan_args/tui.dart';
///
/// class CounterModel implements Model {
///   final int count;
///   CounterModel([this.count = 0]);
///
///   @override
///   Cmd? init() => null;
///
///   @override
///   (Model, Cmd?) update(Msg msg) {
///     return switch (msg) {
///       KeyMsg(key: Key(type: KeyType.up)) =>
///         (CounterModel(count + 1), null),
///       KeyMsg(key: Key(type: KeyType.down)) =>
///         (CounterModel(count - 1), null),
///       KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) =>
///         (this, Cmd.quit()),
///       _ => (this, null),
///     };
///   }
///
///   @override
///   String view() => 'Count: $count\n\nUse ↑/↓ to change, q to quit';
/// }
///
/// void main() async {
///   await runProgram(CounterModel());
/// }
/// ```
///
/// See the `src/tui/tui.dart` documentation for more details on the
/// Elm Architecture and available types.
library tui;

export 'src/tui/tui.dart';
export 'src/tui/bubbles/bubbles.dart' hide ValidateFunc, PasteMsg;
