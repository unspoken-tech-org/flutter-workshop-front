import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/http/interceptors/global_error_interceptor.dart';
import 'package:flutter_workshop_front/core/ui/ui_message.dart';
import 'package:flutter_workshop_front/core/http/api_client.dart';
import 'package:flutter_workshop_front/core/logging/app_logger.dart';
import 'package:flutter_workshop_front/core/logging/log_sink.dart';
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

/// [_client] com o `GlobalErrorInterceptor` real, como no `CustomDio`.
ApiClient _clientWithGlobalErrors(_Handler handler, List<UiMessage> shown) {
  final dio =
      Dio(
          BaseOptions(
            baseUrl: 'https://test.example.com',
            validateStatus: (s) => s! < 500 && s != 401 && s != 403 && s != 429,
          ),
        )
        ..httpClientAdapter = _FakeAdapter(handler)
        ..interceptors.add(GlobalErrorInterceptor(onMessage: shown.add));
  return ApiClient(dio);
}

/// Mesmo `validateStatus` do `CustomDio`: 401/403/429/5xx viram DioException.
ApiClient _client(_Handler handler) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://test.example.com',
      validateStatus: (s) => s! < 500 && s != 401 && s != 403 && s != 429,
    ),
  )..httpClientAdapter = _FakeAdapter(handler);
  return ApiClient(dio);
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

class _MemorySink implements LogSink {
  final List<String> lines = [];

  @override
  String? get directoryPath => null;

  @override
  void write(String line) => lines.add(line);

  @override
  Future<void> flush() async {}
}

AppFailure _failure(Result<Object?> result) {
  expect(result, isA<Err<Object?>>());
  return (result as Err<Object?>).failure;
}

