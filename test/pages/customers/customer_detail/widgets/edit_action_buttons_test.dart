import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/controllers/customer_detail_controller.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/widgets/edit_action_buttons_view.dart';
import 'package:provider/provider.dart';

import '../../../../support/fakes/fake_customer_repository.dart';

void main() {
  testWidgets('durante o salvamento os botões ficam desabilitados com '
      'progresso no Salvar', (tester) async {
    final pending = Completer<Result<CustomerModel>>();
    final controller = CustomerDetailController(
      FakeCustomerRepository(onUpdateCustomer: (_, _) => pending.future),
    )..setEditing(true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: controller,
            child: EditActionButtons(
              customerId: 1,
              onCancel: () {},
              onSave: () => controller.updateCustomer(1),
            ),
          ),
        ),
      ),
    );

    ElevatedButton button(String id) => tester.widget<ElevatedButton>(
      find.descendant(
        of: find.bySemanticsIdentifier(id),
        matching: find.byType(ElevatedButton),
      ),
    );

    await tester.tap(find.text('Salvar'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(button('customerDetail.save').onPressed, isNull);
    expect(button('customerDetail.cancel').onPressed, isNull);

    pending.complete(const Err(NetworkFailure(shownGlobally: true)));
    await tester.pump();

    expect(find.text('Salvar'), findsOneWidget);
    expect(button('customerDetail.save').onPressed, isNotNull);
  });
}
