import '../../support/memory_security_storage.dart';

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/core/security/refresh_result.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';

typedef _PostHandler = Future<Response<dynamic>> Function(Object? data);

class _FakeDio implements Dio {
  @override
  BaseOptions options = BaseOptions();

  final Map<String, _PostHandler> handlers;
  final Map<String, Options?> recordedOptions = {};

  _FakeDio(this.handlers);

  @override
  Interceptors get interceptors => Interceptors();

  @override
  HttpClientAdapter get httpClientAdapter => throw UnimplementedError();

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    recordedOptions[path] = options;
    final handler = handlers[path];
    if (handler == null) {
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: <String, dynamic>{} as T,
      );
    }
    final response = await handler(data);
    return Response<T>(
      requestOptions: response.requestOptions,
      statusCode: response.statusCode,
      headers: response.headers,
      data: response.data as T,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Response<dynamic> _response(
  String path, {
  required int statusCode,
  Object? data,
  Map<String, List<String>>? headers,
}) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: path),
    statusCode: statusCode,
    headers: headers == null ? null : Headers.fromMap(headers),
    data: data,
  );
}

const _rateLimitBody = <String, dynamic>{
  'status': 429,
  'title': 'Muitas requisições',
  'error': {
    'code': 'rate.limited',
    'message': 'Limite de requisições excedido. Tente novamente em instantes.',
  },
};

Response<dynamic> _rateLimited({String? retryAfter}) => _response(
  '/api/auth/refresh',
  statusCode: 429,
  data: _rateLimitBody,
  headers: {
    if (retryAfter != null) 'retry-after': [retryAfter],
  },
);

/// Relógio manual para testar a janela do `Retry-After` sem esperar.
class _FakeClock {
  DateTime now = DateTime(2026, 11, 22, 10);

  void advance(Duration d) => now = now.add(d);
}

class _FixedAdapter implements HttpClientAdapter {
  final int status;
  final String body;
  final Map<String, List<String>> headers;
  int calls = 0;

