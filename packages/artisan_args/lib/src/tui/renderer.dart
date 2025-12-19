import 'dart:async' show unawaited;
import 'dart:io' as io;

import 'terminal.dart';
import 'uv/buffer.dart' as uv_buffer;
import 'uv/styled_string.dart' as uv_styled;
import 'uv/terminal_renderer.dart' as uv_term;

/// Abstract renderer interface for TUI output.
///
/// Renderers are responsible for displaying the view string
/// to the terminal efficiently.
abstract class Renderer {
  /// Renders the view to the terminal.
  ///
  /// [view] is the string representation of the current UI state,
  /// or a [View] object containing metadata.
  void render(Object view);

  /// Clears the rendered content.
  void clear();

  /// Flushes any buffered output.
  Future<void> flush();

  /// Disposes of renderer resources.
  void dispose();
}

/// Options for configuring the renderer.
class RendererOptions {
  const RendererOptions({
    this.fps = 60,
    this.altScreen = true,
    this.hideCursor = true,
    this.ansiCompress = false,
  });

  /// Maximum frames per second for rendering.
  ///
  /// Limits how often the screen can be redrawn to prevent
  /// excessive CPU usage and flickering.
  final int fps;

  /// Whether to use the alternate screen buffer.
  ///
  /// When true, the application runs in fullscreen mode and
  /// the original terminal content is restored on exit.
  final bool altScreen;

  /// Whether to hide the cursor during rendering.
  final bool hideCursor;

  /// Whether to compress redundant ANSI sequences.
  final bool ansiCompress;

  /// The minimum time between renders.
  Duration get frameTime => Duration(milliseconds: 1000 ~/ fps);
}

/// Full-screen renderer using the alternate screen buffer.
///
/// This renderer clears the entire screen and redraws from
/// position (0,0) on each render. Best for fullscreen applications.
class FullScreenRenderer implements Renderer {
  FullScreenRenderer({
    required this.terminal,
    RendererOptions options = const RendererOptions(),
  }) : _options = options;

  /// The terminal to render to.
  final TuiTerminal terminal;

  final RendererOptions _options;

  /// The last rendered view (for skip-if-unchanged optimization).
  String? _lastView;

  /// The last render time (for frame limiting).
  DateTime? _lastRenderTime;

  /// Whether the renderer has been initialized.
  bool _initialized = false;

  /// Initializes the renderer.
  ///
  /// Sets up the terminal for fullscreen rendering.
  void initialize() {
    if (_initialized) return;

    if (_options.altScreen) {
      terminal.enterAltScreen();
    }
    if (_options.hideCursor) {
      terminal.hideCursor();
    }
    terminal.clearScreen();
    _initialized = true;
  }

  @override
  void render(Object view) {
    if (!_initialized) {
      initialize();
    }

    final String content;
    if (view is String) {
      content = view;
    } else {
      // For now, just extract content from View object.
      // Full metadata support will be added to Program.
      content = (view as dynamic).content as String;
    }

    // Frame rate limiting
    if (_lastRenderTime != null) {
      final elapsed = DateTime.now().difference(_lastRenderTime!);
      if (elapsed < _options.frameTime) {
        // Skip this frame
        return;
      }
    }

    // Skip if view hasn't changed
    if (content == _lastView) {
      return;
    }

    // Full redraw (future: diff with _lastView and update only changed lines)
    terminal.cursorHome();
    final output = _options.ansiCompress ? _compressAnsi(content) : content;
    terminal.write(output);

    // Clear any remaining content from previous render
    _clearToEndOfScreen(content);

    _lastView = content;
    _lastRenderTime = DateTime.now();
  }

  /// Clears remaining content after the view.
  void _clearToEndOfScreen(String view) {
    if (!terminal.supportsAnsi) return;

    // Count lines in the view
    final viewLines = view.split('\n').length;
    final termHeight = terminal.size.height;

    // Clear remaining lines
    if (viewLines < termHeight) {
      final clearLine = '\x1b[2K'; // Clear entire line
      final buffer = StringBuffer();
      for (var i = viewLines; i < termHeight; i++) {
        buffer.write('$clearLine\n');
      }
      terminal.write(buffer.toString());
    }
  }

  @override
  void clear() {
    terminal.clearScreen();
    _lastView = null;
  }

  @override
  Future<void> flush() async {
    await terminal.flush();
  }

