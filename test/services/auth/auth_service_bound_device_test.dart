import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';

import '../../support/http/stub_http_client_adapter.dart';
import '../../support/memory_security_storage.dart';

StubHttpClientAdapter _successTokenAdapter() {
  return StubHttpClientAdapter.json(
    data: const {
      'accessToken': 'at',
      'refreshToken': 'rt',
      'tokenType': 'Bearer',
      'expiresIn': 3600,
      'refreshExpiresIn': 86400,
    },
  );
}

StubHttpClientAdapter _conflictAdapter() {
  return StubHttpClientAdapter.json(
    status: 409,
    data: const {
      'error': {
        'message': 'API Key já vinculada a outro dispositivo.',
        'code': 'DEVICE_BOUND',
      },
    },
  );
}

void main() {
  group('AuthService — boundDeviceId & 409 conflict', () {
    test('envia boundDeviceId e appVersion no TokenRequest', () async {
      final storage = MemorySecurityStorage(boundDeviceIdFallback: 'new-uuid')
        ..values['bound_device_id'] = 'test-bound-id';
      final adapter = _successTokenAdapter();
      final authService = AuthService(
        dio: testDio(adapter),
        storage: storage,
        authNotifier: AuthNotifier(),
        appVersion: () async => '1.1.1',
      );

      await authService.authenticate('some-api-key');

      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.data, {
        'boundDeviceId': 'test-bound-id',
        'appVersion': '1.1.1',
      });
    });

    test(
      'persiste e reutiliza o mesmo boundDeviceId entre autenticações',
      () async {
        final storage = MemorySecurityStorage(
          boundDeviceIdFallback: 'new-uuid',
        );
        final authService = AuthService(
          dio: testDio(_successTokenAdapter()),
          storage: storage,
          authNotifier: AuthNotifier(),
          appVersion: () async => '1.1.1',
        );

        await authService.authenticate('key-1');
        final firstId = await storage.getBoundDeviceId();
        expect(firstId, isNotEmpty);

        await authService.authenticate('key-1');
        final secondId = await storage.getBoundDeviceId();
        expect(secondId, equals(firstId));
      },
    );

    test(
      'preserva boundDeviceId após logout e reutiliza na reautenticação',
      () async {
        final storage = MemorySecurityStorage(boundDeviceIdFallback: 'new-uuid')
          ..values['bound_device_id'] = 'original-device-id';
        final authService = AuthService(
          dio: testDio(_successTokenAdapter()),
          storage: storage,
          authNotifier: AuthNotifier(),
          appVersion: () async => '1.1.1',
        );

        await authService.authenticate('key-1');
        expect(await storage.getBoundDeviceId(), equals('original-device-id'));

        await authService.logout();
        expect(await storage.getApiKey(), isNull);
        expect(await storage.getBoundDeviceId(), equals('original-device-id'));

        await authService.authenticate('key-1');
        expect(await storage.getBoundDeviceId(), equals('original-device-id'));
      },
    );

    test('lança RequisitionException e não salva API key em 409', () async {
      final storage = MemorySecurityStorage(boundDeviceIdFallback: 'new-uuid');
      final authService = AuthService(
        dio: testDio(_conflictAdapter()),
        storage: storage,
        authNotifier: AuthNotifier(),
        appVersion: () async => '1.1.1',
      );

      await expectLater(
        authService.authenticate('already-bound-key'),
        throwsA(
          isA<RequisitionException>()
              .having(
                (e) => e.message,
                'message',
                contains('API Key já vinculada a outro dispositivo'),
              )
              .having((e) => e.code, 'code', equals('DEVICE_BOUND')),
        ),
      );
      expect(await storage.getApiKey(), isNull);
    });
  });
}
