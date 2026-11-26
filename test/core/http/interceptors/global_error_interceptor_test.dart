import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/core/http/interceptors/global_error_interceptor.dart';
import 'package:flutter_workshop_front/core/ui/ui_message.dart';

class _FixedAdapter implements HttpClientAdapter {
  final int status;
  final String body;
  final Map<String, List<String>> headers;

  _FixedAdapter(this.status, this.body, {this.headers = const {}});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json; charset=utf-8'],
        ...headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Handler que só registra o que o interceptor repassou.
class _RecordingHandler extends ErrorInterceptorHandler {
  DioException? passed;

  @override
  void next(DioException error) => passed = error;
}

final _rateLimitBody = jsonEncode({
  'status': 429,
  'title': 'Muitas requisições',
  'error': {
    'code': 'rate.limited',
    'message': 'Limite de requisições excedido. Tente novamente em instantes.',
  },
});

DioException _error429({Object? data, bool silent = false}) {
  final options = RequestOptions(
    path: '/v1/brand',
    extra: {if (silent) 'silent': true},
  );
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: 429,
      data: data,
    ),
  );
}

void main() {
  group('CustomDio validateStatus', () {
    test('HTTP 429 vira DioException com o corpo ResponseError', () async {
      final dio = CustomDio(
        baseUri: Uri.parse('https://test.example.com'),
        onMessage: (_) {},
        adapter: _FixedAdapter(
          429,
          _rateLimitBody,
          headers: {
            'retry-after': ['10'],
          },
        ),
      ).createAuthDio();

      final error = await dio
          .get<dynamic>('/v1/brand', options: Options(extra: {'silent': true}))
          .then<DioException?>(
            (_) => null,
            onError: (Object e) => e as DioException,
          );

      expect(error, isNotNull);
      expect(error!.type, DioExceptionType.badResponse);
      expect(error.response?.statusCode, 429);
      expect(error.response?.headers.value('retry-after'), '10');
      expect(
        GlobalErrorInterceptor.tooManyRequestsMessage(error.response),
        'Limite de requisições excedido. Tente novamente em instantes.',
      );
    });

    test('4xx de negócio continua chegando como resposta', () async {
      final dio = CustomDio(
        baseUri: Uri.parse('https://test.example.com'),
        onMessage: (_) {},
        adapter: _FixedAdapter(422, '{}'),
      ).createAuthDio();

      final response = await dio.get<dynamic>('/v1/brand');

      expect(response.statusCode, 422);
    });
  });

  group('GlobalErrorInterceptor 429', () {
    test('mensagem usa error.message, depois title, depois fallback', () {
      Response<dynamic> response(Object? data) => Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 429,
        data: data,
      );

      expect(
        GlobalErrorInterceptor.tooManyRequestsMessage(
          response(jsonDecode(_rateLimitBody)),
        ),
        'Limite de requisições excedido. Tente novamente em instantes.',
      );
      expect(
        GlobalErrorInterceptor.tooManyRequestsMessage(
          response({'status': 429, 'title': 'Muitas requisições'}),
        ),
        'Muitas requisições',
      );
      for (final data in [null, '<html>429</html>', <String, dynamic>{}]) {
        expect(
          GlobalErrorInterceptor.tooManyRequestsMessage(response(data)),
          GlobalErrorInterceptor.tooManyRequestsFallbackMessage,
        );
      }
      expect(
        GlobalErrorInterceptor.tooManyRequestsMessage(null),
        GlobalErrorInterceptor.tooManyRequestsFallbackMessage,
      );
    });

    test('publica mensagem amigável e repassa o erro', () {
      final messages = <UiMessage>[];
      final handler = _RecordingHandler();
      final error = _error429(data: jsonDecode(_rateLimitBody));

      GlobalErrorInterceptor(onMessage: messages.add).onError(error, handler);

      expect(messages, hasLength(1));
      expect(messages.single, isA<UiError>());
      expect(
        messages.single.text,
        'Limite de requisições excedido. Tente novamente em instantes.',
      );
      expect(handler.passed, same(error));
    });

    test('usa fallback quando o corpo não é JSON da API', () {
      final messages = <UiMessage>[];

      GlobalErrorInterceptor(onMessage: messages.add).onError(
        _error429(data: '<html>Too Many Requests</html>'),
        _RecordingHandler(),
      );

      expect(
        messages.single.text,
        GlobalErrorInterceptor.tooManyRequestsFallbackMessage,
      );
    });

    test('respeita silent: true', () {
      final messages = <UiMessage>[];
      final handler = _RecordingHandler();

      GlobalErrorInterceptor(onMessage: messages.add).onError(
        _error429(data: jsonDecode(_rateLimitBody), silent: true),
        handler,
      );

      expect(messages, isEmpty);
      expect(handler.passed?.response?.statusCode, 429);
    });
  });
}