void main() {
  // Falhas esperadas nos testes não devem poluir a saída com logs.
  late bool mirrorBefore;
  setUp(() {
    mirrorBefore = AppLogger.mirrorToConsole;
    AppLogger.mirrorToConsole = false;
  });
  tearDown(() => AppLogger.mirrorToConsole = mirrorBefore);

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

  group('ApiClient.send com GlobalErrorInterceptor', () {
    test('falha já exibida pelo interceptor vem com shownGlobally', () async {
      final shown = <UiMessage>[];
      final offline = _clientWithGlobalErrors(
        (options) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'sem rede',
        ),
        shown,
      );
      final down = _clientWithGlobalErrors((_) => _json(503, '{}'), shown);

      expect(_failure(await _get(offline)).shownGlobally, isTrue);
      expect(_failure(await _get(down)).shownGlobally, isTrue);
      expect(shown, hasLength(2));
    });

    test(
      'falha que o interceptor não exibiu continua para o controller',
      () async {
        final shown = <UiMessage>[];
        final socket = _clientWithGlobalErrors(
          (options) => throw DioException(
            requestOptions: options,
            error: const SocketException('down'),
          ),
          shown,
        );
        final rejected = _clientWithGlobalErrors(
          (_) => _json(400, '{"error":{"code":"x","message":"Nome"}}'),
          shown,
        );

        final socketFailure = _failure(await _get(socket));
        expect(socketFailure, isA<NetworkFailure>());
        expect(socketFailure.shownGlobally, isFalse);
        expect(_failure(await _get(rejected)).shownGlobally, isFalse);
        expect(shown, isEmpty);
      },
    );

    test('requisição silent não marca shownGlobally', () async {
      final shown = <UiMessage>[];
      final client = _clientWithGlobalErrors((_) => _json(500, '{}'), shown);

      final result = await client.send(
        (dio) =>
            dio.get<dynamic>('/x', options: Options(extra: {'silent': true})),
        decode: (data) => data,
      );

      expect(_failure(result).shownGlobally, isFalse);
      expect(shown, isEmpty);
    });
  });

  group('ApiClient.send ProblemDetail (RFC 9457)', () {
    ResponseBody problem(
      int status,
      String body, {
      Map<String, List<String>>? h,
    }) {
      return ResponseBody.fromString(
        body,
        status,
        headers: {
          Headers.contentTypeHeader: ['application/problem+json'],
          ...?h,
        },
      );
    }

    test('400 com ProblemDetail preserva detail e code da raiz', () async {
      final client = _client(
        (_) => problem(
          400,
          '{"type":"about:blank","title":"Bad Request","status":400,'
          '"detail":"Valor inválido","code":"payment.invalid"}',
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

    test('400 com ProblemDetail sem detail usa title como mensagem', () async {
      final client = _client(
        (_) => problem(
          400,
          '{"type":"about:blank","title":"Dados inválidos","status":400,'
          '"code":"validation.failed"}',
        ),
      );

      final failure = _failure(await _get(client));

      expect(failure, isA<ValidationFailure>());
      failure as ValidationFailure;
      expect(failure.message, 'Dados inválidos');
      expect(failure.code, 'validation.failed');
    });

    test('404 com ProblemDetail vira NotFoundFailure', () async {
      final client = _client(
        (_) => problem(
          404,
          '{"type":"about:blank","title":"Not Found","status":404,'
          '"detail":"Aparelho não encontrado","code":"device.not.found"}',
        ),
      );

      final failure = _failure(await _get(client));

      expect(failure, isA<NotFoundFailure>());
      failure as NotFoundFailure;
      expect(failure.message, 'Aparelho não encontrado');
      expect(failure.code, 'device.not.found');
      expect(failure.statusCode, 404);
    });

    test('409 com ProblemDetail vira ConflictFailure', () async {
      final client = _client(
        (_) => problem(
          409,
          '{"type":"about:blank","title":"Conflict","status":409,'
          '"detail":"CPF já cadastrado","code":"customer.cpf.conflict"}',
        ),
      );

      final failure = _failure(await _get(client));

      expect(failure, isA<ConflictFailure>());
      failure as ConflictFailure;
      expect(failure.message, 'CPF já cadastrado');
      expect(failure.code, 'customer.cpf.conflict');
      expect(failure.statusCode, 409);
    });

    test(
      '429 com ProblemDetail vira RateLimitedFailure com Retry-After',
      () async {
        final client = _client(
          (_) => problem(
            429,
            '{"type":"about:blank","title":"Too Many Requests","status":429,'
            '"detail":"Muitas requisições","code":"rate.limited"}',
            h: {
              'retry-after': ['12'],
            },
          ),
        );

        final failure = _failure(await _get(client));

        expect(failure, isA<RateLimitedFailure>());
        failure as RateLimitedFailure;
        expect(failure.message, 'Muitas requisições');
        expect(failure.retryAfter, const Duration(seconds: 12));
      },
    );

    test('500 com ProblemDetail vira ServerFailure e usa fallback', () async {
      final client = _client(
        (_) => problem(
          500,
          '{"type":"about:blank","title":"Internal Server Error","status":500,'
          '"detail":"Erro interno","code":"internal.error"}',
        ),
      );

      final failure = _failure(await _get(client));

      expect(failure, isA<ServerFailure>());
      failure as ServerFailure;
      expect(failure.statusCode, 500);
      expect(failure.message, 'Erro interno');
      expect(failure.messageOr('fallback'), 'fallback');
    });
  });

  group('ApiClient.send logging', () {
    late _MemorySink sink;
    late bool originalMirror;
    late LogLevel originalLevel;

    setUp(() {
      originalMirror = AppLogger.mirrorToConsole;
      originalLevel = AppLogger.minLevel;
      AppLogger.mirrorToConsole = false;
      AppLogger.minLevel = LogLevel.debug;
      sink = _MemorySink();
      AppLogger.setSinkForTesting(sink);
    });

    tearDown(() {
      AppLogger.mirrorToConsole = originalMirror;
      AppLogger.minLevel = originalLevel;
      AppLogger.setSinkForTesting(const NoopLogSink());
    });

    test('falha de decode registra ERROR com método, path e stack', () async {
      final client = _client((_) => _json(200, '{"other":"Maria Silva"}'));

      final failure = _failure(await _get(client));

      expect(failure, isA<UnexpectedFailure>());
      final line = sink.lines.single;
      expect(line, contains('ERROR'));
      expect(line, contains('[ApiClient]'));
      expect(line, contains('Decode failed: GET /x status=200'));
      expect(line, contains('TypeError'));
      expect(line, contains('\n'), reason: 'stack trace em linhas seguintes');
      expect(line, isNot(contains('Maria Silva')));
    });

    test(
      'FormatException no decode não registra o trecho de entrada',
      () async {
        final client = _client((_) => _json(200, '{"phone":"Maria Silva"}'));

        await client.send(
          (dio) => dio.get<dynamic>('/x'),
          decode: (data) => int.parse(asJsonMap(data)['phone'] as String),
        );

        expect(sink.lines.single, contains('FormatException'));
        expect(sink.lines.single, isNot(contains('Maria Silva')));
      },
    );

    test('400 registra WARNING em uma linha, sem conteúdo do corpo', () async {
      final client = _client(
        (_) => _json(
          400,
          '{"error":{"code":"customer.invalid",'
          '"message":"CPF de Maria Silva inválido"},"name":"Maria Silva"}',
        ),
      );

      await _get(client);

      final line = sink.lines.single;
      expect(line, contains('WARNING'));
      expect(
        line,
        contains(
          'GET /x -> ValidationFailure status=400 code=customer.invalid',
        ),
      );
      expect(line, isNot(contains('\n')));
      expect(line, isNot(contains('Maria')));
      expect(line, isNot(contains('inválido')));
    });

    test('5xx (DioException) registra WARNING com status e código', () async {
      final client = _client(
        (_) => _json(503, '{"error":{"code":"db.down","message":"x"}}'),
      );

      await _get(client);

      expect(
        sink.lines.single,
        contains(
          'GET /x -> ServerFailure status=503 code=db.down type=badResponse',
        ),
      );
    });

    test(
      'ProblemDetail registra WARNING com code da raiz sem vazar detail',
      () async {
        final client = _client(
          (_) => ResponseBody.fromString(
            '{"type":"about:blank","title":"Bad Request","status":400,'
            '"detail":"CPF de Maria Silva inválido","code":"customer.invalid"}',
            400,
            headers: {
              Headers.contentTypeHeader: ['application/problem+json'],
            },
          ),
        );

        await _get(client);

        final line = sink.lines.single;
        expect(line, contains('WARNING'));
        expect(
          line,
          contains(
            'GET /x -> ValidationFailure status=400 code=customer.invalid',
          ),
        );
        expect(line, isNot(contains('Maria')));
      },
    );

    test('timeout registra WARNING com o tipo', () async {
      final client = _client(
        (options) => throw DioException.connectionTimeout(
          timeout: const Duration(seconds: 1),
          requestOptions: options,
        ),
      );

      await _get(client);

      expect(sink.lines.single, contains('WARNING'));
      expect(
        sink.lines.single,
        contains('GET /x -> NetworkFailure type=connectionTimeout'),
      );
    });

    test('exceção fora do Dio registra ERROR com stack', () async {
      final client = ApiClient(Dio());

      final result = await client.send<String>(
        (_) => throw StateError('boom'),
        decode: (data) => '',
      );

      expect(_failure(result), isA<UnexpectedFailure>());
      expect(sink.lines.single, contains('ERROR'));
      expect(sink.lines.single, contains('StateError'));
      expect(sink.lines.single, contains('\n'));
    });

    test('sucesso não registra nada', () async {
      final client = _client((_) => _json(200, '{"name":"ana"}'));

      await _get(client);

      expect(sink.lines, isEmpty);
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
