import 'cell.dart';
import 'geometry.dart';
import 'width.dart';

/// Screen is a 2D surface of cells.
///
/// Upstream: `third_party/ultraviolet/buffer.go` (`Screen` interface).
abstract class Screen {
  Rectangle bounds();
  Cell? cellAt(int x, int y);
  void setCell(int x, int y, Cell? cell);
  WidthMethod widthMethod();
}

/// Drawable can draw itself into a [Screen].
///
/// Upstream: `third_party/ultraviolet/buffer.go` (`Drawable`).
abstract class Drawable {
  void draw(Screen screen, Rectangle area);
}
