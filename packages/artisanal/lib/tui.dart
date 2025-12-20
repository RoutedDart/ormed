/// Interactive TUI framework (Bubble Tea for Dart).
///
/// This library provides a framework for building interactive terminal
/// applications using the Elm Architecture (Model-Update-View).
///
/// ## Core Components
///
/// - **[Model]**: Represents the state of your application.
/// - **[Update]**: A function that handles messages and returns a new model and commands.
/// - **[View]**: A function that renders the current model into a string.
/// - **[Program]**: The runtime that manages the event loop and rendering.
/// - **[Bubbles]**: Reusable interactive widgets like text inputs, spinners, and lists.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:artisanal/tui.dart';
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
///   String view() => 'Count: \$count\n\nUse ↑/↓ to change, q to quit';
/// }
///
/// void main() async {
///   await runProgram(CounterModel());
/// }
/// ```
library artisanal.tui;

export 'src/tui/tui.dart';
export 'src/tui/bubbles/bubbles.dart' hide ValidateFunc, PasteMsg;
