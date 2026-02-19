import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/pages/setup/setup_page.dart';
import 'package:flutter_workshop_front/pages/setup/setup_controller.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';
import '../auth_pvt_test.dart';
import '../auth/bound_device_id_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SetupController mockController;
  late MockSecurityStorageWithBoundId mockStorage;

  setUp(() {
    mockStorage = MockSecurityStorageWithBoundId();
    final mockAuthService = AuthService(
      dio: MockDio(),
      storage: mockStorage,
      authNotifier: AuthNotifier(),
    );
    mockController = SetupController(authService: mockAuthService);
  });

  Future<void> pumpSetupPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        home: SetupPage(controller: mockController),
      ),
    );
  }

  testWidgets(
      'Should preserve boundDeviceId after reset and allow reauthentication',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) {
        return;
      }
      FlutterError.presentError(details);
    };

    try {
      // Simular que já existe um boundDeviceId armazenado de uma sessão anterior
      mockStorage.storage['bound_device_id'] = 'existing-device-uuid-123';

      await pumpSetupPage(tester);

      // Preencher API Key válida
      await tester.enterText(find.byType(TextField), 'valid-api-key-789');
      await tester.pump();

      // Tentar fazer login novamente
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 300));

      // Verificar que o boundDeviceId foi preservado (não foi gerado um novo)
      final preservedBoundDeviceId = await mockStorage.getBoundDeviceId();
      expect(preservedBoundDeviceId, 'existing-device-uuid-123');
    } finally {
      FlutterError.onError = originalOnError;
    }
  });

  testWidgets('Should allow reauthentication after failed attempt',
      (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) {
        return;
      }
      FlutterError.presentError(details);
    };

    try {
      // Simular boundDeviceId existente
      mockStorage.storage['bound_device_id'] = 'preserved-device-uuid-456';

      await pumpSetupPage(tester);

      // Primeira tentativa com API Key inválida (simulando erro)
      await tester.enterText(find.byType(TextField), 'invalid-key');
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 300));

      // Verificar que o boundDeviceId foi preservado mesmo após falha
      final preservedBoundDeviceId = await mockStorage.getBoundDeviceId();
      expect(preservedBoundDeviceId, 'preserved-device-uuid-456');

      // Segunda tentativa com API Key válida
      await tester.enterText(find.byType(TextField), 'valid-api-key-retry');
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 300));

      // Confirmar que o boundDeviceId permanece o mesmo
      final finalBoundDeviceId = await mockStorage.getBoundDeviceId();
      expect(finalBoundDeviceId, 'preserved-device-uuid-456');
    } finally {
      FlutterError.onError = originalOnError;
    }
  });
}
