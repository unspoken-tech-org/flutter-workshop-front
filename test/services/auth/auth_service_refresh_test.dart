import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/security/security_storage.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';

class _MemorySecurityStorage implements SecurityStorage {
  final Map<String, String> _storage = {};
  int clearSessionCalls = 0;
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
    _storage.remove('api_key');
    _storage.remove('access_token');
    _storage.remove('refresh_token');
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
      final service = AuthService(dio: dio, storage: storage);

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
      final service = AuthService(dio: dio, storage: storage);

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
      final service = AuthService(dio: dio, storage: storage);

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
      final service = AuthService(dio: dio, storage: storage);

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
      final service = AuthService(dio: dio, storage: storage);

      final token = await service.refreshToken();

      expect(token, isNull);
      expect(storage.clearSessionCalls, 0);
    });
  });
}
