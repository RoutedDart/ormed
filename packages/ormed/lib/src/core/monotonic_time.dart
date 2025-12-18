int _lastUtcMicroseconds = 0;

/// Returns a UTC timestamp that is monotonically increasing within this process.
///
/// Some environments (notably CI containers) may observe small wall-clock
/// adjustments that cause `DateTime.now()` to move backwards. Ormed uses this
/// helper for automatically managed timestamps (created_at/updated_at) so that
/// consecutive mutations never produce decreasing values.
DateTime monotonicNowUtc() {
  final now = DateTime.now().toUtc().microsecondsSinceEpoch;
  if (now <= _lastUtcMicroseconds) {
    _lastUtcMicroseconds += 1;
    return DateTime.fromMicrosecondsSinceEpoch(
      _lastUtcMicroseconds,
      isUtc: true,
    );
  }
  _lastUtcMicroseconds = now;
  return DateTime.fromMicrosecondsSinceEpoch(now, isUtc: true);
}
