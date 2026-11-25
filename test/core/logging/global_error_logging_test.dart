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
      final originalPresentError = FlutterError.presentError;
      final originalPlatformOnError = PlatformDispatcher.instance.onError;
      final originalDebugPrint = debugPrint;
      final printed = <String>[];
      debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
      FlutterError.presentError = FlutterError.dumpErrorToConsole;
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
        FlutterError.presentError = originalPresentError;
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

    test(
      'replaces structured error presenter so repeated errors dump in full',
      () {
        final originalOnError = FlutterError.onError;
        final originalPresentError = FlutterError.presentError;
        final originalPlatformOnError = PlatformDispatcher.instance.onError;
        final originalDebugPrint = debugPrint;
        final printed = <String>[];
        var structuredCalls = 0;
        void fakeStructuredError(FlutterErrorDetails details) {
          structuredCalls += 1;
          printed.add(
            structuredCalls == 1
                ? 'STRUCTURED ${details.exception}'
                : 'Another exception was thrown: ${details.summary}',
          );
        }

        debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
        FlutterError.presentError = fakeStructuredError;
        FlutterError.onError = fakeStructuredError;
        try {
          installGlobalErrorLogging();

          for (final id in ['first', 'second', 'third']) {
            FlutterError.onError!(
              FlutterErrorDetails(
                exception: FlutterError('overflow $id'),
                library: 'rendering library',
              ),
            );
          }
        } finally {
          FlutterError.onError = originalOnError;
          FlutterError.presentError = originalPresentError;
          PlatformDispatcher.instance.onError = originalPlatformOnError;
          debugPrint = originalDebugPrint;
          FlutterError.resetErrorCount();
        }

        final output = printed.join('\n');
        expect(structuredCalls, 0);
        expect(output, contains('overflow first'));
        expect(output, contains('overflow second'));
        expect(output, contains('overflow third'));
        expect(output, isNot(contains('Another exception was thrown')));
        expect(
          'EXCEPTION CAUGHT BY RENDERING LIBRARY'.allMatches(output),
          hasLength(3),
        );
        expect(sink.lines, hasLength(3));
      },
    );

    test(
      'keeps full console output and chained wrapper when configured before ErrorMonitor',
      () {
        final originalOnError = FlutterError.onError;
        final originalPresentError = FlutterError.presentError;
        final originalPlatformOnError = PlatformDispatcher.instance.onError;
        final originalDebugPrint = debugPrint;
        final printed = <String>[];
        final monitorEvents = <String>[];
        var structuredCalls = 0;
        void fakeStructuredError(FlutterErrorDetails details) {
          structuredCalls += 1;
          printed.add(
            structuredCalls == 1
                ? 'STRUCTURED ${details.exception}'
                : 'Another exception was thrown: ${details.summary}',
          );
        }

        debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
        // Simulate WidgetsFlutterBinding.ensureInitialized() installing
        // WidgetInspectorService._reportStructuredError.
        FlutterError.presentError = fakeStructuredError;
        FlutterError.onError = fakeStructuredError;
        try {
          // Simulate agent_toolkit's ensureInitialized hook running before
          // MCPToolkitBinding.initialize() -> ErrorMonitor.attachToFlutterError().
          configureVerboseDebugFlutterErrors();

          final previousForMonitor = FlutterError.onError;
          FlutterError.onError = (details) {
            previousForMonitor?.call(details);
            monitorEvents.add(details.exceptionAsString());
          };

          installGlobalErrorLogging();

          for (final id in ['first', 'second', 'third']) {
            FlutterError.onError!(
              FlutterErrorDetails(
                exception: FlutterError('overflow $id'),
                library: 'rendering library',
              ),
            );
          }
        } finally {
          FlutterError.onError = originalOnError;
          FlutterError.presentError = originalPresentError;
          PlatformDispatcher.instance.onError = originalPlatformOnError;
          debugPrint = originalDebugPrint;
          FlutterError.resetErrorCount();
        }

        final output = printed.join('\n');
        expect(structuredCalls, 0);
        expect(monitorEvents, hasLength(3));
        expect(output, contains('overflow first'));
        expect(output, contains('overflow second'));
        expect(output, contains('overflow third'));
        expect(output, isNot(contains('Another exception was thrown')));
        expect(
          'EXCEPTION CAUGHT BY RENDERING LIBRARY'.allMatches(output),
          hasLength(3),
        );
        expect(sink.lines, hasLength(3));
      },
    );

    test(
      'configureVerboseDebugFlutterErrors preserves a custom FlutterError.onError',
      () {
        final originalOnError = FlutterError.onError;
        final originalPresentError = FlutterError.presentError;
        var customCalls = 0;
        void customHandler(FlutterErrorDetails details) {
          customCalls += 1;
        }

        FlutterError.presentError = FlutterError.dumpErrorToConsole;
        FlutterError.onError = customHandler;
        try {
          configureVerboseDebugFlutterErrors();
          FlutterError.onError!(
            FlutterErrorDetails(exception: FlutterError('custom')),
          );
        } finally {
          FlutterError.onError = originalOnError;
          FlutterError.presentError = originalPresentError;
        }

        expect(customCalls, 1);
      },
    );
  });
}
