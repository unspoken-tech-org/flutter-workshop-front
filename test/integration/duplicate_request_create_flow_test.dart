import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/http/interceptors/duplicate_request_interceptor.dart';
import 'package:flutter_workshop_front/core/http/interceptors/global_error_interceptor.dart';

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
  group('Duplicate Request Create Flow Integration Tests', () {
    test('duplo clique em create nao propaga erro de requisicao duplicada',
        () async {
      var requestCount = 0;

      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://example.test',
          validateStatus: (status) => (status ?? 0) < 500,
        ),
      );

      dio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) async {
          requestCount += 1;
          await Future<void>.delayed(const Duration(milliseconds: 40));
          return const _AdapterResult(
            statusCode: 201,
            data: {'customerId': 123, 'name': 'Cliente Teste'},
          );
        },
      );

      dio.interceptors.add(DuplicateRequestInterceptor(milliseconds: 500));
      dio.interceptors.add(GlobalErrorInterceptor());

      final responses = await Future.wait([
        dio.post('/v1/customer', data: {'name': 'Cliente Teste'}),
        dio.post('/v1/customer', data: {'name': 'Cliente Teste'}),
      ]);

      expect(responses, hasLength(2));
      expect(responses[0].statusCode, 201);
      expect(responses[1].statusCode, 201);
      expect(requestCount, 1,
          reason:
              'Requisicoes duplicadas devem compartilhar a mesma execucao em voo.');
    });

    test(
        'quando create falha, duplicadas recebem o mesmo erro da request lider',
        () async {
      var requestCount = 0;

      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://example.test',
          validateStatus: (status) => (status ?? 0) < 500,
        ),
      );

      dio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) async {
          requestCount += 1;
          await Future<void>.delayed(const Duration(milliseconds: 40));
          return const _AdapterResult(
            statusCode: 500,
            data: {'error': 'falha de create'},
          );
        },
      );

      dio.interceptors.add(DuplicateRequestInterceptor(milliseconds: 500));
      dio.interceptors.add(GlobalErrorInterceptor());

      await expectLater(
        Future.wait([
          dio.post('/v1/customer', data: {'name': 'Cliente Teste'}),
          dio.post('/v1/customer', data: {'name': 'Cliente Teste'}),
        ]),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            500,
          ),
        ),
      );

      expect(requestCount, 1,
          reason:
              'Mesmo em erro, requisicoes duplicadas devem compartilhar uma unica execucao.');
    });
  });
}
