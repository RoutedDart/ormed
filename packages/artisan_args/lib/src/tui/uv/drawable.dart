import 'geometry.dart';
import 'screen.dart';

/// Drawable can draw itself into a [Screen].
///
/// Upstream: `third_party/ultraviolet/buffer.go` (`Drawable`).
abstract interface class Drawable {
  void draw(Screen screen, Rectangle area);
  Rectangle bounds();
}

/// A no-op drawable with a fixed size.
///
/// Useful as a safe fallback when a terminal does not support any image
/// protocol: the renderer won't emit unknown escape sequences.
final class EmptyDrawable implements Drawable {
  const EmptyDrawable({this.width = 0, this.height = 0});

  final int width;
  final int height;

  @override
  Rectangle bounds() =>
      Rectangle(minX: 0, minY: 0, maxX: width, maxY: height);

  @override
  void draw(Screen screen, Rectangle area) {
    // no-op
  }
}
