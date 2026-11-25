import '../support/memory_security_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import '../auth/device_conflict_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(
    'dev.fluttercommunity.plus/package_info',
  );

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'getAll') {
            return <String, dynamic>{
              'appName': 'flutter_workshop_front',
              'version': '1.1.1',
            };
          }
          return null;
        });
  });

  group('Device Conflict Integration Tests', () {
    test(
      'Should handle 409 Conflict correctly in the full service flow',
      () async {
        final storage = MemorySecurityStorage(
          boundDeviceIdFallback: 'new-uuid',
        );
        final authService = AuthService(
          dio: MockDioConflict(),
          storage: storage,
          authNotifier: AuthNotifier(),
        );

        try {
          await authService.authenticate('already-bound-key');
          fail('Deveria ter lançado RequisitionException');
        } on RequisitionException catch (e) {
          expect(
            e.message,
            contains('API Key já vinculada a outro dispositivo'),
          );
          expect(e.code, equals('DEVICE_BOUND'));
        }

        // Verifica que o storage foi limpo em caso de erro conforme a lógica do AuthService
        expect(await storage.getApiKey(), isNull);
      },
    );
  });
}
