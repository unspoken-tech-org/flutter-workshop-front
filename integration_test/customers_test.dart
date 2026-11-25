// Customer scenarios against the local E2E API (skill e2e-local-api).
// Run with .agents/skills/flutter-ui-mcp/scripts/run_integration_tests.sh.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/pages/customers/all_customers/widgets/customer_card.dart';
import 'package:integration_test/integration_test.dart';

import 'support/harness.dart';

/// The card shows the name with capitalised words.
Finder _card(String name) => find.ancestor(
  of: find.textContaining(RegExp('^$name\$', caseSensitive: false)),
  matching: find.byType(CustomerCard),
);

Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton).hitTestable());
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'customer list reloads after register and after editing, keeping search',
    (tester) async {
      await bootApp(tester, (tester) async {
        final tag = uniqueTag();
        final name = 'Cliente Teste $tag';
        final search = field(identifier: 'customers.search');

        await tapId(tester, 'drawer.customers');
        await enter(tester, search, tag);
        await pumpUntilFound(tester, find.text('Nenhum cliente encontrado'));

        // Register: the page replaces itself by the detail (pushReplacement).
        await tapId(tester, 'customers.add');
        await enter(tester, field(label: 'Nome'), name);
        await enter(tester, field(label: 'CPF'), randomCpf());
        await enter(tester, field(label: 'Telefone Principal'), randomPhone());
        await tapText(tester, 'Sexo');
        await tapText(tester, 'Masculino');
        await tapId(tester, 'customerRegister.submit');
        await pumpUntilFound(tester, byId('customerDetail.edit'));

        await _back(tester);
        await pumpUntilFound(tester, _card(name));
        expect(fieldText(tester, search), tag);

        // Edit in the detail, then back to the list.
        await tester.tap(_card(name));
        await tapId(tester, 'customerDetail.edit');
        await enter(tester, field(label: 'Nome'), '$name Editado');
        await tapId(tester, 'customerDetail.save');
        await pumpUntilFound(tester, byId('customerDetail.edit'));

        await _back(tester);
        await pumpUntilFound(tester, _card('$name Editado'));
        expect(fieldText(tester, search), tag);
      });
    },
  );

  testWidgets('invalid name and e-mail block saving the customer', (
    tester,
  ) async {
    await bootApp(tester, (tester) async {
      await tapId(tester, 'drawer.customers');
      await tapId(tester, 'customer.card.1');
      await tapId(tester, 'customerDetail.edit');
      final name = field(label: 'Nome');
      await pumpUntilFound(tester, name);
      final original = fieldText(tester, name);

      final putsBefore = proxyRequests('PUT /v1/customer');

      await enter(tester, name, '   ');
      await enter(tester, field(label: 'Email'), 'sem-dominio@');
      await tapId(tester, 'customerDetail.save');
      await pumpUntilFound(tester, find.text('Por favor, insira um nome'));
      expect(find.text('O email é inválido'), findsOneWidget);
      // Still editing, and nothing reached the API.
      expect(byId('customerDetail.save'), findsOneWidget);
      await settleFor(tester, const Duration(milliseconds: 500));
      expect(proxyRequests('PUT /v1/customer'), putsBefore);

      await tapId(tester, 'customerDetail.cancel');
      await pumpUntilFound(tester, byId('customerDetail.edit'));
      expect(fieldText(tester, field(label: 'Nome')), original);
    });
  });
}
