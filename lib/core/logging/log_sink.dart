/// Destination for formatted log lines.
///
/// Implementations must never throw from [write] or [flush]: logging is
/// best-effort and an I/O failure must not affect the app.
abstract class LogSink {
  /// Directory holding the log files, or `null` when logs are not persisted.
  String? get directoryPath;

  /// Queues [line] for writing without blocking the caller.
  void write(String line);

  /// Completes once every queued line has been handled.
  Future<void> flush();
}

/// Sink used on platforms without file logging (web, mobile) and before
/// [AppLogger.init] runs.
class NoopLogSink implements LogSink {
  const NoopLogSink();

  @override
  String? get directoryPath => null;

  @override
  void write(String line) {}

  @override
  Future<void> flush() async {}
}
