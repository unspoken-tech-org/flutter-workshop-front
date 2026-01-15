import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
            'packageName': 'com.example.flutter_workshop_front',
            'version': '1.1.1',
            'buildNumber': '1',
          };
        }
        return null;
      },
    );
  });

  group('BoundDeviceId Integration Tests', () {
    late MockSecurityStorageWithBoundId storage;
    late AuthService authService;

    setUp(() {
      storage = MockSecurityStorageWithBoundId();
      authService = AuthService(dio: MockDioSuccess(), storage: storage);
    });

    test('Should persist and reuse boundDeviceId across authentications',
        () async {
      // Primeira autenticação
      await authService.authenticate('key-1');
      final firstId = await storage.getBoundDeviceId();
      expect(firstId, isNotEmpty);

      // Segunda autenticação no mesmo storage
      await authService.authenticate('key-1');
      final secondId = await storage.getBoundDeviceId();

      expect(secondId, equals(firstId),
          reason: 'boundDeviceId deve ser o mesmo');
    });
  });
}
