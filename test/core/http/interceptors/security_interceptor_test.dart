import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/http/interceptors/security_interceptor.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/core/security/security_storage.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Gera um JWT minimalista com o timestamp de expiração informado.
/// Não é assinado de forma válida, mas é suficiente para o JwtDecoder ler o `exp`.
String makeJwt(int expEpochSeconds) {
  final header =
      base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}')).replaceAll('=', '');
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
    await clearSession();
    _storage.remove('api_key');
    if (removeBoundDeviceId) {
      _storage.remove('bound_device_id');
    }
  }

  @override
  Future<String?> getAccessToken() async => _storage['access_token'];

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
      required Future<String?> Function() onRefresh,
    }) {
      return SecurityInterceptor(
        storage: storage,
        retryDio: retryDio,
        authNotifier: authNotifier,
        onRefresh: onRefresh,
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

      dio.interceptors.add(buildInterceptor(
        onRefresh: () async {
          refreshCalls += 1;
          await storage.saveAccessToken(newToken);
          return newToken;
        },
      ));

      final response = await dio.get('/protected');

      expect(response.statusCode, 200);
      expect(refreshCalls, 1);
    });

    test('deve propagar 401 sem novo refresh quando retry também falha com 401',
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
        responder: (_) =>
            const _AdapterResult(statusCode: 401, data: {'error': 'still bad'}),
      );

      dio.interceptors.add(buildInterceptor(
        onRefresh: () async {
          refreshCalls += 1;
          await storage.saveAccessToken(newToken);
          return newToken;
        },
      ));

      await expectLater(
        dio.get('/protected'),
        throwsA(isA<DioException>()
            .having((e) => e.response?.statusCode, 'statusCode', 401)),
      );
      // Refresh acontece apenas uma vez — o 401 do retry não aciona outro refresh.
      expect(refreshCalls, 1);
    });

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

      dio.interceptors.add(buildInterceptor(
        onRefresh: () async {
          refreshCalls += 1;
          await storage.saveAccessToken(newToken);
          return newToken;
        },
      ));

      await expectLater(
        dio.get('/protected'),
        throwsA(isA<DioException>()
            .having((e) => e.response?.statusCode, 'statusCode', 500)),
      );
      expect(refreshCalls, 1);
    });

    test('deve retornar cancel quando refresh retorna null em 401', () async {
      storage.seedTokens(
        accessToken: validToken,
        refreshToken: 'rt-1',
        apiKey: 'api-key-1',
      );

      dio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) =>
            const _AdapterResult(statusCode: 401, data: {'error': 'expired'}),
      );

      dio.interceptors.add(buildInterceptor(
        onRefresh: () async {
          refreshCalls += 1;
          return null;
        },
      ));

      await expectLater(
        dio.get('/protected'),
        throwsA(
          isA<DioException>()
              .having((e) => e.type, 'type', DioExceptionType.cancel),
        ),
      );
      expect(refreshCalls, 1);
    });

    test('deve limpar sessao em 403 e retornar cancel', () async {
      storage.seedTokens(
        accessToken: validToken,
        refreshToken: 'rt-1',
        apiKey: 'api-key-1',
      );

      dio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) =>
            const _AdapterResult(statusCode: 403, data: {'error': 'forbidden'}),
      );

      dio.interceptors.add(buildInterceptor(onRefresh: () async => null));

      await expectLater(
        dio.get('/forbidden'),
        throwsA(
          isA<DioException>()
              .having((e) => e.type, 'type', DioExceptionType.cancel),
        ),
      );
      expect(storage.clearProvisioningCalls, 1);
      expect(storage.clearSessionCalls, 1);
      expect(await storage.getApiKey(), isNull);
    });

    // ── onRequest: fluxo proativo (token expirando) ───────────────────────────

    test('deve fazer refresh proativo quando token está prestes a expirar',
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
          return const _AdapterResult(statusCode: 401, data: {'error': 'bad'});
        },
      );

      dio.interceptors.add(buildInterceptor(
        onRefresh: () async {
          refreshCalls += 1;
          await storage.saveAccessToken(newToken);
          return newToken;
        },
      ));

      final response = await dio.get('/protected');

      expect(response.statusCode, 200);
      // Refresh proativo ocorreu no onRequest — nenhum 401 foi recebido.
      expect(refreshCalls, 1);
    });

    test('deve abortar request com cancel quando refresh proativo falha', () async {
      storage.seedTokens(
        accessToken: expiringToken,
        refreshToken: 'rt-1',
        apiKey: 'api-key-1',
      );

      dio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) =>
            const _AdapterResult(statusCode: 200, data: {'ok': true}),
      );

      dio.interceptors.add(buildInterceptor(
        onRefresh: () async {
          refreshCalls += 1;
          return null; // refresh falhou
        },
      ));

      await expectLater(
        dio.get('/protected'),
        throwsA(
          isA<DioException>()
              .having((e) => e.type, 'type', DioExceptionType.cancel),
        ),
      );
      expect(refreshCalls, 1);
    });

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

      dio.interceptors.add(buildInterceptor(
        onRefresh: () async {
          refreshCalls += 1;
          return 'new-token';
        },
      ));

      // /api/auth/token é um endpoint de auth — deve passar sem refresh.
      final response = await dio.post('/api/auth/token');

      expect(response.statusCode, 200);
      expect(refreshCalls, 0);
    });

    // ── Concorrência ──────────────────────────────────────────────────────────

    test('deve executar somente um refresh para requests concorrentes',
        () async {
      // Tokens com exp distintos para garantir strings diferentes.
      final oldToken = makeJwt(_nowSeconds + 3600);  // válido por 1h
      final newToken = makeJwt(_nowSeconds + 7200);  // válido por 2h
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
                statusCode: 200, data: {'path': options.path});
          }
          return const _AdapterResult(statusCode: 401, data: {'error': 'bad'});
        },
      );

      dio.interceptors.add(buildInterceptor(
        onRefresh: () async {
          refreshCalls += 1;
          await Future<void>.delayed(const Duration(milliseconds: 30));
          await storage.saveAccessToken(newToken);
          return newToken;
        },
      ));

      final responses = await Future.wait([
        dio.get('/protected/a'),
        dio.get('/protected/b'),
        dio.get('/protected/c'),
      ]);

      expect(responses, hasLength(3));
      // O Lock garante que apenas 1 refresh é feito para os 3 requests.
      expect(refreshCalls, 1);
    });
  });
}
