import 'dart:async';

import 'package:flutter/foundation.dart';

import 'log_platform_stub.dart'
    if (dart.library.io) 'log_platform_io.dart'
    as platform;
import 'log_sanitizer.dart';
import 'log_sink.dart';

enum LogLevel { debug, info, warning, error }

/// App-wide logger persisted to rotating files on desktop.
///
/// Messages must describe events and codes only: never tokens, API keys,
/// `Authorization` headers or customer data (name, CPF, phone, e-mail).
/// Every message still passes through [LogSanitizer.redact] as a safeguard.
///
/// Logging never throws and never blocks: lines are queued and written
/// asynchronously; failures are ignored.
abstract final class AppLogger {
  static LogSink _sink = const NoopLogSink();

  /// Lowest level written. INFO in release/profile, DEBUG in debug builds.
  static LogLevel minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  /// Whether lines are mirrored to the console via [debugPrint].
  static bool mirrorToConsole = kDebugMode;

  /// Resolves the log directory and starts persisting lines. Safe to call
  /// once at startup; on any failure the logger stays a no-op.
  static Future<void> init() async {
    try {
      _sink = await platform.createDefaultLogSink().timeout(
        const Duration(seconds: 3),
      );
    } catch (e) {
      _sink = const NoopLogSink();
      if (mirrorToConsole) {
        debugPrint('[AppLogger] File logging disabled: ${e.runtimeType}');
      }
    }
  }

  /// Directory holding the log files, or `null` when not persisted.
  static String? get logDirectoryPath => _sink.directoryPath;

  /// Whether the "open logs folder" action makes sense on this platform.
  static bool get canOpenLogDirectory =>
      platform.supportsLogDirectory && logDirectoryPath != null;

  /// Short OS description for the startup line.
  static String describePlatform() {
    try {
      return platform.describePlatform();
    } catch (_) {
      return 'unknown';
    }
  }

  /// Opens the log directory in the system file manager.
  static Future<bool> openLogDirectory() async {
    final path = logDirectoryPath;
    if (path == null) return false;
    try {
      await _sink.flush();
      return await platform.openDirectory(path);
    } catch (e) {
      warning('AppLogger', 'Failed to open log directory', error: e);
      return false;
    }
  }

  static void debug(String tag, String message) =>
      log(LogLevel.debug, tag, message);

  static void info(String tag, String message) =>
      log(LogLevel.info, tag, message);

  static void warning(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      log(LogLevel.warning, tag, message, error: error, stackTrace: stackTrace);

  static void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);

  static void log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < minLevel.index) return;
    try {
      final buffer = StringBuffer()
        ..write(DateTime.now().toIso8601String())
        ..write(' ')
        ..write(level.name.toUpperCase().padRight(7))
        ..write(' [')
        ..write(tag)
        ..write('] ')
        ..write(LogSanitizer.redact(message));
      if (error != null) {
        buffer
          ..write(' | ')
          ..write(LogSanitizer.describeError(error));
      }
      if (stackTrace != null) {
        buffer
          ..write('\n')
          ..write(LogSanitizer.describeStack(stackTrace));
      }
      final line = buffer.toString();
      if (mirrorToConsole) debugPrint(line);
      _sink.write(line);
    } catch (_) {
      // Logging must never break the caller.
    }
  }

  /// Completes once queued lines are written (best-effort).
  static Future<void> flush() async {
    try {
      await _sink.flush();
    } catch (_) {}
  }

  @visibleForTesting
  static void setSinkForTesting(LogSink sink) => _sink = sink;
}
