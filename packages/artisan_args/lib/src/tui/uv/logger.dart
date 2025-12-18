/// Logger is a simple logger interface for Ultraviolet internals.
///
/// Upstream: `third_party/ultraviolet/logger.go`.
abstract class Logger {
  void printf(String format, [List<Object?>? args]);
}

/// A logger that does nothing.
class NullLogger implements Logger {
  const NullLogger();
  @override
  void printf(String format, [List<Object?>? args]) {}
}
