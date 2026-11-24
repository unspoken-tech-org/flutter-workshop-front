import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'log_sink.dart';

/// Appends log lines to `<directory>/<baseName>.log`, rotating by size.
///
/// When the active file would exceed [maxBytes], it is renamed to
/// `<baseName>.1.log`, older files shift up by one and the oldest is removed,
/// so at most [maxFiles] files exist (the active one included).
///
/// Writes are buffered and drained asynchronously, one drain at a time, so
/// callers never wait on disk. Any I/O failure is swallowed on purpose:
/// logging is diagnostic only and must never crash or block the app. After
/// [_maxConsecutiveFailures] failed drains the sink disables itself.
class RotatingFileSink implements LogSink {
  static const int _maxConsecutiveFailures = 5;
  static const int _maxBufferedChars = 1024 * 1024;

  final Directory directory;
  final String baseName;
  final int maxBytes;
  final int maxFiles;

  final StringBuffer _buffer = StringBuffer();
  Future<void> _pending = Future<void>.value();
  bool _drainScheduled = false;
  bool _ready = false;
  bool _disabled = false;
  int _consecutiveFailures = 0;
  int _currentSize = 0;

  RotatingFileSink({
    required this.directory,
    this.baseName = 'app',
    this.maxBytes = 2 * 1024 * 1024,
    this.maxFiles = 5,
  }) : assert(maxBytes > 0),
       assert(maxFiles >= 1);

  @override
  String get directoryPath => directory.path;

  /// Whether the sink gave up after repeated I/O failures.
  bool get isDisabled => _disabled;

  File get _activeFile => _fileAt(0);

  File _fileAt(int index) {
    final name = index == 0 ? '$baseName.log' : '$baseName.$index.log';
    return File('${directory.path}${Platform.pathSeparator}$name');
  }

  @override
  void write(String line) {
    if (_disabled) return;
    if (_buffer.length + line.length > _maxBufferedChars) {
      // Disk is not keeping up; drop instead of growing memory unbounded.
      return;
    }
    _buffer.writeln(line);
    if (_drainScheduled) return;
    _drainScheduled = true;
    _pending = _pending.then((_) => _drain());
  }

  @override
  Future<void> flush() => _pending;

  Future<void> _drain() async {
    _drainScheduled = false;
    if (_buffer.isEmpty) return;
    final chunk = _buffer.toString();
    _buffer.clear();
    if (_disabled) return;
    try {
      await _ensureReady();
      final bytes = utf8.encode(chunk);
      if (_currentSize > 0 && _currentSize + bytes.length > maxBytes) {
        await _rotate();
      }
      await _activeFile.writeAsBytes(bytes, mode: FileMode.append);
      _currentSize += bytes.length;
      _consecutiveFailures = 0;
    } catch (_) {
      // Intentionally ignored: see class docs.
      _ready = false;
      _consecutiveFailures++;
      if (_consecutiveFailures >= _maxConsecutiveFailures) {
        _disabled = true;
      }
    }
  }

  Future<void> _ensureReady() async {
    if (_ready) return;
    await directory.create(recursive: true);
    final file = _activeFile;
    _currentSize = await file.exists() ? await file.length() : 0;
    _ready = true;
  }

  Future<void> _rotate() async {
    try {
      for (var i = maxFiles - 1; i >= 1; i--) {
        final source = _fileAt(i - 1);
        if (!await source.exists()) continue;
        final target = _fileAt(i);
        if (await target.exists()) await target.delete();
        await source.rename(target.path);
      }
      if (maxFiles == 1 && await _activeFile.exists()) {
        await _activeFile.delete();
      }
      _currentSize = 0;
    } catch (_) {
      // Rotation can fail when another process holds the file (e.g. a second
      // app instance on Windows). Keep appending to the active file instead
      // of losing the line; the next drain retries the rotation.
      final file = _activeFile;
      _currentSize = await file.exists() ? await file.length() : 0;
    }
  }
}
