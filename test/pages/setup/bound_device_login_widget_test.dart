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
    final storage = MemorySecurityStorage(boundDeviceIdFallback: 'new-uuid');
    final authService = AuthService(
      dio: testDio(StubHttpClientAdapter.fixed()),
      storage: storage,
      authNotifier: AuthNotifier(),
      appVersion: () async => '1.1.1',
    );
    controller = SetupController(authService: authService);
  });

  testWidgets('Should display setup page correctly', (tester) async {
    await pumpAppWidget(tester, SetupPage(controller: controller));

    expect(find.text('Configuração Inicial'), findsOneWidget);
    expect(find.text('Eletroluk WorkShop'), findsOneWidget);
  });

  testWidgets('Should show error when API Key is empty', (tester) async {
    await pumpAppWidget(tester, SetupPage(controller: controller));

    // O botão fica desabilitado com texto vazio; espaços habilitam o botão
    // mas falham na validação do controller.
    await tester.enterText(find.bySemanticsIdentifier('setup.apiKey'), '   ');
    await tester.pump();

    await tester.tap(find.bySemanticsIdentifier('setup.submit'));
    await tester.pump();

    expect(find.text('A API Key não pode estar vazia.'), findsOneWidget);
  });
}
