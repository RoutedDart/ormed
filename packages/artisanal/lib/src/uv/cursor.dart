import 'geometry.dart';
import '../style/color.dart';

/// Cursor shape primitives.
///
/// Upstream: `third_party/ultraviolet/cursor.go`.
enum CursorShape { block, underline, bar }

extension CursorShapeEncode on CursorShape {
  /// Returns the ANSI-encoded cursor shape code.
  ///
  /// Upstream: `CursorShape.Encode` in `third_party/ultraviolet/cursor.go`.
  int encode({required bool blink}) {
    // s = (s*2)+1; if !blink { s++ }
    var s = (index * 2) + 1;
    if (!blink) s++;
    return s;
  }
}

/// Cursor represents a cursor on the terminal screen.
///
/// Upstream: `third_party/ultraviolet/uv.go` (`Cursor`).
class Cursor {
  Cursor({
    required this.position,
    this.color,
    this.shape = CursorShape.block,
    this.blink = true,
  });

  /// Position of the cursor on the screen.
  Position position;

  /// Color of the cursor.
  Color? color;

  /// Shape of the cursor.
  CursorShape shape;

  /// Whether the cursor should blink.
  bool blink;

  /// Returns a new cursor with default settings at the given position.
  factory Cursor.at(int x, int y) => Cursor(position: Position(x, y));
}
