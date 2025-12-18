import 'cell.dart';
import 'buffer.dart';
import 'geometry.dart';
import 'screen.dart';
import '../../unicode/width.dart';

/// Canvas is a cell-buffer that can be used to compose and draw [Drawable]s.
///
/// Upstream: `third_party/lipgloss/canvas.go` (Canvas backed by `uv.ScreenBuffer`).
final class Canvas implements Screen, Drawable {
  Canvas(int width, int height) : _scr = ScreenBuffer(width, height) {
    // Lip Gloss v2 uses GraphemeWidth for canvas composition.
    _scr.method = WidthMethod.grapheme;
  }

  final ScreenBuffer _scr;

  void resize(int width, int height) => _scr.resize(width, height);

  void clear() => _scr.clear();

  int width() => _scr.width();
  int height() => _scr.height();

  @override
  Rectangle bounds() => _scr.bounds();

  @override
  WidthMethod widthMethod() => _scr.widthMethod();

  @override
  Cell? cellAt(int x, int y) => _scr.cellAt(x, y);

  @override
  void setCell(int x, int y, Cell? cell) => _scr.setCell(x, y, cell);

  /// Composes a [Drawable] onto this canvas.
  Canvas compose(Drawable drawer) {
    drawer.draw(this, bounds());
    return this;
  }

  /// Renders the canvas into a string (trimming trailing spaces per line).
  String render() => _scr.buffer.render();

  @override
  void draw(Screen screen, Rectangle area) => _scr.draw(screen, area);
}
