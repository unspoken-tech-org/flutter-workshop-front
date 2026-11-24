import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/logging/rotating_file_sink.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('rotating_sink_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  File logFile(Directory dir, String name) =>
      File('${dir.path}${Platform.pathSeparator}$name');

  List<String> logNames(Directory dir) =>
      dir
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .toList()
        ..sort();

  test('creates the directory and appends lines to app.log', () async {
    final dir = Directory('${tempDir.path}${Platform.pathSeparator}logs');
    final sink = RotatingFileSink(directory: dir);

    sink.write('first');
    sink.write('second');
    await sink.flush();

    expect(await logFile(dir, 'app.log').readAsString(), 'first\nsecond\n');
  });

  test('rotates by size and keeps at most maxFiles files', () async {
    final sink = RotatingFileSink(
      directory: tempDir,
      maxBytes: 20,
      maxFiles: 3,
    );

    // Each line is 10 bytes with the newline, so every file holds two lines.
    for (var i = 0; i < 10; i++) {
      sink.write('line-${i.toString().padLeft(3, '0')}');
      await sink.flush();
    }

    expect(logNames(tempDir), ['app.1.log', 'app.2.log', 'app.log']);
    expect(
      await logFile(tempDir, 'app.log').readAsString(),
      'line-008\nline-009\n',
    );
    expect(
      await logFile(tempDir, 'app.1.log').readAsString(),
      'line-006\nline-007\n',
    );
    expect(
      await logFile(tempDir, 'app.2.log').readAsString(),
      'line-004\nline-005\n',
    );
    for (final name in logNames(tempDir)) {
      expect(await logFile(tempDir, name).length(), lessThanOrEqualTo(20));
    }
  });

  test('takes the size of an existing app.log into account', () async {
    await logFile(tempDir, 'app.log').writeAsString('previous-run\n');
    final sink = RotatingFileSink(directory: tempDir, maxBytes: 20);

    sink.write('new-run-line');
    await sink.flush();

    expect(
      await logFile(tempDir, 'app.1.log').readAsString(),
      'previous-run\n',
    );
    expect(await logFile(tempDir, 'app.log').readAsString(), 'new-run-line\n');
  });

  test('maxFiles = 1 truncates instead of keeping backups', () async {
    final sink = RotatingFileSink(
      directory: tempDir,
      maxBytes: 10,
      maxFiles: 1,
    );

    sink.write('aaaaaaaa');
    await sink.flush();
    sink.write('bbbbbbbb');
    await sink.flush();

    expect(logNames(tempDir), ['app.log']);
    expect(await logFile(tempDir, 'app.log').readAsString(), 'bbbbbbbb\n');
  });

  test('never throws when the directory cannot be created', () async {
    // A regular file where the log directory should be makes every I/O fail.
    final blocker = logFile(tempDir, 'not_a_dir');
    await blocker.writeAsString('x');
    final sink = RotatingFileSink(
      directory: Directory('${blocker.path}${Platform.pathSeparator}logs'),
    );

    for (var i = 0; i < 10; i++) {
      expect(() => sink.write('line $i'), returnsNormally);
      await expectLater(sink.flush(), completes);
    }

    expect(sink.isDisabled, isTrue);
    expect(() => sink.write('after disable'), returnsNormally);
    await expectLater(sink.flush(), completes);
  });

  test('recovers when the directory becomes writable again', () async {
    final dir = Directory('${tempDir.path}${Platform.pathSeparator}logs');
    await logFile(tempDir, 'logs').writeAsString('blocker');
    final sink = RotatingFileSink(directory: dir);

    sink.write('lost');
    await sink.flush();
    expect(sink.isDisabled, isFalse);

    await logFile(tempDir, 'logs').delete();
    sink.write('kept');
    await sink.flush();

    expect(await logFile(dir, 'app.log').readAsString(), 'kept\n');
  });
}