  _FixedAdapter(this.status, this.body, {this.headers = const {}});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls += 1;
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

String _makeJwt(int expEpochSeconds) {
  final header = base64Url
      .encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'))
      .replaceAll('=', '');
  final payload = base64Url
      .encode(utf8.encode('{"sub":"test","exp":$expEpochSeconds}'))
      .replaceAll('=', '');
  return '$header.$payload.fake-signature';
}

void main() {
  group('AuthService.refreshToken', () {
    test(
      'deve salvar access e refresh quando backend rotaciona token',
      () async {
        final storage = MemorySecurityStorage()
          ..seedTokens(refreshToken: 'rt-1');
        final dio = _FakeDio({
          '/api/auth/refresh': (data) async => _response(
            '/api/auth/refresh',
            statusCode: 200,
            data: {'accessToken': 'at-2', 'refreshToken': 'rt-2'},
          ),
        });
        final service = AuthService(
          appVersion: () async => '1.1.1',
          dio: dio,
          storage: storage,
          authNotifier: AuthNotifier(),
        );

        final result = await service.refreshToken();

        expect(
          result,
          isA<RefreshSuccess>().having(
            (r) => r.accessToken,
            'accessToken',
            'at-2',
          ),
        );
        expect(
          dio.recordedOptions['/api/auth/refresh']?.extra?['silent'],
          isTrue,
        );
        expect(await storage.getAccessToken(), 'at-2');
        expect(await storage.getRefreshToken(), 'rt-2');
        expect(storage.saveTokensCalls, 1);
        expect(storage.saveAccessTokenCalls, 0);
      },
    );

    test(
      'deve salvar apenas access token quando refresh token nao vem na resposta',
      () async {
        final storage = MemorySecurityStorage()
          ..seedTokens(refreshToken: 'rt-1');
        final dio = _FakeDio({
          '/api/auth/refresh': (data) async => _response(
            '/api/auth/refresh',
            statusCode: 200,
            data: {'accessToken': 'at-2'},
          ),
        });
        final service = AuthService(
          appVersion: () async => '1.1.1',
          dio: dio,
          storage: storage,
          authNotifier: AuthNotifier(),
        );

        final result = await service.refreshToken();

        expect(
          result,
          isA<RefreshSuccess>().having(
            (r) => r.accessToken,
            'accessToken',
            'at-2',
          ),
        );
        expect(await storage.getAccessToken(), 'at-2');
        expect(await storage.getRefreshToken(), 'rt-1');
        expect(storage.saveTokensCalls, 0);
        expect(storage.saveAccessTokenCalls, 1);
      },
    );

    test(
      'deve invalidar sessao quando payload de refresh for invalido',
      () async {
        final storage = MemorySecurityStorage()
          ..seedTokens(refreshToken: 'rt-1');
        final dio = _FakeDio({
          '/api/auth/refresh': (data) async => _response(
            '/api/auth/refresh',
            statusCode: 200,
            data: {'unexpected': true},
          ),
          '/api/auth/revoke': (data) async =>
              _response('/api/auth/revoke', statusCode: 200),
        });
        final service = AuthService(
          appVersion: () async => '1.1.1',
          dio: dio,
          storage: storage,
          authNotifier: AuthNotifier(),
        );

        final result = await service.refreshToken();

        expect(result, isA<RefreshSessionExpired>());
        expect(
          dio.recordedOptions['/api/auth/revoke']?.extra?['silent'],
          isTrue,
        );
        expect(storage.clearSessionCalls, 1);
      },
    );

    test('deve invalidar sessao em status 401 do refresh', () async {
      final storage = MemorySecurityStorage()..seedTokens(refreshToken: 'rt-1');
      final dio = _FakeDio({
        '/api/auth/refresh': (data) async =>
            _response('/api/auth/refresh', statusCode: 401),
        '/api/auth/revoke': (data) async =>
            _response('/api/auth/revoke', statusCode: 200),
      });
      final service = AuthService(
        appVersion: () async => '1.1.1',
        dio: dio,
        storage: storage,
        authNotifier: AuthNotifier(),
      );

      final result = await service.refreshToken();

      expect(result, isA<RefreshSessionExpired>());
      expect(storage.clearSessionCalls, 1);
    });

    test('nao deve deslogar em 400 Invalid Host Header do gateway', () async {
      final storage = MemorySecurityStorage()..seedTokens(refreshToken: 'rt-1');
      await storage.saveApiKey('key-1');
      final authNotifier = AuthNotifier(
        initialState: AuthRouteState.authenticated,
      );
      final dio = _FakeDio({
        '/api/auth/refresh': (data) async => _response(
          '/api/auth/refresh',
          statusCode: 400,
          data: 'Gateway: Invalid Host Header',
        ),
      });
      final service = AuthService(
        appVersion: () async => '1.1.1',
        dio: dio,
        storage: storage,
        authNotifier: authNotifier,
      );

      final result = await service.refreshToken();

      expect(
        result,
        isA<RefreshTransientFailure>()
            .having(
              (r) => r.errorType,
              'errorType',
              DioExceptionType.badResponse,
            )
            .having((r) => r.response?.statusCode, 'statusCode', 400),
      );
      expect(storage.clearSessionCalls, 0);
      expect(storage.clearProvisioningCalls, 0);
      expect(await storage.getApiKey(), 'key-1');
      expect(await storage.getRefreshToken(), 'rt-1');
      expect(authNotifier.state, AuthRouteState.authenticated);
    });

    test('nao deve deslogar em 403 HTML do WAF lancado pelo Dio', () async {
      final storage = MemorySecurityStorage()..seedTokens(refreshToken: 'rt-1');
      await storage.saveApiKey('key-1');
      final authNotifier = AuthNotifier(
        initialState: AuthRouteState.authenticated,
      );
      final dio = _FakeDio({
        '/api/auth/refresh': (data) async {
          throw DioException(
            requestOptions: RequestOptions(path: '/api/auth/refresh'),
            type: DioExceptionType.badResponse,
            response: _response(
              '/api/auth/refresh',
              statusCode: 403,
              data: '<html><body>Access denied</body></html>',
            ),
          );
        },
      });
      final service = AuthService(
        appVersion: () async => '1.1.1',
        dio: dio,
        storage: storage,
        authNotifier: authNotifier,
      );

      final result = await service.refreshToken();

      expect(
        result,
        isA<RefreshTransientFailure>()
            .having(
              (r) => r.errorType,
              'errorType',
              DioExceptionType.badResponse,
            )
            .having((r) => r.response?.statusCode, 'statusCode', 403),
      );
      expect(storage.clearSessionCalls, 0);
      expect(storage.clearProvisioningCalls, 0);
      expect(await storage.getApiKey(), 'key-1');
      expect(authNotifier.state, AuthRouteState.authenticated);
    });

    test(
      'deve encerrar sessao quando a API recusa o refresh por chave inativa',
      () async {
        final storage = MemorySecurityStorage()
          ..seedTokens(refreshToken: 'rt-1');
        await storage.saveApiKey('key-1');
        final authNotifier = AuthNotifier(
          initialState: AuthRouteState.authenticated,
        );
        // Corpo real do GlobalExceptionHandler para InvalidTokenException.
        final dio = _FakeDio({
          '/api/auth/refresh': (data) async {
            throw DioException(
              requestOptions: RequestOptions(path: '/api/auth/refresh'),
              response: _response(
                '/api/auth/refresh',
                statusCode: 401,
                data: {
                  'status': 401,
                  'title': 'Token Inválido',
                  'error': {
                    'code': 'auth.invalid.token',
                    'message': 'Associated API Key is inactive',
                  },
                },
              ),
            );
          },
        });
        final service = AuthService(
          appVersion: () async => '1.1.1',
          dio: dio,
          storage: storage,
          authNotifier: authNotifier,
        );

        final result = await service.refreshToken();

        expect(result, isA<RefreshSessionExpired>());
        expect(storage.clearSessionCalls, 1);
        expect(await storage.getRefreshToken(), isNull);
        expect(authNotifier.state, AuthRouteState.needsSetup);
      },
    );

    test(
      'deve fazer logout completo quando a API sinaliza API key invalida',
      () async {
        final storage = MemorySecurityStorage()
          ..seedTokens(refreshToken: 'rt-1');
        await storage.saveApiKey('key-1');
        final authNotifier = AuthNotifier(
          initialState: AuthRouteState.authenticated,
        );
        final dio = _FakeDio({
          '/api/auth/refresh': (data) async => _response(
            '/api/auth/refresh',
            statusCode: 400,
            data: {
              'status': 400,
              'error': {
                'code': 'auth.invalid.api.key',
                'message': 'Invalid API Key',
              },
            },
          ),
          '/api/auth/revoke': (data) async =>
              _response('/api/auth/revoke', statusCode: 200),
        });
        final service = AuthService(
          appVersion: () async => '1.1.1',
          dio: dio,
          storage: storage,
          authNotifier: authNotifier,
        );

        final result = await service.refreshToken();

        expect(result, isA<RefreshSessionExpired>());
        expect(storage.clearProvisioningCalls, 1);
        expect(await storage.getApiKey(), isNull);
        expect(authNotifier.state, AuthRouteState.needsSetup);
      },
    );

    test('nao deve invalidar sessao em status 500 do refresh', () async {
      final storage = MemorySecurityStorage()..seedTokens(refreshToken: 'rt-1');
      final dio = _FakeDio({
        '/api/auth/refresh': (data) async =>
            _response('/api/auth/refresh', statusCode: 500),
      });
      final service = AuthService(
        appVersion: () async => '1.1.1',
        dio: dio,
        storage: storage,
        authNotifier: AuthNotifier(),
      );

      final result = await service.refreshToken();

      expect(
        result,
        isA<RefreshTransientFailure>()
            .having(
              (r) => r.errorType,
              'errorType',
              DioExceptionType.badResponse,
            )
            .having((r) => r.response?.statusCode, 'statusCode', 500),
      );
      expect(storage.clearSessionCalls, 0);
    });

    test(
      'deve retornar RefreshTransientFailure preservando tipo de erro de rede',
      () async {
        for (final type in [
          DioExceptionType.connectionError,
          DioExceptionType.connectionTimeout,
          DioExceptionType.receiveTimeout,
          DioExceptionType.sendTimeout,
        ]) {
          final storage = MemorySecurityStorage()
            ..seedTokens(refreshToken: 'rt-1');
          final authNotifier = AuthNotifier(
            initialState: AuthRouteState.authenticated,
          );
          final dio = _FakeDio({
            '/api/auth/refresh': (data) async {
              throw DioException(
                requestOptions: RequestOptions(path: '/api/auth/refresh'),
                type: type,
                error: 'network issue',
              );
            },
          });
          final service = AuthService(
            appVersion: () async => '1.1.1',
            dio: dio,
            storage: storage,
            authNotifier: authNotifier,
          );

          final result = await service.refreshToken();

          expect(
            result,
            isA<RefreshTransientFailure>().having(
              (r) => r.errorType,
              'errorType',
              type,
            ),
          );
          expect(storage.clearSessionCalls, 0);
          expect(authNotifier.state, AuthRouteState.authenticated);
        }
      },
    );
  });

  group('AuthService.refreshToken com HTTP 429', () {
    late MemorySecurityStorage storage;
    late AuthNotifier authNotifier;
    late _FakeClock clock;
    late int refreshCalls;

    setUp(() async {
      storage = MemorySecurityStorage()..seedTokens(refreshToken: 'rt-1');
      await storage.saveApiKey('key-1');
      authNotifier = AuthNotifier(initialState: AuthRouteState.authenticated);
      clock = _FakeClock();
      refreshCalls = 0;
    });

    AuthService serviceWith(Future<Response<dynamic>> Function() onRefresh) {
      return AuthService(
        appVersion: () async => '1.1.1',
        dio: _FakeDio({
          '/api/auth/refresh': (data) {
            refreshCalls += 1;
            return onRefresh();
          },
        }),
        storage: storage,
        authNotifier: authNotifier,
        clock: () => clock.now,
      );
    }

    void expectSessionKept() {
      expect(storage.clearSessionCalls, 0);
      expect(storage.clearProvisioningCalls, 0);
      expect(authNotifier.state, AuthRouteState.authenticated);
    }

    Matcher isTransient429() => isA<RefreshTransientFailure>()
        .having((r) => r.errorType, 'errorType', DioExceptionType.badResponse)
        .having((r) => r.response?.statusCode, 'statusCode', 429);

    test(
      '429 entregue como status é transitório e não derruba a sessão',
      () async {
        final service = serviceWith(() async => _rateLimited(retryAfter: '10'));

        final result = await service.refreshToken();

        expect(result, isTransient429());
        expectSessionKept();
        expect(await storage.getApiKey(), 'key-1');
        expect(await storage.getRefreshToken(), 'rt-1');
      },
    );

    test(
      '429 lançado como DioException é transitório e não derruba a sessão',
      () async {
        final service = serviceWith(() async {
          throw DioException(
            requestOptions: RequestOptions(path: '/api/auth/refresh'),
            type: DioExceptionType.badResponse,
            response: _rateLimited(retryAfter: '10'),
          );
        });

        final result = await service.refreshToken();

        expect(result, isTransient429());
        expectSessionKept();
        expect(await storage.getRefreshToken(), 'rt-1');
      },
    );

    test(
      'respeita Retry-After: 10 antes de chamar o refresh de novo',
      () async {
        var respond429 = true;
        final service = serviceWith(() async {
          if (respond429) return _rateLimited(retryAfter: '10');
          return _response(
            '/api/auth/refresh',
            statusCode: 200,
            data: {'accessToken': 'at-2', 'refreshToken': 'rt-2'},
          );
        });

        expect(await service.refreshToken(), isTransient429());
        expect(refreshCalls, 1);

        respond429 = false;
        clock.advance(const Duration(seconds: 9));
        final blocked = await service.refreshToken();
        expect(blocked, isTransient429());
        expect(refreshCalls, 1, reason: 'dentro do Retry-After não há request');
        expectSessionKept();

        clock.advance(const Duration(seconds: 1));
        final after = await service.refreshToken();
        expect(after, isA<RefreshSuccess>());
        expect(refreshCalls, 2);
        expect(await storage.getAccessToken(), 'at-2');
      },
    );

    test('sem Retry-After aplica o fallback de 30s', () async {
      final service = serviceWith(() async => _rateLimited());

      await service.refreshToken();
      expect(refreshCalls, 1);

      clock.advance(const Duration(seconds: 29));
      await service.refreshToken();
      expect(refreshCalls, 1);

      clock.advance(const Duration(seconds: 1));
      await service.refreshToken();
      expect(refreshCalls, 2);
      expectSessionKept();
    });

    test('Retry-After inválido aplica o fallback de 30s', () async {
      for (final invalid in [
        'abc',
        '-5',
        '',
        'Wed, 21 Oct 2026 07:28:00 GMT',
      ]) {
        refreshCalls = 0;
        clock = _FakeClock();
        final service = serviceWith(
          () async => _rateLimited(retryAfter: invalid),
        );

        await service.refreshToken();
        clock.advance(const Duration(seconds: 29));
        await service.refreshToken();
        expect(refreshCalls, 1, reason: 'Retry-After="$invalid"');

        clock.advance(const Duration(seconds: 1));
        await service.refreshToken();
        expect(refreshCalls, 2, reason: 'Retry-After="$invalid"');
      }
    });

    test('DioException 429 sem Retry-After também suspende por 30s', () async {
      final service = serviceWith(() async {
        throw DioException(
          requestOptions: RequestOptions(path: '/api/auth/refresh'),
          type: DioExceptionType.badResponse,
          response: _rateLimited(),
        );
      });

      await service.refreshToken();
      clock.advance(const Duration(seconds: 29));
      await service.refreshToken();
      expect(refreshCalls, 1);

      clock.advance(const Duration(seconds: 1));
      await service.refreshToken();
      expect(refreshCalls, 2);
    });

    test(
      'falhas transitórias que não são 429 não suspendem o refresh',
      () async {
        final service = serviceWith(
          () async => _response('/api/auth/refresh', statusCode: 500),
        );

        await service.refreshToken();
        await service.refreshToken();

        expect(refreshCalls, 2);
      },
    );

    test('via CustomDio real: 429 com Retry-After vira DioException e '
        'bloqueia novas chamadas HTTP', () async {
      final adapter = _FixedAdapter(
        429,
        jsonEncode(_rateLimitBody),
        headers: {
          'retry-after': ['10'],
        },
      );
      final dio = CustomDio(
        baseUri: Uri.parse('https://test.example.com'),
        adapter: adapter,
      ).createAuthDio();
      final service = AuthService(
        appVersion: () async => '1.1.1',
        dio: dio,
        storage: storage,
        authNotifier: authNotifier,
        clock: () => clock.now,
      );

      final first = await service.refreshToken();
      expect(first, isTransient429());
      expect(adapter.calls, 1);

      clock.advance(const Duration(seconds: 5));
      final second = await service.refreshToken();
      expect(second, isTransient429());
      expect(adapter.calls, 1);
      expectSessionKept();

      clock.advance(const Duration(seconds: 5));
      await service.refreshToken();
      expect(adapter.calls, 2);
    });
  });

  group('AuthService bootstrap/session', () {
    late AuthNotifier authNotifier;

    setUp(() {
      authNotifier = AuthNotifier(initialState: AuthRouteState.restoring);
    });

    test(
      'deve restaurar sessao via api key salva quando nao ha tokens',
      () async {
        final storage = MemorySecurityStorage();
        await storage.saveApiKey('key-1');
        final dio = _FakeDio({
          '/api/auth/token': (data) async => _response(
            '/api/auth/token',
            statusCode: 200,
            data: {
              'accessToken': 'at-1',
              'refreshToken': 'rt-1',
              'tokenType': 'Bearer',
              'expiresIn': 3600,
              'refreshExpiresIn': 86400,
            },
          ),
        });
        final service = AuthService(
          appVersion: () async => '1.1.1',
          dio: dio,
          storage: storage,
          authNotifier: authNotifier,
        );

        final restored = await service.restoreSessionFromStoredApiKey();

        expect(restored, SessionRestoreResult.restored);
        expect(await storage.getAccessToken(), 'at-1');
        expect(await storage.getRefreshToken(), 'rt-1');
      },
    );

    test(
      'deve limpar provisioning quando authenticate falha com 401',
      () async {
        final storage = MemorySecurityStorage();
        await storage.saveApiKey('invalid-key');
        final dio = _FakeDio({
          '/api/auth/token': (data) async {
            throw DioException(
              requestOptions: RequestOptions(path: '/api/auth/token'),
              response: _response('/api/auth/token', statusCode: 401),
            );
          },
        });
        final service = AuthService(
          appVersion: () async => '1.1.1',
          dio: dio,
          storage: storage,
          authNotifier: authNotifier,
        );

        await expectLater(
          service.authenticate('invalid-key'),
          throwsA(isA<DioException>()),
        );

        expect(storage.clearProvisioningCalls, 1);
        expect(await storage.getApiKey(), isNull);
        expect(await storage.getAccessToken(), isNull);
        expect(await storage.getRefreshToken(), isNull);
        expect(authNotifier.state, AuthRouteState.needsSetup);
      },
    );

    test(
      'authenticate nao deve definir needsSetup em erro transitorio de rede',
      () async {
        final storage = MemorySecurityStorage();
        await storage.saveApiKey('key-1');
        final notifier = AuthNotifier(initialState: AuthRouteState.offline);
        final dio = _FakeDio({
          '/api/auth/token': (data) async {
            throw DioException(
              requestOptions: RequestOptions(path: '/api/auth/token'),
              type: DioExceptionType.connectionError,
            );
          },
        });
        final service = AuthService(
          appVersion: () async => '1.1.1',
          dio: dio,
          storage: storage,
          authNotifier: notifier,
        );

        await expectLater(
          service.authenticate('key-1'),
          throwsA(isA<DioException>()),
        );

        expect(await storage.getApiKey(), 'key-1');
        expect(notifier.state, AuthRouteState.offline);
      },
    );

    test(
      'deve falhar restore e limpar provisioning em api key invalida',
      () async {
        final storage = MemorySecurityStorage();
        await storage.saveApiKey('invalid-key');
        final dio = _FakeDio({
          '/api/auth/token': (data) async {
            throw DioException(
              requestOptions: RequestOptions(path: '/api/auth/token'),
              response: _response('/api/auth/token', statusCode: 401),
            );
          },
        });
        final service = AuthService(
          appVersion: () async => '1.1.1',
          dio: dio,
          storage: storage,
          authNotifier: authNotifier,
        );

        final restored = await service.restoreSessionFromStoredApiKey();

        expect(restored, SessionRestoreResult.invalidCredentials);
        expect(storage.clearProvisioningCalls, 1);
        expect(await storage.getApiKey(), isNull);
      },
    );

    test(
      'restoreSessionFromStoredApiKey retorna noApiKey quando nao ha chave salva',
      () async {
        final storage = MemorySecurityStorage();
        final service = AuthService(
          appVersion: () async => '1.1.1',
          dio: _FakeDio({}),
          storage: storage,
          authNotifier: authNotifier,
        );

        final restored = await service.restoreSessionFromStoredApiKey();

        expect(restored, SessionRestoreResult.noApiKey);
      },
    );

    test(
      'initializeAuthState deve autenticar quando sessao ja existe',
      () async {
        final storage = MemorySecurityStorage()
          ..seedTokens(accessToken: 'at-1', refreshToken: 'rt-1');
        final dio = _FakeDio({});
        final service = AuthService(
          appVersion: () async => '1.1.1',
          dio: dio,
          storage: storage,
          authNotifier: authNotifier,
        );

        final state = await service.initializeAuthState();

        expect(state, AuthRouteState.authenticated);
        expect(authNotifier.state, AuthRouteState.authenticated);
      },
    );

    test(
      'initializeAuthState deve ir para offline e preservar apiKey em erro de rede no bootstrap',
      () async {
        final storage = MemorySecurityStorage();
        await storage.saveApiKey('key-1');
        final dio = _FakeDio({
          '/api/auth/token': (data) async {
            throw DioException(
              requestOptions: RequestOptions(path: '/api/auth/token'),
              type: DioExceptionType.connectionTimeout,
            );
          },
        });
        final service = AuthService(
          appVersion: () async => '1.1.1',
          dio: dio,
          storage: storage,
          authNotifier: authNotifier,
        );

        final state = await service.initializeAuthState();

        expect(state, AuthRouteState.offline);
        expect(authNotifier.state, AuthRouteState.offline);
        expect(await storage.getApiKey(), 'key-1');
      },
    );

    test(
      'initializeAuthState deve ir para storageError quando storage lanca excecao no boot',
      () async {
        final storage = MemorySecurityStorage()
          ..getRefreshTokenError = PlatformException(
            code: 'KEYSTORE_ERR',
            message: 'Keystore unavailable',
          );
        final service = AuthService(
          appVersion: () async => '1.1.1',
          dio: _FakeDio({}),
          storage: storage,
          authNotifier: authNotifier,
        );

        final state = await service.initializeAuthState();

        expect(state, AuthRouteState.storageError);
        expect(authNotifier.state, AuthRouteState.storageError);
      },
    );

    test(
      'initializeAuthState deve ir para storageError quando getBoundDeviceId falha durante restore',
      () async {
        final storage = MemorySecurityStorage();
        await storage.saveApiKey('key-1');
        storage.getBoundDeviceIdError = PlatformException(
          code: 'KEYSTORE_WRITE_ERR',
          message: 'Cannot read device id',
        );
        final service = AuthService(
          appVersion: () async => '1.1.1',
          dio: _FakeDio({}),
          storage: storage,
          authNotifier: authNotifier,
        );

        final state = await service.initializeAuthState();

        expect(state, AuthRouteState.storageError);
        expect(authNotifier.state, AuthRouteState.storageError);
      },
    );
  });

  group('AuthService race & hasSession', () {
    test(
      'logout durante refresh em voo descarta token do refresh e mantém storage limpo',
      () async {
        final storage = MemorySecurityStorage()
          ..seedTokens(accessToken: 'at-old', refreshToken: 'rt-1');
        await storage.saveApiKey('key-1');
        final authNotifier = AuthNotifier(
          initialState: AuthRouteState.authenticated,
        );
        final refreshCompleter = Completer<Response<dynamic>>();

        final dio = _FakeDio({
          '/api/auth/refresh': (_) => refreshCompleter.future,
          '/api/auth/revoke': (_) async =>
              _response('/api/auth/revoke', statusCode: 200),
        });
        final service = AuthService(
          appVersion: () async => '1.1.1',
          dio: dio,
          storage: storage,
          authNotifier: authNotifier,
        );

        final refreshFuture = service.refreshToken();
        await Future<void>.delayed(Duration.zero);

        await service.logout();
        expect(authNotifier.state, AuthRouteState.needsSetup);
        expect(await storage.getAccessToken(), isNull);
        expect(await storage.getRefreshToken(), isNull);
        expect(await storage.getApiKey(), isNull);

        refreshCompleter.complete(
          _response(
            '/api/auth/refresh',
            statusCode: 200,
            data: {'accessToken': 'at-stale', 'refreshToken': 'rt-stale'},
          ),
        );

        final result = await refreshFuture;

        expect(result, isA<RefreshSessionExpired>());
        expect(await storage.getAccessToken(), isNull);
        expect(await storage.getRefreshToken(), isNull);
        expect(await storage.getApiKey(), isNull);
        expect(authNotifier.state, AuthRouteState.needsSetup);
      },
    );

    test(
      'forceLogout durante refresh em voo descarta token do refresh e mantém storage limpo',
      () async {
        final storage = MemorySecurityStorage()
          ..seedTokens(accessToken: 'at-old', refreshToken: 'rt-1');
        await storage.saveApiKey('key-1');
        final authNotifier = AuthNotifier(
          initialState: AuthRouteState.authenticated,
        );
        final refreshCompleter = Completer<Response<dynamic>>();

        final dio = _FakeDio({
          '/api/auth/refresh': (_) => refreshCompleter.future,
        });
        final service = AuthService(
          appVersion: () async => '1.1.1',
          dio: dio,
          storage: storage,
          authNotifier: authNotifier,
        );

        final refreshFuture = service.refreshToken();
        await Future<void>.delayed(Duration.zero);

        await service.forceLogout();

        refreshCompleter.complete(
          _response(
            '/api/auth/refresh',
            statusCode: 200,
            data: {'accessToken': 'at-stale'},
          ),
        );

        final result = await refreshFuture;

        expect(result, isA<RefreshSessionExpired>());
        expect(await storage.getAccessToken(), isNull);
        expect(await storage.getRefreshToken(), isNull);
        expect(await storage.getApiKey(), isNull);
        expect(authNotifier.state, AuthRouteState.needsSetup);
      },
    );

    test(
      'novo authenticate durante refresh em voo não é sobrescrito pelo token antigo',
      () async {
        final storage = MemorySecurityStorage()
          ..seedTokens(accessToken: 'at-old', refreshToken: 'rt-1');
        final authNotifier = AuthNotifier(
          initialState: AuthRouteState.needsSetup,
        );
        final refreshCompleter = Completer<Response<dynamic>>();

        final dio = _FakeDio({
          '/api/auth/refresh': (_) => refreshCompleter.future,
          '/api/auth/token': (_) async => _response(
            '/api/auth/token',
            statusCode: 200,
            data: {
              'accessToken': 'at-fresh',
              'refreshToken': 'rt-fresh',
              'tokenType': 'Bearer',
              'expiresIn': 3600,
              'refreshExpiresIn': 86400,
            },
          ),
        });
        final service = AuthService(
          appVersion: () async => '1.1.1',
          dio: dio,
          storage: storage,
          authNotifier: authNotifier,
        );

        final refreshFuture = service.refreshToken();
        await Future<void>.delayed(Duration.zero);

        await service.authenticate('new-key');

        refreshCompleter.complete(
          _response(
            '/api/auth/refresh',
            statusCode: 200,
            data: {'accessToken': 'at-stale', 'refreshToken': 'rt-stale'},
          ),
        );

        final result = await refreshFuture;

        expect(result, isA<RefreshSessionExpired>());
        expect(await storage.getAccessToken(), 'at-fresh');
        expect(await storage.getRefreshToken(), 'rt-fresh');
        expect(authNotifier.state, AuthRouteState.authenticated);
      },
    );

    test(
      'hasSession retorna false quando há apenas accessToken expirado ou malformado',
      () async {
        final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final expiredJwt = _makeJwt(nowSec - 300);
        final validJwt = _makeJwt(nowSec + 3600);

        final storageExpired = MemorySecurityStorage()
          ..seedTokens(accessToken: expiredJwt);
        final serviceExpired = AuthService(
          appVersion: () async => '1.1.1',
          dio: _FakeDio({}),
          storage: storageExpired,
          authNotifier: AuthNotifier(),
        );
        expect(await serviceExpired.hasSession, isFalse);

        final storageMalformed = MemorySecurityStorage()
          ..seedTokens(accessToken: 'not-a-jwt');
        final serviceMalformed = AuthService(
          appVersion: () async => '1.1.1',
          dio: _FakeDio({}),
          storage: storageMalformed,
          authNotifier: AuthNotifier(),
        );
        expect(await serviceMalformed.hasSession, isFalse);

        final storageValid = MemorySecurityStorage()
          ..seedTokens(accessToken: validJwt);
        final serviceValid = AuthService(
          appVersion: () async => '1.1.1',
          dio: _FakeDio({}),
          storage: storageValid,
          authNotifier: AuthNotifier(),
        );
        expect(await serviceValid.hasSession, isTrue);

        final storageWithRefresh = MemorySecurityStorage()
          ..seedTokens(accessToken: expiredJwt, refreshToken: 'rt-1');
        final serviceWithRefresh = AuthService(
          appVersion: () async => '1.1.1',
          dio: _FakeDio({}),
          storage: storageWithRefresh,
          authNotifier: AuthNotifier(),
        );
        expect(await serviceWithRefresh.hasSession, isTrue);
      },
    );
  });
}
