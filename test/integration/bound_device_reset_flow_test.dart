import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';
import '../auth/bound_device_id_test.dart';

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
            'version': '1.1.1',
          };
        }
        return null;
      },
    );
  });

  group('BoundDeviceId Reset Integration Tests', () {
    test('Should simulate administrative reset and reuse same device ID',
        () async {
      final storage = MockSecurityStorageWithBoundId();
      final authService = AuthService(
        dio: MockDioSuccess(),
        storage: storage,
        authNotifier: AuthNotifier(),
      );

      // 1. Vincula inicial
      await authService.authenticate('key-1');
      final deviceId = await storage.getBoundDeviceId();

      // 2. Logout (simula sessão encerrada mas dispositivo mantido)
      await authService.logout();

      // 3. Re-autentica (simula pós reset no backend se o backend permitir o mesmo ID)
      await authService.authenticate('key-1');
      final secondDeviceId = await storage.getBoundDeviceId();

      expect(secondDeviceId, equals(deviceId),
          reason: 'Deve reusar o ID persistido');
    });
  });
}