  @override
  void dispose() {
    if (!_initialized) return;

    if (_options.hideCursor) {
      terminal.showCursor();
    }
    if (_options.altScreen) {
      terminal.exitAltScreen();
    }
    _initialized = false;
  }
}

/// Inline renderer that renders below the current cursor position.
///
/// This renderer doesn't use the alternate screen buffer, so
/// output accumulates in the terminal history. Best for
/// tools that should leave output visible after exit.
class InlineRenderer implements Renderer {
  InlineRenderer({
    required this.terminal,
    RendererOptions options = const RendererOptions(
      altScreen: false,
      hideCursor: false,
    ),
  }) : _options = options;

  /// The terminal to render to.
  final TuiTerminal terminal;

  final RendererOptions _options;

  /// Number of lines in the last render.
  int _lastLineCount = 0;

  /// The last render time (for frame limiting).
  DateTime? _lastRenderTime;

  /// Whether we've rendered at least once.
  bool _hasRendered = false;

  @override
  void render(Object view) {
    final String content;
    if (view is String) {
      content = view;
    } else {
      content = (view as dynamic).content as String;
    }

    // Frame rate limiting
    if (_lastRenderTime != null) {
      final elapsed = DateTime.now().difference(_lastRenderTime!);
      if (elapsed < _options.frameTime) {
        return;
      }
    }

    // Clear previous output
    if (_hasRendered && _lastLineCount > 0) {
      _clearPreviousLines(_lastLineCount);
    }

    // Hide cursor during render if configured
    if (_options.hideCursor) {
      terminal.hideCursor();
    }

    // Write the new view
    final output = _options.ansiCompress ? _compressAnsi(content) : content;
    terminal.write(output);
    if (!output.endsWith('\n')) {
      terminal.writeln();
    }

    // Show cursor after render
    if (_options.hideCursor) {
      terminal.showCursor();
    }

    _lastLineCount = content.split('\n').length;
    _lastRenderTime = DateTime.now();
    _hasRendered = true;
  }

  /// Clears the previous output by moving up and clearing lines.
  void _clearPreviousLines(int lines) {
    if (!terminal.supportsAnsi) return;

    final buffer = StringBuffer();
    for (var i = 0; i < lines; i++) {
      buffer.write('\x1b[A'); // Move up
      buffer.write('\x1b[2K'); // Clear line
    }
    buffer.write('\r'); // Return to start of line
    terminal.write(buffer.toString());
  }

  @override
  void clear() {
    if (_hasRendered && _lastLineCount > 0) {
      _clearPreviousLines(_lastLineCount);
    }
    _lastLineCount = 0;
  }

  @override
  Future<void> flush() async {
    await terminal.flush();
  }

  @override
  void dispose() {
    // Inline renderer doesn't need cleanup
  }
}

/// A renderer that buffers output for efficient writes.
///
/// Collects all output in a buffer and writes it in a single
/// operation to reduce flickering.
class BufferedRenderer implements Renderer {
  BufferedRenderer({required this.inner});

  /// The underlying renderer.
  final Renderer inner;

  /// Pending view to render.
  Object? _pendingView;

  /// Whether we have pending output.
  bool _dirty = false;

  @override
  void render(Object view) {
    _pendingView = view;
    _dirty = true;
  }

  @override
  void clear() {
    _pendingView = null;
    inner.clear();
    _dirty = false;
  }

  @override
  Future<void> flush() async {
    if (_dirty && _pendingView != null) {
      inner.render(_pendingView!);
      _dirty = false;
    }
    await inner.flush();
  }

  @override
  void dispose() {
    inner.dispose();
  }
}

/// Ultraviolet-inspired renderer backed by a cell buffer + diffing updates.
///
/// This renderer keeps `Model.view(): String` as the public API, but internally
/// parses ANSI-styled strings into a cell buffer and diffs frames to emit
/// minimal terminal updates.
///
/// Upstream references:
/// - `third_party/ultraviolet/styled.go` (`StyledString.Draw`)
/// - `third_party/ultraviolet/terminal_renderer.go` (`TerminalRenderer.Render`)
class UltravioletRenderer implements Renderer {
  UltravioletRenderer({
    required this.terminal,
    RendererOptions options = const RendererOptions(),
    this.movementCapsOverride,
  }) : _options = options;

  final TuiTerminal terminal;
  final RendererOptions _options;
  final ({bool useTabs, bool useBackspace})? movementCapsOverride;

  bool _initialized = false;
  bool _dirty = false;
  String _pendingView = '';
  final List<String> _printLines = <String>[];
  static const int _maxPrintLines = 2000;

