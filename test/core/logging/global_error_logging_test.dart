import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/logging/app_logger.dart';
import 'package:flutter_workshop_front/core/logging/global_error_logging.dart';
import 'package:flutter_workshop_front/core/logging/log_sink.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _MemorySink implements LogSink {
  final List<String> lines = [];

  @override
  String? get directoryPath => null;

  @override
  void write(String line) => lines.add(line);

  @override
  Future<void> flush() async {}
}

PackageInfo _info(String buildNumber) => PackageInfo(
  appName: 'Workshop',
  packageName: 'flutter_workshop_front',
  version: '1.7.1',
  buildNumber: buildNumber,
);

void main() {
  late _MemorySink sink;
  late bool originalMirror;

  setUp(() {
    originalMirror = AppLogger.mirrorToConsole;
    AppLogger.mirrorToConsole = false;
    sink = _MemorySink();
    AppLogger.setSinkForTesting(sink);
  });

  tearDown(() {
    AppLogger.mirrorToConsole = originalMirror;
    AppLogger.setSinkForTesting(const NoopLogSink());
  });

  group('logAppStart', () {
    test('omits the build number when it is empty', () async {
      await logAppStart(packageInfoLoader: () async => _info(''));

      expect(sink.lines.single, contains('version=1.7.1 '));
    });

    test('appends the build number when present', () async {
      await logAppStart(packageInfoLoader: () async => _info('42'));

      expect(sink.lines.single, contains('version=1.7.1+42 '));
    });
  });

  group('installGlobalErrorLogging', () {
    test('presents every FlutterError in full, not only the first', () {
      final originalOnError = FlutterError.onError;
      final originalPlatformOnError = PlatformDispatcher.instance.onError;
      final originalDebugPrint = debugPrint;
      final printed = <String>[];
      debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
      FlutterError.onError = FlutterError.dumpErrorToConsole;
      try {
        installGlobalErrorLogging();

        for (final id in ['first', 'second']) {
          FlutterError.onError!(
            FlutterErrorDetails(
              exception: FlutterError('overflow $id'),
              library: 'rendering library',
            ),
          );
        }
      } finally {
        FlutterError.onError = originalOnError;
        PlatformDispatcher.instance.onError = originalPlatformOnError;
        debugPrint = originalDebugPrint;
        FlutterError.resetErrorCount();
      }

      final output = printed.join('\n');
      expect(output, contains('overflow second'));
      expect(output, isNot(contains('Another exception was thrown')));
      expect(
        'EXCEPTION CAUGHT BY RENDERING LIBRARY'.allMatches(output),
        hasLength(2),
      );
    });
  });
}
