import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/http/interceptors/duplicate_request_interceptor.dart';

class _AdapterResult {
  final int statusCode;
  final Object? data;

  const _AdapterResult({required this.statusCode, this.data});
}

class _TestHttpClientAdapter implements HttpClientAdapter {
  final FutureOr<_AdapterResult> Function(RequestOptions options) responder;

  _TestHttpClientAdapter({required this.responder});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final result = await responder(options);
    final body = result.data == null ? '' : jsonEncode(result.data);

    return ResponseBody.fromString(
      body,
      result.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('DuplicateRequestInterceptor', () {
    late Dio dio;
    late int requestCount;

    setUp(() {
      requestCount = 0;
      dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) async {
          requestCount += 1;
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return const _AdapterResult(statusCode: 200, data: {'ok': true});
        },
      );
      dio.interceptors.add(DuplicateRequestInterceptor(milliseconds: 100));
    });

    test('deve coalescer requests identicas concorrentes dentro da janela',
        () async {
      final firstCall = dio.post('/device', data: {'name': 'A'});
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final secondCall = dio.post('/device', data: {'name': 'A'});

      final responses = await Future.wait([firstCall, secondCall]);

      expect(responses[0].statusCode, 200);
      expect(responses[1].statusCode, 200);
      expect(requestCount, 1);
    });

    test('deve reutilizar resposta recente para request identica na janela',
        () async {
      await dio.post('/device', data: {'name': 'A'});
      final response = await dio.post('/device', data: {'name': 'A'});

      expect(response.statusCode, 200);
      expect(requestCount, 1);
    });

    test('deve permitir nova request identica apos expirar janela', () async {
      await dio.post('/device', data: {'name': 'A'});
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final response = await dio.post('/device', data: {'name': 'A'});

      expect(response.statusCode, 200);
      expect(requestCount, 2);
    });

    test('deve ignorar duplicidade quando isAuthRetry=true', () async {
      await dio.post('/device', data: {'name': 'A'});

      final response = await dio.post(
        '/device',
        data: {'name': 'A'},
        options: Options(extra: {'isAuthRetry': true}),
      );

      expect(response.statusCode, 200);
      expect(requestCount, 2);
    });

    test('deve ignorar duplicidade quando bypassDuplicateCheck=true', () async {
      await dio.post('/device', data: {'name': 'A'});

      final response = await dio.post(
        '/device',
        data: {'name': 'A'},
        options: Options(extra: {'bypassDuplicateCheck': true}),
      );

      expect(response.statusCode, 200);
      expect(requestCount, 2);
    });

    test('nao deve coalescer quando payload for diferente', () async {
      await dio.post('/device', data: {'name': 'A'});
      final response = await dio.post('/device', data: {'name': 'B'});

      expect(response.statusCode, 200);
      expect(requestCount, 2);
    });

    test(
        'ordem diferente de campos no payload deve manter comportamento previsivel',
        () async {
      await dio.post('/device', data: {'a': 1, 'b': 2});
      final response = await dio.post('/device', data: {'b': 2, 'a': 1});

      expect(response.statusCode, 200);
      expect(requestCount, 2);
    });

    test('nao deve coalescer quando query params forem diferentes', () async {
      await dio
          .post('/device', queryParameters: {'page': 1}, data: {'name': 'A'});
      final response = await dio.post(
        '/device',
        queryParameters: {'page': 2},
        data: {'name': 'A'},
      );

      expect(response.statusCode, 200);
      expect(requestCount, 2);
    });

    test('deve coalescer burst alto de requests identicas', () async {
      final responses = await Future.wait(
        List.generate(
          20,
          (_) => dio.post('/device', data: {'name': 'Burst'}),
        ),
      );

      expect(responses, hasLength(20));
      expect(responses.every((r) => r.statusCode == 200), isTrue);
      expect(requestCount, 1);
    });

    test('deve propagar erro da request lider para duplicadas', () async {
      var errorCount = 0;
      final failingDio = Dio(
        BaseOptions(
          baseUrl: 'https://example.test',
          validateStatus: (status) => (status ?? 0) < 500,
        ),
      );
      failingDio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) async {
          errorCount += 1;
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return const _AdapterResult(statusCode: 500, data: {'error': 'boom'});
        },
      );
      failingDio.interceptors
          .add(DuplicateRequestInterceptor(milliseconds: 100));

      final first = failingDio.post('/device', data: {'name': 'A'});
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final second = failingDio.post('/device', data: {'name': 'A'});

      await expectLater(
        Future.wait([first, second]),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
      expect(errorCount, 1);
    });

    test('apos erro, nova request identica deve executar novamente', () async {
      var calls = 0;
      final flakyDio = Dio(
        BaseOptions(
          baseUrl: 'https://example.test',
          validateStatus: (status) => (status ?? 0) < 500,
        ),
      );
      flakyDio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) async {
          calls += 1;
          if (calls == 1) {
            return const _AdapterResult(
                statusCode: 500, data: {'error': 'boom'});
          }
          return const _AdapterResult(statusCode: 201, data: {'ok': true});
        },
      );
      flakyDio.interceptors.add(DuplicateRequestInterceptor(milliseconds: 100));

      await expectLater(
        flakyDio.post('/device', data: {'name': 'A'}),
        throwsA(isA<DioException>()),
      );

      final response = await flakyDio.post('/device', data: {'name': 'A'});
      expect(response.statusCode, 201);
      expect(calls, 2);
    });

    test('deve respeitar fronteira da janela de coalescencia', () async {
      final windowDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      var calls = 0;
      windowDio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) async {
          calls += 1;
          return const _AdapterResult(statusCode: 200, data: {'ok': true});
        },
      );
      windowDio.interceptors.add(DuplicateRequestInterceptor(milliseconds: 80));

      await windowDio.post('/device', data: {'name': 'A'});
      await Future<void>.delayed(const Duration(milliseconds: 40));
      await windowDio.post('/device', data: {'name': 'A'});
      expect(calls, 1);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      await windowDio.post('/device', data: {'name': 'A'});
      expect(calls, 2);
    });

    test('deve propagar timeout da request lider para duplicadas', () async {
      var calls = 0;
      final timeoutDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      timeoutDio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (options) async {
          calls += 1;
          await Future<void>.delayed(const Duration(milliseconds: 30));
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
          );
        },
      );
      timeoutDio.interceptors
          .add(DuplicateRequestInterceptor(milliseconds: 100));

      final first = timeoutDio.post('/device', data: {'name': 'A'});
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final second = timeoutDio.post('/device', data: {'name': 'A'});

      await expectLater(
        Future.wait([first, second]),
        throwsA(
          isA<DioException>().having(
              (e) => e.type, 'type', DioExceptionType.connectionTimeout),
        ),
      );
      expect(calls, 1);
    });
  });
}
