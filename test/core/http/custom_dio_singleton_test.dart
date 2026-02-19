import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/core/security/security_storage.dart';

class _MemorySecurityStorage implements SecurityStorage {
  final Map<String, String> _storage = {};

  void seedTokens({String? accessToken, String? refreshToken}) {
    if (accessToken != null) _storage['access_token'] = accessToken;
    if (refreshToken != null) _storage['refresh_token'] = refreshToken;
  }

  @override
  Future<void> clearAll() async => _storage.clear();

  @override
  Future<void> clearSession() async {
    _storage.remove('access_token');
    _storage.remove('refresh_token');
  }

  @override
  Future<void> clearProvisioning({bool removeBoundDeviceId = false}) async {
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
  Future<String> getBoundDeviceId() async => _storage['bound_device_id'] ?? 'd';

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
  group('CustomDio singleton', () {
    setUpAll(() {
      dotenv.testLoad(fileInput: 'BASE_URL=https://example.test\n');
    });

    setUp(CustomDio.resetForTest);
    tearDown(CustomDio.resetForTest);

    test('deve reutilizar a mesma instancia para chamadas autenticadas', () {
      final storage = _MemorySecurityStorage();
      CustomDio.setup(storage, () async => null, AuthNotifier());

      final first = CustomDio.dioInstance();
      final second = CustomDio.dioInstance();

      expect(identical(first, second), isTrue);
    });

    test('deve executar somente um refresh em escritas concorrentes', () async {
      final storage = _MemorySecurityStorage()
        ..seedTokens(accessToken: 'old-token', refreshToken: 'rt-1');
      var refreshCalls = 0;

      CustomDio.setup(
        storage,
        () async {
          refreshCalls += 1;
          await storage.saveAccessToken('new-token');
          return 'new-token';
        },
        AuthNotifier(),
      );

      final dioA = CustomDio.dioInstance();
      final dioB = CustomDio.dioInstance();
      dioA.httpClientAdapter = _TestHttpClientAdapter(
        responder: (options) {
          final authHeader = options.headers['Authorization'];
          if (authHeader == 'Bearer new-token') {
            final status = options.method == 'POST' ? 201 : 200;
            return _AdapterResult(statusCode: status, data: {'ok': true});
          }
          return const _AdapterResult(
            statusCode: 401,
            data: {'error': 'expired'},
          );
        },
      );

      final responses = await Future.wait([
        dioA.post('/v1/payment', data: {'value': 100}),
        dioB.put('/v1/device/update', data: {'id': 1}),
      ]);

      expect(responses, hasLength(2));
      expect(refreshCalls, 1);
    });
  });
}