  uv_buffer.ScreenBuffer? _screen;
  uv_term.TerminalRenderer? _renderer;

  DateTime? _lastRenderTime;

  void printLine(String text) {
    _initialize();
    if (text.isEmpty) return;

    final lines = text.replaceAll('\r\n', '\n').split('\n');
    for (final line in lines) {
      if (line.isEmpty) continue;
      _printLines.add(line);
      if (_printLines.length > _maxPrintLines) {
        _printLines.removeAt(0);
      }
    }
  }

  String _composeView(String view) {
    if (_printLines.isEmpty) return view;
    if (view.isEmpty) return '${_printLines.join('\n')}\n';
    return '${_printLines.join('\n')}\n$view';
  }

  void renderImmediate(String view) {
    _initialize();
    _pendingView = _composeView(view);
    _dirty = true;
    _lastRenderTime = null;
    _flushInternal();
    unawaited(terminal.flush());
  }

  void _initialize() {
    if (_initialized) return;

    if (_options.altScreen) {
      terminal.enterAltScreen();
    }
    if (_options.hideCursor) {
      terminal.hideCursor();
    }
    if (_options.altScreen) {
      terminal.clearScreen();
    }

    final (width: w, height: h) = terminal.size;
    _screen = uv_buffer.ScreenBuffer(w, h);

    final sink = _TerminalStringSink(terminal);
    final envMap = io.Platform.environment;
    final env = envMap.entries.map((e) => '${e.key}=${e.value}').toList();
    // The UV-style renderer needs to know whether output is a TTY so it can
    // pick the correct color profile and enable terminal optimizations.
    //
    // Upstream: `third_party/ultraviolet/terminal_renderer.go` uses a real
    // terminal writer; our `StringSink` abstraction requires an explicit hint.
    if (terminal.isTerminal && !envMap.containsKey('TTY_FORCE')) {
      env.add('TTY_FORCE=1');
    }
    if (terminal.isTerminal &&
        terminal.supportsAnsi &&
        (envMap['TERM'] == null || (envMap['TERM'] ?? '').isEmpty)) {
      env.add('TERM=xterm-256color');
    }
    _renderer = uv_term.TerminalRenderer(sink, env: env);
    _renderer!.setFullscreen(_options.altScreen);
    _renderer!.setRelativeCursor(!_options.altScreen);
    _renderer!.setMapNewline(!io.Platform.isWindows && terminal.isTerminal);
    _renderer!.setScrollOptim(!io.Platform.isWindows);

    // Apply terminal movement optimizations. Allow a compatibility override so
    // callers can provide capability bits without probing the terminal.
    final caps = movementCapsOverride ?? terminal.optimizeMovements();
    _renderer!.setHasTab(caps.useTabs);
    _renderer!.setBackspace(caps.useBackspace);
    if (caps.useTabs) {
      _renderer!.setTabStops(w);
    }

    if (_options.altScreen) {
      _renderer!.saveCursor();
      _renderer!.erase();
    }

    _initialized = true;
  }

  void _ensureSize() {
    final (width: w, height: h) = terminal.size;
    final scr = _screen;
    if (scr == null) return;
    if (scr.width() == w && scr.height() == h) return;
    scr.resize(w, h);
    _renderer?.resize(w, h);
    _renderer?.erase();
  }

  @override
  void render(Object view) {
    _initialize();

    final String content;
    if (view is String) {
      content = view;
    } else {
      content = (view as dynamic).content as String;
    }

    if (_lastRenderTime != null) {
      final elapsed = DateTime.now().difference(_lastRenderTime!);
      if (elapsed < _options.frameTime) return;
    }

    _pendingView = _composeView(content);
    _dirty = true;
    _lastRenderTime = DateTime.now();

    // Unlike the other renderers, the UV renderer buffers terminal output in
    // its own writer and needs a flush step to emit bytes. Do it immediately
    // so Program doesn't need to coordinate flush ordering with control writes.
    //
    // Also schedule a terminal flush: Program doesn't call Renderer.flush()
    // today, and some terminals won't paint until the underlying sink is
    // flushed.
    _flushInternal();
    unawaited(terminal.flush());
  }

  @override
  void clear() {
    _initialize();
    _renderer?.erase();
    _dirty = true;
    _pendingView = '';
    unawaited(terminal.flush());
  }

  @override
  Future<void> flush() async {
    if (!_initialized) return;
    _flushInternal();
    await terminal.flush();
  }

