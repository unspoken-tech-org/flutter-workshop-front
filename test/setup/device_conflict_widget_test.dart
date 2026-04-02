import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/pages/setup/setup_page.dart';
import 'package:flutter_workshop_front/pages/setup/setup_controller.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';
import '../auth/bound_device_id_test.dart';
import '../auth/device_conflict_test.dart';

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

  late SetupController controller;

  setUp(() {
    final mockAuthService = AuthService(
      dio: MockDioConflict(),
      storage: MockSecurityStorageWithBoundId(),
      authNotifier: AuthNotifier(),
    );
    controller = SetupController(authService: mockAuthService);
  });

  testWidgets('Should display conflict message on 409 error',
      (WidgetTester tester) async {
    // Ignora overflows
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };

    await tester.pumpWidget(
      MaterialApp(
        home: SetupPage(controller: controller),
      ),
    );

    await tester.enterText(find.byType(TextField), 'valid-key');
    await tester.pump();

    await tester.tap(find.byType(ElevatedButton));

    // Usa runAsync para permitir processamento de microtasks e timers do Mock
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 500));
    });

    await tester.pump();

    // Valida primeiro no controller
    expect(controller.errorMessage,
        contains('API Key já vinculada a outro dispositivo'));

    // Agora valida na UI
    expect(find.textContaining('API Key já vinculada a outro dispositivo'),
        findsOneWidget);

    FlutterError.onError = originalOnError;
  });
}
