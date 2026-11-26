import '../../support/memory_security_storage.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/core/http/interceptors/global_error_interceptor.dart';
import 'package:flutter_workshop_front/core/http/interceptors/security_interceptor.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/core/security/refresh_result.dart';

/// Gera um JWT minimalista com o timestamp de expiração informado.
String _makeJwt(int expEpochSeconds) {
  final header = base64Url
      .encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'))
      .replaceAll('=', '');
  final payload = base64Url
      .encode(utf8.encode('{"sub":"test","exp":$expEpochSeconds}'))
      .replaceAll('=', '');
  return '$header.$payload.fake-sig';
}

int get _nowSeconds => DateTime.now().millisecondsSinceEpoch ~/ 1000;

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
  group('CustomDio', () {
    test('appDio: SecurityInterceptor antes do GlobalErrorInterceptor; '
        'authDio já nasce com o GlobalErrorInterceptor', () {
      final factory = CustomDio(baseUri: Uri.parse('https://api.test'));

      final appDio = factory.createAppDio(
        storage: MemorySecurityStorage(),
        onRefresh: () async => const RefreshSessionExpired(),
        authNotifier: AuthNotifier(),
      );
      final authDio = factory.createAuthDio();

      final appTypes = appDio.interceptors.map((i) => i.runtimeType).toList();
      expect(
        appTypes.indexOf(SecurityInterceptor),
        lessThan(appTypes.indexOf(GlobalErrorInterceptor)),
      );
      expect(appTypes.last, GlobalErrorInterceptor);
      expect(
        authDio.interceptors.whereType<GlobalErrorInterceptor>(),
        hasLength(1),
      );
      expect(authDio.interceptors.whereType<SecurityInterceptor>(), isEmpty);
      expect(appDio.options.baseUrl, 'https://api.test');
    });

    test('deve executar somente um refresh em escritas concorrentes', () async {
      // Tokens como JWTs válidos: oldToken válido localmente mas rejeitado pelo
      // servidor com 401 (ex: invalidação forçada), newToken válido por 2h.
      final oldToken = _makeJwt(_nowSeconds + 3600);
      final newToken = _makeJwt(_nowSeconds + 7200);

      final storage = MemorySecurityStorage()
        ..seedTokens(accessToken: oldToken, refreshToken: 'rt-1');
      var refreshCalls = 0;

      final adapter = _TestHttpClientAdapter(
        responder: (options) {
          final authHeader = options.headers['Authorization'];
          if (authHeader == 'Bearer $newToken') {
            final status = options.method == 'POST' ? 201 : 200;
            return _AdapterResult(statusCode: status, data: {'ok': true});
          }
          return const _AdapterResult(
            statusCode: 401,
            data: {'error': 'expired'},
          );
        },
      );
      // O adapter vale também para o retryDio interno.
      final dio =
          CustomDio(
            baseUri: Uri.parse('https://api.test'),
            adapter: adapter,
          ).createAppDio(
            storage: storage,
            onRefresh: () async {
              refreshCalls += 1;
              await storage.saveAccessToken(newToken);
              return RefreshSuccess(newToken);
            },
            authNotifier: AuthNotifier(),
          );

      final responses = await Future.wait<Response<dynamic>>([
        dio.post<dynamic>('/v1/payment', data: {'value': 100}),
        dio.put<dynamic>('/v1/device/update', data: {'id': 1}),
      ]);

      expect(responses, hasLength(2));
      expect(refreshCalls, 1);
    });
  });
}
