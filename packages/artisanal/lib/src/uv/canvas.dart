/// Immediate-mode Canvas for composing [Drawable]s onto a backing [Buffer].
///
/// [Canvas] implements [Screen] and provides simple drawing operations that
/// write directly into a cell buffer. Use it to build layers of content and
/// then present via a [Compositor] and [Screen].
///
/// {@category Ultraviolet}
/// {@subCategory Rendering}
///
/// {@macro artisanal_uv_concept_overview}
/// {@macro artisanal_uv_renderer_overview}
/// {@macro artisanal_uv_performance_tips}
///
/// Example:
/// ```dart
/// final canvas = Canvas(80, 24);
/// // Compose a drawable (e.g., StyledString) onto the canvas.
/// StyledString('Hello, UV').draw(canvas, canvas.bounds());
/// final rendered = canvas.render();
/// ```
import 'cell.dart';
import 'buffer.dart';
import 'drawable.dart';
import 'geometry.dart';
import 'screen.dart';
import '../unicode/width.dart';

/// Canvas is a cell-buffer that can be used to compose and draw [Drawable]s.
///
/// Upstream: `third_party/lipgloss/canvas.go` (Canvas backed by `uv.ScreenBuffer`).
final class Canvas implements Screen, Drawable {
  Canvas(int width, int height) : _scr = ScreenBuffer(width, height) {
    // Lip Gloss v2 uses GraphemeWidth for canvas composition.
    _scr.method = WidthMethod.grapheme;
  }

  final ScreenBuffer _scr;

  /// Resizes the canvas backing buffer to the given dimensions.
  void resize(int width, int height) => _scr.resize(width, height);

  /// Clears the entire canvas to empty cells.
  void clear() => _scr.clear();

  /// The current canvas width in cells.
  int width() => _scr.width();
  /// The current canvas height in cells.
  int height() => _scr.height();

  @override
  /// Returns the drawable bounds of the canvas.
  Rectangle bounds() => _scr.bounds();

  @override
  /// Returns the active grapheme width measurement method.
  WidthMethod widthMethod() => _scr.widthMethod();

  @override
  /// Returns the cell at ([x], [y]) or null if out of bounds.
  Cell? cellAt(int x, int y) => _scr.cellAt(x, y);

  @override
  /// Sets the cell at ([x], [y]) in the backing buffer.
  void setCell(int x, int y, Cell? cell) => _scr.setCell(x, y, cell);

  /// Composes a [Drawable] onto this canvas.
  Canvas compose(Drawable drawer) {
    drawer.draw(this, bounds());
    return this;
  }

  /// Renders the canvas into a string (trimming trailing spaces per line).
  String render() => _scr.buffer.render();

  @override
  /// Draws this canvas onto another [Screen] within [area].
  void draw(Screen screen, Rectangle area) => _scr.draw(screen, area);
}
