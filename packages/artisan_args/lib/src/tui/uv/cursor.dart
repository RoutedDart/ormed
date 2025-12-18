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
