import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/pages/customers/customer_register/controllers/customer_register_controller.dart';
import 'package:flutter_workshop_front/pages/customers/customer_register/widgets/customer_register_form.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:provider/provider.dart';

class _StubCustomerRepository extends Fake implements CustomerRepository {}

Widget _wrap() => MaterialApp(
  home: Scaffold(
    body: ChangeNotifierProvider(
      create: (_) => CustomerRegisterController(_StubCustomerRepository()),
      child: const CustomerRegisterForm(),
    ),
  ),
);

void main() {
  group('CustomerRegisterForm', () {
    testWidgets('botão Limpar limpa campos, sexo e telefones secundários', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap());

      final clearButton = find.widgetWithText(ElevatedButton, 'Limpar');
      expect(tester.widget<ElevatedButton>(clearButton).onPressed, isNotNull);

      await tester.enterText(find.widgetWithText(TextFormField, 'Nome'), 'Ana');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email (opcional)'),
        'ana@x.com',
      );

      await tester.tap(find.text('Sexo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Feminino').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adicionar telefone secundário'));
      await tester.pumpAndSettle();

      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('ana@x.com'), findsOneWidget);
      expect(find.text('Feminino'), findsOneWidget);
      final fieldsWithPhone = find.byType(TextFormField).evaluate().length;

      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(find.text('Ana'), findsNothing);
      expect(find.text('ana@x.com'), findsNothing);
      expect(find.text('Feminino'), findsNothing);
      expect(
        find.byType(TextFormField).evaluate().length,
        lessThan(fieldsWithPhone),
      );
    });
  });
}
