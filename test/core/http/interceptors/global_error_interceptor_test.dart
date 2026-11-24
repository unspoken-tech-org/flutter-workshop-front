import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/core/http/interceptors/global_error_interceptor.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

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

Future<void> _pumpHost(WidgetTester tester) {
  return tester.pumpWidget(
    MaterialApp(
      navigatorKey: SnackBarUtil().navigatorKey,
      home: const Scaffold(body: SizedBox.shrink()),
    ),
  );
}

void main() {
  group('CustomDio validateStatus', () {
    test('HTTP 429 vira DioException com o corpo ResponseError', () async {
      final dio = CustomDio(
        baseUri: Uri.parse('https://test.example.com'),
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

    testWidgets('exibe mensagem amigável e repassa o erro', (tester) async {
      await _pumpHost(tester);
      final handler = _RecordingHandler();
      final error = _error429(data: jsonDecode(_rateLimitBody));

      GlobalErrorInterceptor().onError(error, handler);
      await tester.pump();

      expect(
        find.text(
          'Limite de requisições excedido. Tente novamente em instantes.',
        ),
        findsOneWidget,
      );
      expect(handler.passed, same(error));

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('usa fallback quando o corpo não é JSON da API', (
      tester,
    ) async {
      await _pumpHost(tester);

      GlobalErrorInterceptor().onError(
        _error429(data: '<html>Too Many Requests</html>'),
        _RecordingHandler(),
      );
      await tester.pump();

      expect(
        find.text(GlobalErrorInterceptor.tooManyRequestsFallbackMessage),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('respeita silent: true', (tester) async {
      await _pumpHost(tester);
      final handler = _RecordingHandler();

      GlobalErrorInterceptor().onError(
        _error429(data: jsonDecode(_rateLimitBody), silent: true),
        handler,
      );
      await tester.pump();

      expect(
        find.text(
          'Limite de requisições excedido. Tente novamente em instantes.',
        ),
        findsNothing,
      );
      expect(handler.passed?.response?.statusCode, 429);
    });
  });
}
