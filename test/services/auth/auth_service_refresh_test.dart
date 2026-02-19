import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/core/security/security_storage.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';

class _MemorySecurityStorage implements SecurityStorage {
  final Map<String, String> _storage = {};
  int clearSessionCalls = 0;
  int clearProvisioningCalls = 0;
  int saveAccessTokenCalls = 0;
  int saveTokensCalls = 0;

  void seedTokens({String? accessToken, String? refreshToken}) {
    if (accessToken != null) _storage['access_token'] = accessToken;
    if (refreshToken != null) _storage['refresh_token'] = refreshToken;
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
    saveAccessTokenCalls += 1;
    _storage['access_token'] = accessToken;
  }

  @override
  Future<void> saveApiKey(String key) async {
    _storage['api_key'] = key;
  }

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    saveTokensCalls += 1;
    _storage['access_token'] = accessToken;
    _storage['refresh_token'] = refreshToken;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

typedef _PostHandler = Future<Response<dynamic>> Function(Object? data);

class _FakeDio implements Dio {
  @override
  BaseOptions options = BaseOptions();

  final Map<String, _PostHandler> handlers;

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
    final handler = handlers[path];
    if (handler == null) {
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {} as T,
      );
    }
    final response = await handler(data);
    return Response<T>(
      requestOptions: response.requestOptions,
      statusCode: response.statusCode,
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
}) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: path),
    statusCode: statusCode,
    data: data,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel('dev.fluttercommunity.plus/package_info');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, dynamic>{
            'appName': 'flutter_workshop_front',
            'packageName': 'com.example.flutter_workshop_front',
            'version': '1.1.1',
            'buildNumber': '1',
          };
        }
        return null;
      },
    );
  });

  group('AuthService.refreshToken', () {
    test('deve salvar access e refresh quando backend rotaciona token',
        () async {
      final storage = _MemorySecurityStorage()
        ..seedTokens(refreshToken: 'rt-1');
      final dio = _FakeDio({
        '/api/auth/refresh': (data) async => _response(
              '/api/auth/refresh',
              statusCode: 200,
              data: {'accessToken': 'at-2', 'refreshToken': 'rt-2'},
            ),
      });
      final service = AuthService(
        dio: dio,
        storage: storage,
        authNotifier: AuthNotifier(),
      );

      final token = await service.refreshToken();

      expect(token, 'at-2');
      expect(await storage.getAccessToken(), 'at-2');
      expect(await storage.getRefreshToken(), 'rt-2');
      expect(storage.saveTokensCalls, 1);
      expect(storage.saveAccessTokenCalls, 0);
    });

    test(
        'deve salvar apenas access token quando refresh token nao vem na resposta',
        () async {
      final storage = _MemorySecurityStorage()
        ..seedTokens(refreshToken: 'rt-1');
      final dio = _FakeDio({
        '/api/auth/refresh': (data) async => _response(
              '/api/auth/refresh',
              statusCode: 200,
              data: {'accessToken': 'at-2'},
            ),
      });
      final service = AuthService(
        dio: dio,
        storage: storage,
        authNotifier: AuthNotifier(),
      );

      final token = await service.refreshToken();

      expect(token, 'at-2');
      expect(await storage.getAccessToken(), 'at-2');
      expect(await storage.getRefreshToken(), 'rt-1');
      expect(storage.saveTokensCalls, 0);
      expect(storage.saveAccessTokenCalls, 1);
    });

    test('deve invalidar sessao quando payload de refresh for invalido',
        () async {
      final storage = _MemorySecurityStorage()
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
        dio: dio,
        storage: storage,
        authNotifier: AuthNotifier(),
      );

      final token = await service.refreshToken();

      expect(token, isNull);
      expect(storage.clearSessionCalls, 1);
    });

    test('deve invalidar sessao em status 401 do refresh', () async {
      final storage = _MemorySecurityStorage()
        ..seedTokens(refreshToken: 'rt-1');
      final dio = _FakeDio({
        '/api/auth/refresh': (data) async =>
            _response('/api/auth/refresh', statusCode: 401),
        '/api/auth/revoke': (data) async =>
            _response('/api/auth/revoke', statusCode: 200),
      });
      final service = AuthService(
        dio: dio,
        storage: storage,
        authNotifier: AuthNotifier(),
      );

      final token = await service.refreshToken();

      expect(token, isNull);
      expect(storage.clearSessionCalls, 1);
    });

    test('nao deve invalidar sessao em status 500 do refresh', () async {
      final storage = _MemorySecurityStorage()
        ..seedTokens(refreshToken: 'rt-1');
      final dio = _FakeDio({
        '/api/auth/refresh': (data) async =>
            _response('/api/auth/refresh', statusCode: 500),
      });
      final service = AuthService(
        dio: dio,
        storage: storage,
        authNotifier: AuthNotifier(),
      );

      final token = await service.refreshToken();

      expect(token, isNull);
      expect(storage.clearSessionCalls, 0);
    });
  });

  group('AuthService bootstrap/session', () {
    late AuthNotifier authNotifier;

    setUp(() {
      authNotifier = AuthNotifier(initialState: AuthRouteState.restoring);
    });

    test('deve restaurar sessao via api key salva quando nao ha tokens',
        () async {
      final storage = _MemorySecurityStorage();
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
        dio: dio,
        storage: storage,
        authNotifier: authNotifier,
      );

      final restored = await service.restoreSessionFromStoredApiKey();

      expect(restored, isTrue);
      expect(await storage.getAccessToken(), 'at-1');
      expect(await storage.getRefreshToken(), 'rt-1');
    });

    test('deve limpar provisioning quando authenticate falha com 401',
        () async {
      final storage = _MemorySecurityStorage();
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
    });

    test('deve falhar restore e limpar provisioning em api key invalida',
        () async {
      final storage = _MemorySecurityStorage();
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
        dio: dio,
        storage: storage,
        authNotifier: authNotifier,
      );

      final restored = await service.restoreSessionFromStoredApiKey();

      expect(restored, isFalse);
      expect(storage.clearProvisioningCalls, 1);
      expect(await storage.getApiKey(), isNull);
    });

    test('initializeAuthState deve autenticar quando sessao ja existe',
        () async {
      final storage = _MemorySecurityStorage()
        ..seedTokens(accessToken: 'at-1', refreshToken: 'rt-1');
      final dio = _FakeDio({});
      final service = AuthService(
        dio: dio,
        storage: storage,
        authNotifier: authNotifier,
      );

      final state = await service.initializeAuthState();

      expect(state, AuthRouteState.authenticated);
      expect(authNotifier.state, AuthRouteState.authenticated);
    });

    test('initializeAuthState deve ir para setup em erro de rede no bootstrap',
        () async {
      final storage = _MemorySecurityStorage();
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
        dio: dio,
        storage: storage,
        authNotifier: authNotifier,
      );

      final state = await service.initializeAuthState();

      expect(state, AuthRouteState.needsSetup);
      expect(authNotifier.state, AuthRouteState.needsSetup);
      expect(await storage.getApiKey(), 'key-1');
    });
  });
}
