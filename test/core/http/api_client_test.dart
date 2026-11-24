import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/http/api_client.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';

typedef _Handler = FutureOr<ResponseBody> Function(RequestOptions options);

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final _Handler handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, String body, {Map<String, List<String>>? h}) {
  return ResponseBody.fromString(
    body,
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      ...?h,
    },
  );
}

/// Mesmo `validateStatus` do `CustomDio`: 401/403/429/5xx viram DioException.
ApiClient _client(_Handler handler) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://test.example.com',
      validateStatus: (s) => s! < 500 && s != 401 && s != 403 && s != 429,
    ),
  )..httpClientAdapter = _FakeAdapter(handler);
  return ApiClient(dio: dio);
}

Future<Result<String>> _get(
  ApiClient client, {
  Set<int> expected = const {200},
}) {
  return client.send(
    (dio) => dio.get<dynamic>('/x'),
    expectedStatus: expected,
    decode: (data) => asJsonMap(data)['name'] as String,
  );
}

AppFailure _failure(Result<Object?> result) {
  expect(result, isA<Err<Object?>>());
  return (result as Err<Object?>).failure;
}

void main() {
  group('ApiClient.send', () {
    test('devolve Ok com o corpo decodificado no status esperado', () async {
      final client = _client((_) => _json(200, '{"name":"ana"}'));

      final result = await _get(client);

      expect(result, isA<Ok<String>>());
      expect((result as Ok<String>).value, 'ana');
    });

    test('aceita qualquer status do conjunto esperado', () async {
      final client = _client((_) => _json(201, '{"name":"novo"}'));

      final result = await _get(client, expected: {200, 201});

      expect(result.valueOrNull, 'novo');
    });

    test('2xx fora do esperado vira UnexpectedFailure', () async {
      final client = _client((_) => _json(200, '{"name":"ana"}'));

      final result = await _get(client, expected: {201});

      expect(_failure(result), isA<UnexpectedFailure>());
    });

    test('400 com corpo da API preserva mensagem e código', () async {
      final client = _client(
        (_) => _json(
          400,
          '{"error":{"code":"payment.invalid","message":"Valor inválido"}}',
        ),
      );

      final failure = _failure(await _get(client));

      expect(failure, isA<ValidationFailure>());
      failure as ValidationFailure;
      expect(failure.message, 'Valor inválido');
      expect(failure.code, 'payment.invalid');
      expect(failure.statusCode, 400);
      expect(failure.messageOr('fallback'), 'Valor inválido');
    });

    test('404 e 409 têm falhas próprias', () async {
      final notFound = _client(
        (_) => _json(404, '{"error":{"code":"x.nf","message":"Não achei"}}'),
      );
      final conflict = _client(
        (_) => _json(409, '{"error":{"code":"x.c","message":"Conflito"}}'),
      );

      expect(_failure(await _get(notFound)), isA<NotFoundFailure>());
      expect(_failure(await _get(conflict)), isA<ConflictFailure>());
    });

    test('4xx com corpo que não é Map não lança TypeError', () async {
      final client = _client(
        (_) => ResponseBody.fromString(
          '<html>bad gateway</html>',
          422,
          headers: {
            Headers.contentTypeHeader: ['text/html'],
          },
        ),
      );

      final failure = _failure(await _get(client));

      expect(failure, isA<ValidationFailure>());
      expect(
        failure.messageOr('fallback'),
        'Erro na requisição (status 422). Tente novamente.',
      );
    });

    test('4xx com error que é lista também é tolerado', () async {
      final client = _client((_) => _json(400, '{"error":["a","b"]}'));

      expect(_failure(await _get(client)), isA<ValidationFailure>());
    });

    test('401 e 403 viram SessionFailure e usam o fallback', () async {
      for (final status in [401, 403]) {
        final client = _client((_) => _json(status, '{}'));

        final failure = _failure(await _get(client));

        expect(failure, isA<SessionFailure>());
        expect((failure as SessionFailure).statusCode, status);
        expect(failure.messageOr('fallback'), 'fallback');
      }
    });

    test('429 vira RateLimitedFailure com Retry-After', () async {
      final client = _client(
        (_) => _json(
          429,
          '{"error":{"code":"rate","message":"Calma"}}',
          h: {
            'retry-after': ['7'],
          },
        ),
      );

      final failure = _failure(await _get(client));

      expect(failure, isA<RateLimitedFailure>());
      failure as RateLimitedFailure;
      expect(failure.retryAfter, const Duration(seconds: 7));
      expect(failure.message, 'Calma');
    });

    test('5xx vira ServerFailure e usa o fallback', () async {
      final client = _client(
        (_) => _json(500, '{"error":{"code":"boom","message":"Interno"}}'),
      );

      final failure = _failure(await _get(client));

      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 500);
      expect(failure.messageOr('fallback'), 'fallback');
    });

    test('5xx com corpo não-Map não lança', () async {
      final client = _client(
        (_) => ResponseBody.fromString(
          'oops',
          502,
          headers: {
            Headers.contentTypeHeader: ['text/plain'],
          },
        ),
      );

      expect(_failure(await _get(client)), isA<ServerFailure>());
    });

    test('timeout vira NetworkFailure', () async {
      final client = _client(
        (options) => throw DioException.connectionTimeout(
          timeout: const Duration(seconds: 1),
          requestOptions: options,
        ),
      );

      expect(_failure(await _get(client)), isA<NetworkFailure>());
    });

    test('erro de conexão vira NetworkFailure', () async {
      final client = _client(
        (options) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'sem rede',
        ),
      );

      expect(_failure(await _get(client)), isA<NetworkFailure>());
    });

    test('SocketException embrulhada em unknown vira NetworkFailure', () async {
      final client = _client(
        (options) => throw DioException(
          requestOptions: options,
          error: const SocketException('down'),
        ),
      );

      expect(_failure(await _get(client)), isA<NetworkFailure>());
    });

    test('cancelamento vira UnexpectedFailure', () async {
      final client = _client(
        (options) => throw DioException.requestCancelled(
          requestOptions: options,
          reason: 'logout',
        ),
      );

      expect(_failure(await _get(client)), isA<UnexpectedFailure>());
    });

    test('corpo em formato inesperado vira UnexpectedFailure', () async {
      final client = _client((_) => _json(200, '[1,2,3]'));

      final failure = _failure(await _get(client));

      expect(failure, isA<UnexpectedFailure>());
      expect(failure.messageOr('fallback'), 'fallback');
    });

    test('exceção qualquer no call vira UnexpectedFailure', () async {
      final client = _client((_) => _json(200, '{}'));

      final result = await client.send<String>(
        (dio) => throw StateError('x'),
        decode: (_) => 'nunca',
      );

      expect(_failure(result), isA<UnexpectedFailure>());
    });
  });

  group('Result', () {
    test('map transforma Ok e preserva Err', () {
      expect(const Ok(2).map((v) => v * 2).valueOrNull, 4);
      const err = Err<int>(NetworkFailure());
      expect(err.map((v) => v * 2), isA<Err<int>>());
    });
  });
}
