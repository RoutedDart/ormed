import 'dart:math' as math;

/// Upstream: `third_party/ultraviolet/buffer.go` (`Position`, `Rectangle`).
final class Position {
  const Position(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is Position && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Rectangle with inclusive-exclusive bounds: `[min, max)`.
///
/// Upstream: `third_party/ultraviolet/buffer.go` (`Rectangle`).
final class Rectangle {
  const Rectangle({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  final int minX;
  final int minY;
  final int maxX;
  final int maxY;

  int get width => maxX - minX;
  int get height => maxY - minY;

  bool get isEmpty => width <= 0 || height <= 0;

  bool contains(Position p) =>
      p.x >= minX && p.x < maxX && p.y >= minY && p.y < maxY;

  bool containsRect(Rectangle other) =>
      other.minX >= minX &&
      other.minY >= minY &&
      other.maxX <= maxX &&
      other.maxY <= maxY;

  bool overlaps(Rectangle other) =>
      !(other.maxX <= minX ||
          other.minX >= maxX ||
          other.maxY <= minY ||
          other.minY >= maxY);

  Rectangle union(Rectangle other) {
    if (isEmpty) return other;
    if (other.isEmpty) return this;
    return Rectangle(
      minX: math.min(minX, other.minX),
      minY: math.min(minY, other.minY),
      maxX: math.max(maxX, other.maxX),
      maxY: math.max(maxY, other.maxY),
    );
  }

  Rectangle intersect(Rectangle other) {
    final minX = math.max(this.minX, other.minX);
    final minY = math.max(this.minY, other.minY);
    final maxX = math.min(this.maxX, other.maxX);
    final maxY = math.min(this.maxY, other.maxY);
    if (minX >= maxX || minY >= maxY) {
      return const Rectangle(minX: 0, minY: 0, maxX: 0, maxY: 0);
    }
    return Rectangle(minX: minX, minY: minY, maxX: maxX, maxY: maxY);
  }

  @override
  bool operator ==(Object other) =>
      other is Rectangle &&
      other.minX == minX &&
      other.minY == minY &&
      other.maxX == maxX &&
      other.maxY == maxY;

  @override
  int get hashCode => Object.hash(minX, minY, maxX, maxY);
}

Rectangle rect(int x, int y, int width, int height) =>
    Rectangle(minX: x, minY: y, maxX: x + width, maxY: y + height);
