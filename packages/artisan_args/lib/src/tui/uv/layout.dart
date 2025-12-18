import 'geometry.dart';

/// Layout constraints.
///
/// Upstream: `third_party/ultraviolet/layout.go`.
abstract interface class Constraint {
  int apply(int size);
}

/// A constraint that represents a percentage of the available size.
///
/// Upstream: `type Percent int`.
final class Percent implements Constraint {
  const Percent(this.value);

  final int value;

  @override
  int apply(int size) {
    if (value < 0) return 0;
    if (value > 100) return size;
    return (size * value) ~/ 100;
  }
}

/// Syntactic sugar for [Percent].
///
/// Upstream: `Ratio(numerator, denominator int) Percent`.
Percent ratio(int numerator, int denominator) {
  if (denominator == 0) return const Percent(0);
  return Percent((numerator * 100) ~/ denominator);
}

/// A constraint that represents a fixed size.
///
/// Upstream: `type Fixed int`.
final class Fixed implements Constraint {
  const Fixed(this.value);

  final int value;

  @override
  int apply(int size) {
    if (value < 0) return 0;
    if (value > size) return size;
    return value;
  }
}

/// Splits [area] vertically into top/bottom.
///
/// Upstream: `SplitVertical` in `third_party/ultraviolet/layout.go`.
({Rectangle top, Rectangle bottom}) splitVertical(
  Rectangle area,
  Constraint c,
) {
  final height = (c.apply(area.height) < area.height)
      ? c.apply(area.height)
      : area.height;
  final top = Rectangle(
    minX: area.minX,
    minY: area.minY,
    maxX: area.maxX,
    maxY: area.minY + height,
  );
  final bottom = Rectangle(
    minX: area.minX,
    minY: area.minY + height,
    maxX: area.maxX,
    maxY: area.maxY,
  );
  return (top: top, bottom: bottom);
}

/// Splits [area] horizontally into left/right.
///
/// Upstream: `SplitHorizontal` in `third_party/ultraviolet/layout.go`.
({Rectangle left, Rectangle right}) splitHorizontal(
  Rectangle area,
  Constraint c,
) {
  final width = (c.apply(area.width) < area.width)
      ? c.apply(area.width)
      : area.width;
  final left = Rectangle(
    minX: area.minX,
    minY: area.minY,
    maxX: area.minX + width,
    maxY: area.maxY,
  );
  final right = Rectangle(
    minX: area.minX + width,
    minY: area.minY,
    maxX: area.maxX,
    maxY: area.maxY,
  );
  return (left: left, right: right);
}
