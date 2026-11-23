import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/http/interceptors/global_error_interceptor.dart';
import 'package:flutter_workshop_front/core/http/interceptors/security_interceptor.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/core/security/refresh_result.dart';
import 'package:flutter_workshop_front/core/security/security_storage.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Gera um JWT minimalista com o timestamp de expiração informado.
/// Não é assinado de forma válida, mas é suficiente para o JwtDecoder ler o `exp`.
String makeJwt(int expEpochSeconds) {
  final header = base64Url
      .encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'))
      .replaceAll('=', '');
  final payload = base64Url
      .encode(utf8.encode('{"sub":"test","exp":$expEpochSeconds}'))
      .replaceAll('=', '');
  return '$header.$payload.fake-signature';
}

int get _nowSeconds => DateTime.now().millisecondsSinceEpoch ~/ 1000;

/// Token expirado há alguns minutos.
String get expiredToken => makeJwt(_nowSeconds - 300);

/// Token expirando daqui a 30s (dentro do buffer de 60s → "expirando em breve").
String get expiringToken => makeJwt(_nowSeconds + 30);

/// Token válido por 1 hora.
String get validToken => makeJwt(_nowSeconds + 3600);

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _MemorySecurityStorage implements SecurityStorage {
  final Map<String, String> _storage = {};
  int clearSessionCalls = 0;
  int clearProvisioningCalls = 0;
  int getAccessTokenCalls = 0;
  Object? Function(int callIndex)? getAccessTokenErrorOnCall;
  Object? clearProvisioningError;

  void seedTokens({String? accessToken, String? refreshToken, String? apiKey}) {
    if (accessToken != null) _storage['access_token'] = accessToken;
    if (refreshToken != null) _storage['refresh_token'] = refreshToken;
    if (apiKey != null) _storage['api_key'] = apiKey;
  }

  @override
  Future<void> clearAll() async => _storage.clear();

  @override
  Future<void> clearSession() async {
    clearSessionCalls += 1;
    _storage.remove('access_token');
    _storage.remove('refresh_token');
  }

  @override
  Future<void> clearProvisioning({bool removeBoundDeviceId = false}) async {
    clearProvisioningCalls += 1;
    if (clearProvisioningError != null) {
      throw clearProvisioningError!;
    }
    await clearSession();
    _storage.remove('api_key');
    if (removeBoundDeviceId) {
      _storage.remove('bound_device_id');
    }
  }

  @override
  Future<String?> getAccessToken() async {
    getAccessTokenCalls += 1;
    final err = getAccessTokenErrorOnCall?.call(getAccessTokenCalls);
    if (err != null) throw err;
    return _storage['access_token'];
  }

  @override
  Future<String?> getApiKey() async => _storage['api_key'];

  @override
  Future<String> getBoundDeviceId() async =>
      _storage['bound_device_id'] ?? 'device-1';

  @override
  Future<String?> getRefreshToken() async => _storage['refresh_token'];

  @override
  Future<void> saveAccessToken(String accessToken) async {
    _storage['access_token'] = accessToken;
  }

  @override
  Future<void> saveApiKey(String key) async {
    _storage['api_key'] = key;
  }

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _storage['access_token'] = accessToken;
    _storage['refresh_token'] = refreshToken;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AdapterResult {
  final int statusCode;
  final Object? data;

  /// Corpo cru não-JSON (ex.: página HTML do WAF). Tem precedência sobre [data].
  final String? rawBody;
  final String contentType;

  const _AdapterResult({
    required this.statusCode,
    this.data,
    this.rawBody,
    this.contentType = Headers.jsonContentType,
  });
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
    final body =
        result.rawBody ?? (result.data == null ? '' : jsonEncode(result.data));

    return ResponseBody.fromString(
      body,
      result.statusCode,
      headers: {
        Headers.contentTypeHeader: [result.contentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('SecurityInterceptor', () {
    late _MemorySecurityStorage storage;
    late Dio dio;
    late Dio retryDio;
    late int refreshCalls;
    late AuthNotifier authNotifier;

    /// Monta um SecurityInterceptor conectado ao [dio] e [retryDio] fornecidos.
    SecurityInterceptor buildInterceptor({
      required Future<RefreshResult> Function() onRefresh,
      Future<void> Function()? onCredentialRejected,
    }) {
      return SecurityInterceptor(
        storage: storage,
        retryDio: retryDio,
        authNotifier: authNotifier,
        onRefresh: onRefresh,
        onCredentialRejected: onCredentialRejected,
      );
    }

    setUp(() {
      storage = _MemorySecurityStorage();
      authNotifier = AuthNotifier();
      refreshCalls = 0;

      dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      retryDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    });

    // ── onError: fluxo reativo (401 inesperado do servidor) ───────────────────

    test('deve fazer refresh e retry em 401', () async {
      final newToken = validToken;
      // Token válido por JWT, mas o servidor retorna 401 (ex: invalidação forçada).
      storage.seedTokens(
        accessToken: validToken,
        refreshToken: 'rt-1',
        apiKey: 'api-key-1',
      );

      // Main dio: sempre retorna 401.
      dio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) =>
            const _AdapterResult(statusCode: 401, data: {'error': 'expired'}),
      );
      // retryDio: retorna 200 para o novo token.
      retryDio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (options) {
          if (options.headers['Authorization'] == 'Bearer $newToken') {
            return const _AdapterResult(statusCode: 200, data: {'ok': true});
          }
          return const _AdapterResult(statusCode: 401, data: {'error': 'bad'});
        },
      );

      dio.interceptors.add(
        buildInterceptor(
          onRefresh: () async {
            refreshCalls += 1;
            await storage.saveAccessToken(newToken);
            return RefreshSuccess(newToken);
          },
        ),
      );

      final response = await dio.get<dynamic>('/protected');

      expect(response.statusCode, 200);
      expect(refreshCalls, 1);
    });

    test(
      'deve propagar 401 sem novo refresh quando retry também falha com 401',
      () async {
        // Token válido localmente, mas servidor rejeita e o novo token também é rejeitado.
        // O retryDio não tem SecurityInterceptor → 401 do retry propaga diretamente.
        final newToken = validToken;
        storage.seedTokens(
          accessToken: validToken,
          refreshToken: 'rt-1',
          apiKey: 'api-key-1',
        );

        dio.httpClientAdapter = _TestHttpClientAdapter(
          responder: (_) =>
              const _AdapterResult(statusCode: 401, data: {'error': 'expired'}),
        );
        retryDio.httpClientAdapter = _TestHttpClientAdapter(
          responder: (_) => const _AdapterResult(
            statusCode: 401,
            data: {'error': 'still bad'},
          ),
        );

        dio.interceptors.add(
          buildInterceptor(
            onRefresh: () async {
              refreshCalls += 1;
              await storage.saveAccessToken(newToken);
              return RefreshSuccess(newToken);
            },
          ),
        );

        await expectLater(
          dio.get<dynamic>('/protected'),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'statusCode',
              401,
            ),
          ),
        );
        // Refresh acontece apenas uma vez — o 401 do retry não aciona outro refresh.
        expect(refreshCalls, 1);
      },
    );

    test('deve propagar erro do retry quando retry falha com 500', () async {
      final newToken = validToken;
      storage.seedTokens(
        accessToken: validToken,
        refreshToken: 'rt-1',
        apiKey: 'api-key-1',
      );

      dio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) =>
            const _AdapterResult(statusCode: 401, data: {'error': 'expired'}),
      );
      retryDio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) =>
            const _AdapterResult(statusCode: 500, data: {'error': 'server'}),
      );

      dio.interceptors.add(
        buildInterceptor(
          onRefresh: () async {
            refreshCalls += 1;
            await storage.saveAccessToken(newToken);
            return RefreshSuccess(newToken);
          },
        ),
      );

      await expectLater(
        dio.get<dynamic>('/protected'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
      expect(refreshCalls, 1);
    });

    test(
      'deve retornar cancel quando refresh retorna RefreshSessionExpired em 401',
      () async {
        storage.seedTokens(
          accessToken: validToken,
          refreshToken: 'rt-1',
          apiKey: 'api-key-1',
        );

        dio.httpClientAdapter = _TestHttpClientAdapter(
          responder: (_) =>
              const _AdapterResult(statusCode: 401, data: {'error': 'expired'}),
        );

        dio.interceptors.add(
          buildInterceptor(
            onRefresh: () async {
              refreshCalls += 1;
              return const RefreshSessionExpired();
            },
          ),
        );

        await expectLater(
          dio.get<dynamic>('/protected'),
          throwsA(
            isA<DioException>().having(
              (e) => e.type,
              'type',
              DioExceptionType.cancel,
            ),
          ),
        );
        expect(refreshCalls, 1);
      },
    );

    test('não deve deslogar em 403 de autorização por papel da API', () async {
      storage.seedTokens(
        accessToken: validToken,
        refreshToken: 'rt-1',
        apiKey: 'api-key-1',
      );

      // Corpo real do accessDeniedHandler do SecurityConfig da API.
      dio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) => const _AdapterResult(
          statusCode: 403,
          data: {
            'status': 403,
            'title': 'Acesso Negado',
            'error': {'code': 'auth.access.denied', 'message': 'Acesso Negado'},
          },
        ),
      );

      final authService = AuthService(
        dio: Dio(),
        storage: storage,
        authNotifier: authNotifier,
      );

      dio.interceptors.add(
        buildInterceptor(
          onRefresh: () async => const RefreshSessionExpired(),
          onCredentialRejected: authService.forceLogout,
        ),
      );

      await expectLater(
        dio.get<dynamic>('/admin-only'),
        throwsA(
          isA<DioException>()
              .having((e) => e.type, 'type', DioExceptionType.badResponse)
              .having((e) => e.response?.statusCode, 'statusCode', 403),
        ),
      );
      expect(storage.clearProvisioningCalls, 0);
      expect(storage.clearSessionCalls, 0);
      expect(await storage.getApiKey(), 'api-key-1');
      expect(authNotifier.state, isNot(AuthRouteState.needsSetup));
    });

    test('não deve deslogar em 403 HTML do WAF da Cloudflare', () async {
      storage.seedTokens(
        accessToken: validToken,
        refreshToken: 'rt-1',
        apiKey: 'api-key-1',
      );

      dio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) => const _AdapterResult(
          statusCode: 403,
          rawBody: '<!DOCTYPE html><html><body>Access denied</body></html>',
          contentType: 'text/html; charset=UTF-8',
        ),
      );

      final authService = AuthService(
        dio: Dio(),
        storage: storage,
        authNotifier: authNotifier,
      );

      dio.interceptors.add(
        buildInterceptor(
          onRefresh: () async => const RefreshSessionExpired(),
          onCredentialRejected: authService.forceLogout,
        ),
      );

      await expectLater(
        dio.get<dynamic>('/protected'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            403,
          ),
        ),
      );
      expect(storage.clearProvisioningCalls, 0);
      expect(await storage.getApiKey(), 'api-key-1');
      expect(authNotifier.state, isNot(AuthRouteState.needsSetup));
    });

    test('deve deslogar quando a API sinaliza credencial revogada', () async {
      storage.seedTokens(
        accessToken: validToken,
        refreshToken: 'rt-1',
        apiKey: 'api-key-1',
      );

      dio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) => const _AdapterResult(
          statusCode: 403,
          data: {
            'status': 403,
            'error': {
              'code': 'auth.invalid.api.key',
              'message': 'Invalid API Key',
            },
          },
        ),
      );

      final authService = AuthService(
        dio: Dio(),
        storage: storage,
        authNotifier: authNotifier,
      );

      dio.interceptors.add(
        buildInterceptor(
          onRefresh: () async => const RefreshSessionExpired(),
          onCredentialRejected: authService.forceLogout,
        ),
      );

      await expectLater(
        dio.get<dynamic>('/protected'),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      expect(storage.clearProvisioningCalls, 1);
      expect(await storage.getApiKey(), isNull);
      expect(authNotifier.state, AuthRouteState.needsSetup);
    });

    // ── onRequest: fluxo proativo (token expirando) ───────────────────────────

    test(
      'deve fazer refresh proativo quando token está prestes a expirar',
      () async {
        final newToken = validToken;
        storage.seedTokens(
          accessToken: expiringToken, // dentro do buffer de 60s
          refreshToken: 'rt-1',
          apiKey: 'api-key-1',
        );

        // O request nunca chega ao servidor com token antigo — refresh ocorre no onRequest.
        dio.httpClientAdapter = _TestHttpClientAdapter(
          responder: (options) {
            if (options.headers['Authorization'] == 'Bearer $newToken') {
              return const _AdapterResult(statusCode: 200, data: {'ok': true});
            }
            // Se chegou com token expirado, falha o teste.
            return const _AdapterResult(
              statusCode: 401,
              data: {'error': 'bad'},
            );
          },
        );

        dio.interceptors.add(
          buildInterceptor(
            onRefresh: () async {
              refreshCalls += 1;
              await storage.saveAccessToken(newToken);
              return RefreshSuccess(newToken);
            },
          ),
        );

        final response = await dio.get<dynamic>('/protected');

        expect(response.statusCode, 200);
        // Refresh proativo ocorreu no onRequest — nenhum 401 foi recebido.
        expect(refreshCalls, 1);
      },
    );

    test(
      'deve abortar request com cancel quando refresh proativo falha',
      () async {
        storage.seedTokens(
          accessToken: expiringToken,
          refreshToken: 'rt-1',
          apiKey: 'api-key-1',
        );

        dio.httpClientAdapter = _TestHttpClientAdapter(
          responder: (_) =>
              const _AdapterResult(statusCode: 200, data: {'ok': true}),
        );

        dio.interceptors.add(
          buildInterceptor(
            onRefresh: () async {
              refreshCalls += 1;
              return const RefreshSessionExpired(); // refresh falhou
            },
          ),
        );

        await expectLater(
          dio.get<dynamic>('/protected'),
          throwsA(
            isA<DioException>().having(
              (e) => e.type,
              'type',
              DioExceptionType.cancel,
            ),
          ),
        );
        expect(refreshCalls, 1);
      },
    );

    test('não deve fazer refresh proativo para endpoints de auth', () async {
      storage.seedTokens(
        accessToken: expiredToken,
        refreshToken: 'rt-1',
        apiKey: 'api-key-1',
      );

      dio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) =>
            const _AdapterResult(statusCode: 200, data: {'token': 'abc'}),
      );

      dio.interceptors.add(
        buildInterceptor(
          onRefresh: () async {
            refreshCalls += 1;
            return const RefreshSuccess('new-token');
          },
        ),
      );

      // /api/auth/token é um endpoint de auth — deve passar sem refresh.
      final response = await dio.post<dynamic>('/api/auth/token');

      expect(response.statusCode, 200);
      expect(refreshCalls, 0);
    });

    // ── Concorrência ──────────────────────────────────────────────────────────

    test(
      'deve executar somente um refresh para requests concorrentes',
      () async {
        // Tokens com exp distintos para garantir strings diferentes.
        final oldToken = makeJwt(_nowSeconds + 3600); // válido por 1h
        final newToken = makeJwt(_nowSeconds + 7200); // válido por 2h
        storage.seedTokens(
          accessToken: oldToken,
          refreshToken: 'rt-1',
          apiKey: 'api-key-1',
        );

        // Main dio: sempre retorna 401 (simula token expirado no servidor).
        dio.httpClientAdapter = _TestHttpClientAdapter(
          responder: (_) =>
              const _AdapterResult(statusCode: 401, data: {'error': 'expired'}),
        );
        // retryDio: retorna 200 quando o novo token é apresentado.
        retryDio.httpClientAdapter = _TestHttpClientAdapter(
          responder: (options) {
            if (options.headers['Authorization'] == 'Bearer $newToken') {
              return _AdapterResult(
                statusCode: 200,
                data: {'path': options.path},
              );
            }
            return const _AdapterResult(
              statusCode: 401,
              data: {'error': 'bad'},
            );
          },
        );

        dio.interceptors.add(
          buildInterceptor(
            onRefresh: () async {
              refreshCalls += 1;
              await Future<void>.delayed(const Duration(milliseconds: 30));
              await storage.saveAccessToken(newToken);
              return RefreshSuccess(newToken);
            },
          ),
        );

        final responses = await Future.wait([
          dio.get<dynamic>('/protected/a'),
          dio.get<dynamic>('/protected/b'),
          dio.get<dynamic>('/protected/c'),
        ]);

        expect(responses, hasLength(3));
        // O Lock garante que apenas 1 refresh é feito para os 3 requests.
        expect(refreshCalls, 1);
      },
    );

    // ── Resiliência contra exceções de storage / retry ──────────────────────

    test(
      'não pendura request quando storage lança PlatformException em onRequest',
      () async {
        storage.getAccessTokenErrorOnCall = (_) =>
            PlatformException(code: 'READ_ERR', message: 'Keystore locked');

        dio.httpClientAdapter = _TestHttpClientAdapter(
          responder: (_) =>
              const _AdapterResult(statusCode: 200, data: {'ok': true}),
        );
        dio.interceptors.add(
          buildInterceptor(
            onRefresh: () async => const RefreshSessionExpired(),
            onCredentialRejected: () async => storage.clearProvisioning(),
          ),
        );

        await expectLater(
          dio.get<dynamic>('/protected').timeout(const Duration(seconds: 2)),
          throwsA(
            isA<DioException>().having(
              (e) => e.error,
              'error',
              isA<PlatformException>(),
            ),
          ),
        );
      },
    );

    test(
      'não pendura request quando storage lança PlatformException dentro de _refreshUnderLock',
      () async {
        storage.seedTokens(
          accessToken: validToken,
          refreshToken: 'rt-1',
          apiKey: 'api-key-1',
        );
        // 1a chamada (onRequest) ok; 2a chamada (onError -> _refreshUnderLock) lança.
        storage.getAccessTokenErrorOnCall = (call) => call >= 2
            ? PlatformException(code: 'READ_ERR', message: 'Keystore locked')
            : null;

        dio.httpClientAdapter = _TestHttpClientAdapter(
          responder: (_) =>
              const _AdapterResult(statusCode: 401, data: {'error': 'expired'}),
        );
        dio.interceptors.add(
          buildInterceptor(
            onRefresh: () async => const RefreshSessionExpired(),
            onCredentialRejected: () async => storage.clearProvisioning(),
          ),
        );

        await expectLater(
          dio.get<dynamic>('/protected').timeout(const Duration(seconds: 2)),
          throwsA(
            isA<DioException>().having(
              (e) => e.error,
              'error',
              isA<PlatformException>(),
            ),
          ),
        );
      },
    );

    test(
      'não pendura request e atualiza authNotifier quando clearProvisioning falha em onError',
      () async {
        storage.seedTokens(
          accessToken: validToken,
          refreshToken: 'rt-1',
          apiKey: 'api-key-1',
        );
        storage.clearProvisioningError = PlatformException(
          code: 'DEL_ERR',
          message: 'Delete failed',
        );

        dio.httpClientAdapter = _TestHttpClientAdapter(
          responder: (_) => const _AdapterResult(
            statusCode: 403,
            data: {
              'status': 403,
              'error': {
                'code': 'auth.invalid.api.key',
                'message': 'Invalid API Key',
              },
            },
          ),
        );
        dio.interceptors.add(
          buildInterceptor(
            onRefresh: () async => const RefreshSessionExpired(),
            onCredentialRejected: () async => storage.clearProvisioning(),
          ),
        );

        await expectLater(
          dio.get<dynamic>('/protected').timeout(const Duration(seconds: 2)),
          throwsA(
            isA<DioException>().having(
              (e) => e.type,
              'type',
              DioExceptionType.cancel,
            ),
          ),
        );
        expect(authNotifier.state, AuthRouteState.needsSetup);
      },
    );

    test('não pendura request quando retryDio lança exceção não-Dio', () async {
      final newToken = validToken;
      storage.seedTokens(
        accessToken: validToken,
        refreshToken: 'rt-1',
        apiKey: 'api-key-1',
      );

      dio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) =>
            const _AdapterResult(statusCode: 401, data: {'error': 'expired'}),
      );
      retryDio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) => throw StateError('Unexpected adapter crash'),
      );

      dio.interceptors.add(
        buildInterceptor(
          onRefresh: () async {
            await storage.saveAccessToken(newToken);
            return RefreshSuccess(newToken);
          },
        ),
      );

      await expectLater(
        dio.get<dynamic>('/protected').timeout(const Duration(seconds: 2)),
        throwsA(isA<DioException>()),
      );
    });

    // ── Propagação de falhas transitórias de refresh (2.2.4) ──────────────────

    test(
      'deve propagar DioException real no refresh proativo com RefreshTransientFailure',
      () async {
        for (final type in [
          DioExceptionType.connectionError,
          DioExceptionType.connectionTimeout,
        ]) {
          storage.seedTokens(
            accessToken: expiringToken,
            refreshToken: 'rt-1',
            apiKey: 'api-key-1',
          );

          final testDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
          testDio.interceptors.add(
            SecurityInterceptor(
              storage: storage,
              retryDio: retryDio,
              authNotifier: authNotifier,
              onRefresh: () async => RefreshTransientFailure(
                errorType: type,
                error: 'network down',
              ),
            ),
          );

          await expectLater(
            testDio.get<dynamic>('/protected'),
            throwsA(isA<DioException>().having((e) => e.type, 'type', type)),
          );
        }
      },
    );

    test(
      'deve propagar DioException 500 no refresh reativo com RefreshTransientFailure',
      () async {
        storage.seedTokens(
          accessToken: validToken,
          refreshToken: 'rt-1',
          apiKey: 'api-key-1',
        );

        dio.httpClientAdapter = _TestHttpClientAdapter(
          responder: (_) =>
              const _AdapterResult(statusCode: 401, data: {'error': 'expired'}),
        );

        dio.interceptors.add(
          buildInterceptor(
            onRefresh: () async => RefreshTransientFailure(
              errorType: DioExceptionType.badResponse,
              response: Response(
                requestOptions: RequestOptions(path: '/api/auth/refresh'),
                statusCode: 500,
              ),
            ),
          ),
        );

        await expectLater(
          dio.get<dynamic>('/protected'),
          throwsA(
            isA<DioException>()
                .having((e) => e.type, 'type', DioExceptionType.badResponse)
                .having((e) => e.response?.statusCode, 'statusCode', 500),
          ),
        );
      },
    );

    testWidgets(
      'refresh proativo com falha transitória aciona GlobalErrorInterceptor uma única vez sem duplicar no authDio',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            scaffoldMessengerKey: SnackBarUtil().scaffoldKey,
            home: const Scaffold(body: SizedBox.shrink()),
          ),
        );

        storage.seedTokens(
          accessToken: expiringToken,
          refreshToken: 'rt-1',
          apiKey: 'api-key-1',
        );

        // authDio real com GlobalErrorInterceptor, simulando falha de conexão.
        final authDio = Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..interceptors.add(GlobalErrorInterceptor());
        authDio.httpClientAdapter = _TestHttpClientAdapter(
          responder: (options) => throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            error: 'SocketException',
          ),
        );

        final authService = AuthService(
          dio: authDio,
          storage: storage,
          authNotifier: authNotifier,
        );

        dio.interceptors
          ..add(
            SecurityInterceptor(
              storage: storage,
              retryDio: retryDio,
              authNotifier: authNotifier,
              onRefresh: authService.refreshToken,
            ),
          )
          ..add(GlobalErrorInterceptor());

        await tester.runAsync(() async {
          await expectLater(
            dio.get<dynamic>('/protected'),
            throwsA(
              isA<DioException>().having(
                (e) => e.type,
                'type',
                DioExceptionType.connectionError,
              ),
            ),
          );
        });

        await tester.pump();
        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.text('Não foi possível conectar ao servidor.'),
          findsOneWidget,
        );
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      'refresh reativo (401) com falha transitória aciona GlobalErrorInterceptor uma única vez',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            scaffoldMessengerKey: SnackBarUtil().scaffoldKey,
            home: const Scaffold(body: SizedBox.shrink()),
          ),
        );

        storage.seedTokens(
          accessToken: validToken,
          refreshToken: 'rt-1',
          apiKey: 'api-key-1',
        );

        final authDio = Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..interceptors.add(GlobalErrorInterceptor());
        authDio.httpClientAdapter = _TestHttpClientAdapter(
          responder: (_) => const _AdapterResult(
            statusCode: 500,
            data: {'error': 'server down'},
          ),
        );

        final authService = AuthService(
          dio: authDio,
          storage: storage,
          authNotifier: authNotifier,
        );

        dio.httpClientAdapter = _TestHttpClientAdapter(
          responder: (_) =>
              const _AdapterResult(statusCode: 401, data: {'error': 'expired'}),
        );
        dio.interceptors
          ..add(
            SecurityInterceptor(
              storage: storage,
              retryDio: retryDio,
              authNotifier: authNotifier,
              onRefresh: authService.refreshToken,
            ),
          )
          ..add(GlobalErrorInterceptor());

        await tester.runAsync(() async {
          await expectLater(
            dio.get<dynamic>('/protected'),
            throwsA(
              isA<DioException>().having(
                (e) => e.response?.statusCode,
                'statusCode',
                500,
              ),
            ),
          );
        });

        await tester.pump();
        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.text('Erro interno do servidor. Tente novamente mais tarde.'),
          findsOneWidget,
        );
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      'GlobalErrorInterceptor exibe mensagem de timeout para sendTimeout e ignora RefreshSessionExpired',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            scaffoldMessengerKey: SnackBarUtil().scaffoldKey,
            home: const Scaffold(body: SizedBox.shrink()),
          ),
        );

        // 1. RefreshSessionExpired -> cancel -> sem SnackBar.
        storage.seedTokens(
          accessToken: expiringToken,
          refreshToken: 'rt-1',
          apiKey: 'api-key-1',
        );
        final cancelDio = Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..interceptors.add(
            SecurityInterceptor(
              storage: storage,
              retryDio: retryDio,
              authNotifier: authNotifier,
              onRefresh: () async => const RefreshSessionExpired(),
            ),
          )
          ..interceptors.add(GlobalErrorInterceptor());

        await tester.runAsync(() async {
          await expectLater(
            cancelDio.get<dynamic>('/expired'),
            throwsA(
              isA<DioException>().having(
                (e) => e.type,
                'type',
                DioExceptionType.cancel,
              ),
            ),
          );
        });
        await tester.pump();
        expect(find.byType(SnackBar), findsNothing);

        // 2. sendTimeout -> exibe SnackBar de timeout.
        dio.httpClientAdapter = _TestHttpClientAdapter(
          responder: (options) => throw DioException(
            requestOptions: options,
            type: DioExceptionType.sendTimeout,
          ),
        );
        dio.interceptors.add(GlobalErrorInterceptor());

        await tester.runAsync(() async {
          await expectLater(
            dio.get<dynamic>('/send-timeout'),
            throwsA(
              isA<DioException>().having(
                (e) => e.type,
                'type',
                DioExceptionType.sendTimeout,
              ),
            ),
          );
        });

        await tester.pump();
        expect(
          find.text('Tempo de conexão esgotado. Verifique sua internet.'),
          findsOneWidget,
        );
        await tester.pump(const Duration(seconds: 5));
      },
    );
  });
}