  void _flushInternal() {
    if (!_initialized) return;
    if (!_dirty) return;

    _ensureSize();
    final scr = _screen;
    final r = _renderer;
    if (scr == null || r == null) return;

    final ss = uv_styled.newStyledString(
      _options.ansiCompress ? _compressAnsi(_pendingView) : _pendingView,
    )..wrap = true;
    ss.draw(scr, scr.bounds());

    r.render(scr.buffer);
    r.flush();
    _dirty = false;
  }

  @override
  void dispose() {
    if (!_initialized) return;
    if (_options.hideCursor) {
      terminal.showCursor();
    }
    if (_options.altScreen) {
      terminal.exitAltScreen();
    }
    _initialized = false;
  }
}

final class _TerminalStringSink implements StringSink {
  _TerminalStringSink(this.terminal);

  final TuiTerminal terminal;

  @override
  void write(Object? obj) => terminal.write(obj?.toString() ?? '');

  @override
  void writeAll(Iterable objects, [String separator = '']) =>
      write(objects.join(separator));

  @override
  void writeCharCode(int charCode) =>
      terminal.write(String.fromCharCode(charCode));

  @override
  void writeln([Object? obj = '']) => terminal.writeln(obj?.toString() ?? '');
}

/// A renderer that does nothing (for testing).
class NullTuiRenderer implements Renderer {
  /// The last view that was rendered.
  Object? lastView;

  /// All views that have been rendered.
  final List<Object> views = [];

  @override
  void render(Object view) {
    lastView = view;
    views.add(view);
  }

  @override
  void clear() {
    lastView = null;
  }

  @override
  Future<void> flush() async {}

  @override
  void dispose() {}
}

/// Renderer that writes output without diffing or clearing (nil renderer mode).
class NullRenderer implements Renderer {
  NullRenderer({
    required this.terminal,
    RendererOptions options = const RendererOptions(),
  }) : _options = options;

  final TuiTerminal terminal;
  final RendererOptions _options;

  @override
  void render(Object view) {
    final String content;
    if (view is String) {
      content = view;
    } else {
      content = (view as dynamic).content as String;
    }
    final output = _options.ansiCompress ? _compressAnsi(content) : content;
    terminal.writeln(output);
  }

  @override
  void clear() {}

  @override
  Future<void> flush() async {
    await terminal.flush();
  }

  @override
  void dispose() {}
}

String _compressAnsi(String input) {
  // Remove redundant SGR sequences to reduce output size.
  //
  // This intentionally removes *repeated* SGR sequences even when separated by
  // text (e.g. "\x1b[31mred\x1b[31mred" -> "\x1b[31mredred").
  final sgr = RegExp(r'\x1B\[[0-9;:]*m');
  final out = StringBuffer();
  var lastEnd = 0;
  String? lastSgr;

  for (final m in sgr.allMatches(input)) {
    out.write(input.substring(lastEnd, m.start));
    final seq = m.group(0)!;

    // Normalize the empty-param reset to a stable form.
    final normalized = seq == '\x1B[m' ? '\x1B[0m' : seq;

    if (normalized != lastSgr) {
      out.write(seq);
      lastSgr = normalized;
    }

    lastEnd = m.end;
  }

  out.write(input.substring(lastEnd));
  return out.toString();
}

/// A renderer that writes to a StringSink (for testing).
class StringSinkRenderer implements Renderer {
  StringSinkRenderer(this.sink);

  /// The sink to write to.
  final StringSink sink;

  @override
  void render(Object view) {
    final String content;
    if (view is String) {
      content = view;
    } else {
      content = (view as dynamic).content as String;
    }
    sink.write(content);
  }

  @override
  void clear() {
    // Can't clear a StringSink
  }

  @override
  Future<void> flush() async {}

  @override
  void dispose() {}
}

/// Extension to create renderers from terminals.
extension TerminalRendererExtension on TuiTerminal {
  /// Creates a fullscreen renderer for this terminal.
  FullScreenRenderer fullScreenRenderer({
    RendererOptions options = const RendererOptions(),
  }) {
    return FullScreenRenderer(terminal: this, options: options);
  }

  /// Creates an inline renderer for this terminal.
  InlineRenderer inlineRenderer({
    RendererOptions options = const RendererOptions(
      altScreen: false,
      hideCursor: false,
    ),
  }) {
    return InlineRenderer(terminal: this, options: options);
  }
}
