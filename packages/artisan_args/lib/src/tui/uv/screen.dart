import 'cell.dart';
import 'geometry.dart';
import '../../unicode/width.dart';

/// Screen is a 2D surface of cells.
///
/// Upstream: `third_party/ultraviolet/buffer.go` (`Screen` interface).
abstract class Screen {
  Rectangle bounds();
  Cell? cellAt(int x, int y);
  void setCell(int x, int y, Cell? cell);
  WidthMethod widthMethod();
}

/// Optional fast-path: clear the entire screen.
///
/// Upstream: `third_party/ultraviolet/screen` (Clear).
abstract class ClearableScreen implements Screen {
  void clear();
}

/// Optional fast-path: clear an area of the screen.
///
/// Upstream: `third_party/ultraviolet/screen` (ClearArea).
abstract class ClearAreaScreen implements Screen {
  void clearArea(Rectangle area);
}

/// Optional fast-path: fill the entire screen.
///
/// Upstream: `third_party/ultraviolet/screen` (Fill).
abstract class FillableScreen implements Screen {
  void fill(Cell? cell);
}

/// Optional fast-path: fill an area of the screen.
///
/// Upstream: `third_party/ultraviolet/screen` (FillArea).
abstract class FillAreaScreen implements Screen {
  void fillArea(Cell? cell, Rectangle area);
}

/// Optional fast-path: clone the entire screen into a buffer.
///
/// Upstream: `third_party/ultraviolet/screen` (Clone).
abstract class CloneableScreen implements Screen {
  Object clone();
}

/// Optional fast-path: clone a screen area into a buffer.
///
/// Upstream: `third_party/ultraviolet/screen` (CloneArea).
abstract class CloneAreaScreen implements Screen {
  Object? cloneArea(Rectangle area);
}

/// Drawable can draw itself into a [Screen].
///
/// Upstream: `third_party/ultraviolet/buffer.go` (`Drawable`).
abstract class Drawable {
  void draw(Screen screen, Rectangle area);
}
