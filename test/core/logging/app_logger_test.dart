import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/logging/app_logger.dart';
import 'package:flutter_workshop_front/core/logging/log_sanitizer.dart';
import 'package:flutter_workshop_front/core/logging/log_sink.dart';

class _MemorySink implements LogSink {
  final List<String> lines = [];

  @override
  String? get directoryPath => '/tmp/logs';

  @override
  void write(String line) => lines.add(line);

  @override
  Future<void> flush() async {}
}

class _ThrowingSink implements LogSink {
  @override
  String? get directoryPath => throw const FileSystemLikeException();

  @override
  void write(String line) => throw const FileSystemLikeException();

  @override
  Future<void> flush() async => throw const FileSystemLikeException();
}

class FileSystemLikeException implements Exception {
  const FileSystemLikeException();
}

void main() {
  late LogLevel originalLevel;
  late bool originalMirror;

  setUp(() {
    originalLevel = AppLogger.minLevel;
    originalMirror = AppLogger.mirrorToConsole;
    AppLogger.mirrorToConsole = false;
  });

  tearDown(() {
    AppLogger.minLevel = originalLevel;
    AppLogger.mirrorToConsole = originalMirror;
    AppLogger.setSinkForTesting(const NoopLogSink());
  });

  group('AppLogger', () {
    test('filters lines below minLevel', () {
      final sink = _MemorySink();
      AppLogger.setSinkForTesting(sink);
      AppLogger.minLevel = LogLevel.info;

      AppLogger.debug('Test', 'hidden');
      AppLogger.info('Test', 'shown');
      AppLogger.error('Test', 'failure', error: StateError('boom'));

      expect(sink.lines, hasLength(2));
      expect(sink.lines[0], contains('INFO    [Test] shown'));
      expect(sink.lines[1], contains('ERROR   [Test] failure | StateError'));
    });

    test('redacts secrets and customer data in messages', () {
      final sink = _MemorySink();
      AppLogger.setSinkForTesting(sink);

      AppLogger.info('Test', 'Authorization: Bearer abc.def.ghi');

      expect(sink.lines.single, isNot(contains('abc.def.ghi')));
    });

    test('never throws when the sink fails', () async {
      AppLogger.setSinkForTesting(_ThrowingSink());

      expect(() => AppLogger.info('Test', 'line'), returnsNormally);
      expect(
        () => AppLogger.error(
          'Test',
          'line',
          error: Exception('x'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
      await expectLater(AppLogger.flush(), completes);
    });
  });

  group('LogSanitizer', () {
    test('redacts tokens, keys and query strings', () {
      const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.c2lnbmF0dXJlLXZhbHVl';
      final result = LogSanitizer.redact(
        'Authorization: Bearer $jwt x-api-key=sk_live_123 '
        'refreshToken: "r3fr3sh" GET https://api.test/customers?name=Maria',
      );

      expect(result, isNot(contains(jwt)));
      expect(result, isNot(contains('sk_live_123')));
      expect(result, isNot(contains('r3fr3sh')));
      expect(result, isNot(contains('Maria')));
      expect(result, contains('https://api.test/customers?[REDACTED]'));
    });

    test('redacts e-mail, CPF and phone numbers', () {
      final result = LogSanitizer.redact(
        'cliente joao.silva@example.com cpf 123.456.789-09 '
        'cpf2 12345678909 tel (11) 98765-4321 tel2 11987654321',
      );

      expect(result, isNot(contains('joao.silva@example.com')));
      expect(result, isNot(contains('123.456.789-09')));
      expect(result, isNot(contains('12345678909')));
      expect(result, isNot(contains('98765-4321')));
      expect(result, isNot(contains('11987654321')));
    });

    test('keeps versions and diagnostic numbers intact', () {
      const message =
          'current=1.6.2 latest=1.7.0 status=404 '
          'Download progress: 50% (1048576/2097152 bytes)';

      expect(LogSanitizer.redact(message), message);
    });

    test('summarizes DioException without headers, body or query', () {
      final error = DioException(
        requestOptions: RequestOptions(
          path: 'https://api.test/customers?cpf=12345678909',
          method: 'GET',
          headers: {'Authorization': 'Bearer secret-token'},
        ),
        response: Response<dynamic>(
          requestOptions: RequestOptions(),
          statusCode: 500,
          data: {'name': 'Maria'},
        ),
        type: DioExceptionType.badResponse,
      );

      final description = LogSanitizer.describeError(error);

      expect(
        description,
        'DioException(type=badResponse, status=500, GET /customers)',
      );
    });

    test('truncates long error descriptions', () {
      final description = LogSanitizer.describeError(Exception('x' * 5000));

      expect(description.length, lessThan(LogSanitizer.maxErrorLength + 20));
      expect(description, endsWith('... (truncated)'));
    });
  });
}
