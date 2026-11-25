import '../../support/memory_security_storage.dart';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/pages/setup/setup_controller.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';

class _FixedAdapter implements HttpClientAdapter {
  final int status;
  final String body;
  final String contentType;

  _FixedAdapter(this.status, this.body, this.contentType);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [contentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _authDio(
  int status,
  String body, {
  String contentType = 'application/json',
}) {
  return Dio(
    BaseOptions(
      baseUrl: 'https://test.example.com',
      validateStatus: (status) =>
          status! < 500 && status != 401 && status != 403,
    ),
  )..httpClientAdapter = _FixedAdapter(status, body, contentType);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.fluttercommunity.plus/package_info');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getAll') {
            return <String, dynamic>{
              'appName': 'flutter_workshop_front',
              'version': '1.1.1',
            };
          }
          return null;
        });
  });

  group('AuthService.authenticate — status fora de 200/409', () {
    for (final status in [400, 404, 429]) {
      test(
        '$status lança RequisitionException e não salva a API key',
        () async {
          final storage = MemorySecurityStorage(
            boundDeviceIdFallback: 'new-uuid',
          );
          final notifier = AuthNotifier();
          final service = AuthService(
            dio: _authDio(
              status,
              jsonEncode({
                'error': {'message': 'Falha $status', 'code': 'E$status'},
              }),
            ),
            storage: storage,
            authNotifier: notifier,
          );

          await expectLater(
            service.authenticate('key'),
            throwsA(
              isA<RequisitionException>().having(
                (e) => e.message,
                'message',
                'Falha $status',
              ),
            ),
          );
          expect(await storage.getApiKey(), isNull);
          expect(notifier.state, isNot(AuthRouteState.authenticated));
        },
      );
    }

    test(
      'SetupController não marca sucesso e exibe a mensagem em 429 sem JSON',
      () async {
        final controller = SetupController(
          authService: AuthService(
            dio: _authDio(429, 'Too Many Requests', contentType: 'text/plain'),
            storage: MemorySecurityStorage(boundDeviceIdFallback: 'new-uuid'),
            authNotifier: AuthNotifier(),
          ),
        );

        final result = await controller.authenticate('key');

        expect(result, isFalse);
        expect(controller.isSuccess, isFalse);
        expect(controller.errorMessage, contains('429'));
      },
    );
  });
}
