import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/pages/setup/setup_controller.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';

import '../../support/http/stub_http_client_adapter.dart';
import '../../support/memory_security_storage.dart';

void main() {
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
            dio: testDio(
              StubHttpClientAdapter.fixed(
                status: status,
                body: jsonEncode({
                  'error': {'message': 'Falha $status', 'code': 'E$status'},
                }),
              ),
            ),
            storage: storage,
            authNotifier: notifier,
            appVersion: () async => '1.1.1',
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
            dio: testDio(
              StubHttpClientAdapter.fixed(
                status: 429,
                body: 'Too Many Requests',
                contentType: Headers.textPlainContentType,
              ),
            ),
            storage: MemorySecurityStorage(boundDeviceIdFallback: 'new-uuid'),
            authNotifier: AuthNotifier(),
            appVersion: () async => '1.1.1',
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
