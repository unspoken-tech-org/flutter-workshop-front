import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/pages/setup/setup_controller.dart';
import 'package:flutter_workshop_front/pages/setup/setup_page.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';

import '../../support/http/stub_http_client_adapter.dart';
import '../../support/memory_security_storage.dart';
import '../../support/widget_test_harness.dart';

void main() {
  late SetupController controller;
  late MemorySecurityStorage storage;

  setUp(() {
    storage = MemorySecurityStorage(boundDeviceIdFallback: 'new-uuid');
    final authService = AuthService(
      dio: testDio(StubHttpClientAdapter.fixed()),
      storage: storage,
      authNotifier: AuthNotifier(),
      appVersion: () async => '1.1.1',
    );
    controller = SetupController(authService: authService);
  });

  testWidgets(
    'Should preserve boundDeviceId after reset and allow reauthentication',
    (tester) async {
      storage.values['bound_device_id'] = 'existing-device-uuid-123';

      await pumpAppWidget(tester, SetupPage(controller: controller));

      await tester.enterText(
        find.bySemanticsIdentifier('setup.apiKey'),
        'valid-api-key-789',
      );
      await tester.pump();

      await tester.tap(find.bySemanticsIdentifier('setup.submit'));
      await tester.pumpAndSettle();

      expect(await storage.getBoundDeviceId(), 'existing-device-uuid-123');
    },
  );

  testWidgets('Should allow reauthentication after failed attempt', (
    tester,
  ) async {
    storage.values['bound_device_id'] = 'preserved-device-uuid-456';

    await pumpAppWidget(tester, SetupPage(controller: controller));

    await tester.enterText(
      find.bySemanticsIdentifier('setup.apiKey'),
      'invalid-key',
    );
    await tester.pump();
    await tester.tap(find.bySemanticsIdentifier('setup.submit'));
    await tester.pumpAndSettle();

    expect(await storage.getBoundDeviceId(), 'preserved-device-uuid-456');

    await tester.enterText(
      find.bySemanticsIdentifier('setup.apiKey'),
      'valid-api-key-retry',
    );
    await tester.pump();
    await tester.tap(find.bySemanticsIdentifier('setup.submit'));
    await tester.pumpAndSettle();

    expect(await storage.getBoundDeviceId(), 'preserved-device-uuid-456');
  });
}
