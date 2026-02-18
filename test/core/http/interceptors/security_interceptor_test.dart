import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/http/interceptors/duplicate_request_interceptor.dart';
import 'package:flutter_workshop_front/core/http/interceptors/security_interceptor.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/core/security/security_storage.dart';

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

void main() {
  group('SecurityInterceptor', () {
    late _MemorySecurityStorage storage;
    late Dio dio;
    late int refreshCalls;
    late AuthNotifier authNotifier;

    setUp(() {
      storage = _MemorySecurityStorage();
      storage.seedTokens(
        accessToken: 'old-token',
        refreshToken: 'rt-1',
        apiKey: 'api-key-1',
      );
      authNotifier = AuthNotifier();
      refreshCalls = 0;
    });

    test('deve fazer refresh e retry em 401', () async {
      dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (options) {
          final authHeader = options.headers['Authorization'];
          if (authHeader == 'Bearer new-token') {
            return const _AdapterResult(statusCode: 200, data: {'ok': true});
          }
          return const _AdapterResult(
              statusCode: 401, data: {'error': 'expired'});
        },
      );
      dio.interceptors.add(
        SecurityInterceptor(
          storage: storage,
          dio: dio,
          authNotifier: authNotifier,
          onRefresh: () async {
            refreshCalls += 1;
            await storage.saveAccessToken('new-token');
            return 'new-token';
          },
        ),
      );

      final response = await dio.get('/protected');

      expect(response.statusCode, 200);
      expect(refreshCalls, 1);
    });

    test('deve respeitar limite de retry por request', () async {
      dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) =>
            const _AdapterResult(statusCode: 401, data: {'error': 'expired'}),
      );
      dio.interceptors.add(
        SecurityInterceptor(
          storage: storage,
          dio: dio,
          authNotifier: authNotifier,
          onRefresh: () async {
            refreshCalls += 1;
            return 'new-token';
          },
        ),
      );

      await expectLater(
        dio.get('/protected', options: Options(extra: {'authRetryCount': 1})),
        throwsA(isA<DioException>()
            .having((e) => e.response?.statusCode, 'statusCode', 401)),
      );
      expect(refreshCalls, 0);
    });

    test('deve propagar erro real do retry quando retry falha', () async {
      dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      final retryDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) {
          return const _AdapterResult(
              statusCode: 401, data: {'error': 'expired'});
        },
      );
      retryDio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) =>
            const _AdapterResult(statusCode: 500, data: {'error': 'server'}),
      );
      dio.interceptors.add(
        SecurityInterceptor(
          storage: storage,
          dio: retryDio,
          authNotifier: authNotifier,
          onRefresh: () async {
            refreshCalls += 1;
            await storage.saveAccessToken('new-token');
            return 'new-token';
          },
        ),
      );

      await expectLater(
        dio.get('/protected'),
        throwsA(isA<DioException>()
            .having((e) => e.response?.statusCode, 'statusCode', 500)),
      );
      expect(refreshCalls, 1);
    });

    test('deve limpar provisioning em 403 e retornar cancel', () async {
      dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) =>
            const _AdapterResult(statusCode: 403, data: {'error': 'forbidden'}),
      );
      dio.interceptors.add(
        SecurityInterceptor(
          storage: storage,
          dio: dio,
          authNotifier: authNotifier,
          onRefresh: () async => null,
        ),
      );

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

    test('deve executar somente um refresh para requests concorrentes',
        () async {
      dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (options) {
          final authHeader = options.headers['Authorization'];
          if (authHeader == 'Bearer new-token') {
            return _AdapterResult(
                statusCode: 200, data: {'path': options.path});
          }
          return const _AdapterResult(
              statusCode: 401, data: {'error': 'expired'});
        },
      );
      dio.interceptors.add(
        SecurityInterceptor(
          storage: storage,
          dio: dio,
          authNotifier: authNotifier,
          onRefresh: () async {
            refreshCalls += 1;
            await Future<void>.delayed(const Duration(milliseconds: 30));
            await storage.saveAccessToken('new-token');
            return 'new-token';
          },
        ),
      );

      final responses = await Future.wait([
        dio.get('/protected/a'),
        dio.get('/protected/b'),
        dio.get('/protected/c'),
      ]);

      expect(responses, hasLength(3));
      expect(refreshCalls, 1);
    });

    test('retry de auth deve ignorar cache de duplicidade', () async {
      var retryProtectedCalls = 0;
      final retryDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      retryDio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (options) {
          if (options.path == '/protected') {
            retryProtectedCalls += 1;
            final authHeader = options.headers['Authorization'];
            if (authHeader == 'Bearer new-token') {
              return const _AdapterResult(
                  statusCode: 200, data: {'source': 'retry'});
            }
            return const _AdapterResult(
                statusCode: 200, data: {'source': 'prewarm'});
          }
          return const _AdapterResult(statusCode: 404);
        },
      );
      retryDio.interceptors.add(DuplicateRequestInterceptor(milliseconds: 500));

      final prewarmResponse = await retryDio.get('/protected');
      expect(prewarmResponse.data['source'], 'prewarm');

      dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.httpClientAdapter = _TestHttpClientAdapter(
        responder: (_) =>
            const _AdapterResult(statusCode: 401, data: {'error': 'expired'}),
      );
      dio.interceptors.add(
        SecurityInterceptor(
          storage: storage,
          dio: retryDio,
          authNotifier: authNotifier,
          onRefresh: () async {
            refreshCalls += 1;
            await storage.saveAccessToken('new-token');
            return 'new-token';
          },
        ),
      );

      final retriedResponse = await dio.get('/protected');

      expect(retriedResponse.statusCode, 200);
      expect(retriedResponse.data['source'], 'retry');
      expect(retryProtectedCalls, 2,
          reason:
              'Uma chamada de prewarm e outra de retry real; sem bypass retornaria cache antigo.');
    });
  });
}
