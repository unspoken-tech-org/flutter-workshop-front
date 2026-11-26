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

  setUp(() {
    final adapter = StubHttpClientAdapter.json(
      status: 409,
      data: const {
        'error': {
          'message': 'API Key já vinculada a outro dispositivo.',
          'code': 'DEVICE_BOUND',
        },
      },
    );
    final authService = AuthService(
      dio: testDio(adapter),
      storage: MemorySecurityStorage(boundDeviceIdFallback: 'new-uuid'),
      authNotifier: AuthNotifier(),
      appVersion: () async => '1.1.1',
    );
    controller = SetupController(authService: authService);
  });

  testWidgets('Should display conflict message on 409 error', (tester) async {
    await pumpAppWidget(tester, SetupPage(controller: controller));

    await tester.enterText(
      find.bySemanticsIdentifier('setup.apiKey'),
      'valid-key',
    );
    await tester.pump();

    await tester.tap(find.bySemanticsIdentifier('setup.submit'));
    await tester.pumpAndSettle();

    expect(
      controller.errorMessage,
      contains('API Key já vinculada a outro dispositivo'),
    );
    expect(
      find.textContaining('API Key já vinculada a outro dispositivo'),
      findsOneWidget,
    );
  });
}
