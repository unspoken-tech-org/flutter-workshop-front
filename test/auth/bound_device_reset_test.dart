import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';
import 'bound_device_id_test.dart';

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

  group('BoundDeviceId Reset Unit Tests', () {
    test('Should preserve boundDeviceId after logout/clearSession', () async {
      final storage = MockSecurityStorageWithBoundId();
      final authService = AuthService(dio: MockDioSuccess(), storage: storage);

      storage.storage['bound_device_id'] = 'original-device-id';

      await authService.authenticate('key-1');
      expect(await storage.getBoundDeviceId(), equals('original-device-id'));

      await authService.logout();

      expect(await storage.getApiKey(), isNull);
      expect(await storage.getBoundDeviceId(), equals('original-device-id'),
          reason: 'O boundDeviceId deve ser preservado após logout');
    });
  });
}
