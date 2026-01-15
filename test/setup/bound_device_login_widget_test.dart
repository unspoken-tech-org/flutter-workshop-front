import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    final mockAuthService = AuthService(dio: MockDio(), storage: mockStorage);
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

  testWidgets('Should display setup page correctly',
      (WidgetTester tester) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) {
        return;
      }
      FlutterError.presentError(details);
    };

    await pumpSetupPage(tester);

    expect(find.text('Configuração Inicial'), findsOneWidget);
    expect(find.text('Eletroluk Workshop'), findsOneWidget);
  });

  testWidgets('Should show error when API Key is empty',
      (WidgetTester tester) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) {
        return;
      }
      FlutterError.presentError(details);
    };

    await pumpSetupPage(tester);

    // No teste, o botão está desabilitado se o texto estiver vazio conforme lib/pages/setup/widgets/setup_action_button.dart:24
    // Então vamos preencher com espaços para habilitar mas falhar na validação do controller
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.text('A API Key não pode estar vazia.'), findsOneWidget);
  });
}
