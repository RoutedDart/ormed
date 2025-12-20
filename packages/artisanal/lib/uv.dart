/// Ultraviolet: A low-level terminal rendering engine.
///
/// This library provides the core rendering logic, cell buffers, and input
/// decoders for building high-performance terminal UIs. It is a port of the
/// Ultraviolet engine.
///
/// ## Key Components
///
/// - **[Terminal]**: The main entry point for UV-based applications.
/// - **[Buffer]**: A 2D grid of [Cell]s representing the terminal screen.
/// - **[Cell]**: A single character with associated [UvStyle] and [Link].
/// - **[Renderer]**: Efficiently diffs buffers and sends ANSI updates to the terminal.
/// - **[Decoder]**: High-performance ANSI input decoder for keys and mouse events.
///
/// ## Usage
///
/// ```dart
/// import 'package:artisanal/uv.dart';
///
/// void main() async {
///   final terminal = Terminal();
///   await terminal.start();
///   
///   terminal.setCell(0, 0, Cell(
///     content: 'H',
///     style: UvStyle(fg: UvColor.rgb(255, 0, 0)),
///   ));
///   
///   terminal.draw();
///   await terminal.stop();
/// }
/// ```
library artisanal.uv;

export 'src/uv/terminal.dart' show Terminal;
export 'src/uv/buffer.dart' show Buffer, Line, LineData;
export 'src/uv/cell.dart' show Cell, Link, UvStyle, UvColor, UvBasic16, UvIndexed256, UvRgb;
export 'src/uv/event.dart'
    show
        Event,
        KeyEvent,
        WindowSizeEvent,
        MouseEvent,
        MouseClickEvent,
        MouseMotionEvent,
        KeyPressEvent,
        KittyGraphicsEvent,
        PrimaryDeviceAttributesEvent,
        FocusEvent,
        PasteEvent;
export 'src/uv/mouse.dart' show MouseMode, MouseButton;
export 'src/uv/border.dart' show UvBorder;
export 'src/uv/decoder.dart' show EventDecoder, LegacyKeyEncoding;
export 'src/uv/terminal_renderer.dart' show UvTerminalRenderer;
export 'src/uv/geometry.dart' show Position, Rectangle, rect;
export 'src/uv/capabilities.dart' show TerminalCapabilities;
export 'src/uv/styled_string.dart' show StyledString, newStyledString;
export 'src/uv/layer.dart' show Layer, Compositor;
export 'src/uv/layout.dart' show splitHorizontal, splitVertical, Fixed, Percent;
export 'src/uv/screen.dart' show Screen;
