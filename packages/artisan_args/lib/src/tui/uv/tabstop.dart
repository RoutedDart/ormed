/// Tab stop management.
///
/// Upstream: `third_party/ultraviolet/tabstop.go`.
final class TabStops {
  TabStops._(this.width, this.interval, this.stops);

  static const int defaultTabInterval = 8;

  final int interval;
  int width;
  List<int> stops;

  factory TabStops(int width, int interval) {
    final stops = List<int>.filled((width + (interval - 1)) ~/ interval, 0);
    final ts = TabStops._(width, interval, stops);
    ts._init(0, width);
    return ts;
  }

  factory TabStops.defaults(int cols) => TabStops(cols, defaultTabInterval);

  int getWidth() => width;

  void resize(int newWidth) {
    if (newWidth == width) return;

    if (newWidth < width) {
      final size = (newWidth + (interval - 1)) ~/ interval;
      stops = stops.sublist(0, size);
    } else {
      final size = (newWidth - width + (interval - 1)) ~/ interval;
      stops = [...stops, ...List<int>.filled(size, 0)];
    }

    _init(width, newWidth);
    width = newWidth;
  }

  bool isStop(int col) {
    final mask = _mask(col);
    final i = col >> 3;
    if (i < 0 || i >= stops.length) return false;
    return (stops[i] & mask) != 0;
  }

  int next(int col) => find(col, 1);
  int prev(int col) => find(col, -1);

  int find(int col, int delta) {
    if (delta == 0) return col;

    var prev = false;
    var count = delta;
    if (count < 0) {
      count = -count;
      prev = true;
    }

    while (count > 0) {
      if (!prev) {
        if (col >= width - 1) return col;
        col++;
      } else {
        if (col < 1) return col;
        col--;
      }

      if (isStop(col)) count--;
    }

    return col;
  }

  void set(int col) {
    final mask = _mask(col);
    stops[col >> 3] |= mask;
  }

  void reset(int col) {
    final mask = _mask(col);
    stops[col >> 3] &= ~mask;
  }

  void clear() {
    stops = List<int>.filled(stops.length, 0);
  }

  int _mask(int col) => 1 << (col & (interval - 1));

  void _init(int col, int width) {
    for (var x = col; x < width; x++) {
      if (x % interval == 0) {
        set(x);
      } else {
        reset(x);
      }
    }
  }
}
