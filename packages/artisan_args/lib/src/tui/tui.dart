/// Interactive TUI runtime using the Elm Architecture pattern.
///
/// This module provides a Bubble Tea-style framework for building
/// interactive terminal applications in Dart.
///
/// ## Core Concepts
///
/// - [Model] - Defines application state and the init/update/view contract
/// - [Msg] - Messages that trigger state updates
/// - [Cmd] - Async commands that produce messages
/// - [Program] - Event loop that manages the application lifecycle
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
/// ## The Elm Architecture
///
/// This module implements The Elm Architecture (TEA), a pattern for
/// building interactive applications:
///
/// 1. **Model** - The application state
/// 2. **Update** - How the state changes in response to messages
/// 3. **View** - How to render the state as output
///
/// Messages flow through the system:
/// - User input generates messages (KeyMsg, MouseMsg, etc.)
/// - Messages are sent to `update()` which produces new state
/// - The new state is rendered via `view()`
/// - Commands from `update()` may produce more messages
///
/// ## Message Types
///
/// Built-in message types:
/// - [KeyMsg] - Keyboard input
/// - [MouseMsg] - Mouse events (when enabled)
/// - [WindowSizeMsg] - Terminal resize events
/// - [TickMsg] - Timer events
///
/// Custom messages can extend [Msg]:
/// ```dart
/// class DataLoadedMsg extends Msg {
///   final List<Item> items;
///   DataLoadedMsg(this.items);
/// }
/// ```
///
/// ## Commands
///
/// Commands represent side effects:
/// - [Cmd.quit] - Exit the program
/// - [Cmd.tick] - Timer that fires once
/// - [Cmd.batch] - Run commands concurrently
/// - [Cmd.sequence] - Run commands in order
/// - [Cmd.perform] - Wrap async operations
library;

// Terminal abstraction
export 'terminal.dart'
    show TuiTerminal, StdioTerminal, TerminalState;

// Components
export 'component.dart' show ViewComponent, StaticComponent, ComponentHost;

// Key input
export 'key.dart' show Key, KeyType, KeyParser, Keys;

// Message types
export 'msg.dart'
    show
        Msg,
        KeyMsg,
        ClipboardMsg,
        ClipboardSelection,
        BackgroundColorMsg,
        ForegroundColorMsg,
        CursorColorMsg,
        MouseMsg,
        MouseButton,
        MouseAction,
        WindowSizeMsg,
        TickMsg,
        QuitMsg,
        BatchMsg,
        FocusMsg,
        PasteMsg,
        CustomMsg,
        InterruptMsg,
        RepaintMsg,
        UvEventMsg;

// Terminal theme helper (background/dark-mode)
export 'theme.dart' show TerminalThemeState, TerminalThemeHost;

// Command system
export 'cmd.dart'
    show
        Cmd,
        StreamCmd,
        EveryCmd,
        CmdExtension,
        every,
        CmdFunc,
        CmdFunc1,
        // Control messages
        SetWindowTitleMsg,
        ClearScreenMsg,
        EnterAltScreenMsg,
        ExitAltScreenMsg,
        ShowCursorMsg,
        HideCursorMsg,
        EnableMouseCellMotionMsg,
        EnableMouseAllMotionMsg,
        DisableMouseMsg,
        EnableBracketedPasteMsg,
        DisableBracketedPasteMsg,
        EnableReportFocusMsg,
        DisableReportFocusMsg,
        RequestWindowSizeMsg,
        SuspendMsg,
        ResumeMsg,
        PrintLineMsg,
        RepaintRequestMsg,
        ExecProcessMsg,
        ExecResult;

// Model interface
export 'model.dart'
    show Model, CopyWithModel, CompositeModel, UpdateResult, noCmd, quit;

// Renderer
export 'renderer.dart'
    show
        Renderer,
        RendererOptions,
        FullScreenRenderer,
        InlineRenderer,
        UltravioletRenderer,
        BufferedRenderer,
        NullTuiRenderer,
        StringSinkRenderer,
        TerminalRendererExtension;

// Program runtime
export 'program.dart'
    show
        Program,
        ProgramOptions,
        MouseMode,
        MessageFilter,
        ProgramCancelledError,
        runProgram,
        runProgramWithResult,
        runProgramDebug;

// Markdown helper (lightweight Glamour-style renderer for examples)
export 'markdown.dart' show renderMarkdown;

// Harmonica helpers (spring, projectile) used by progress and demos
export 'harmonica.dart'
    show
        Spring,
        Projectile,
        Point,
        Vector,
        gravity,
        terminalGravity,
        fpsDelta,
        newSpringFromFps;
