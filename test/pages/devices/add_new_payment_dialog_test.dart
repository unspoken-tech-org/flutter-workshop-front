import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/dialogs/add_new_payment_dialog.dart';
import 'package:provider/provider.dart';

DeviceCustomer _sampleDevice() => DeviceCustomer.fromJson(const {
  'deviceId': 1,
  'customerId': 1,
  'customerName': 'Cliente',
  'deviceStatus': 'EM_ANDAMENTO',
  'brandName': 'Marca',
  'modelName': 'Modelo',
  'typeName': 'Tipo',
  'technicianId': 1,
  'technicianName': 'Tecnico',
  'problem': 'Não liga',
  'observation': '',
  'budget': null,
  'serviceValue': 200.0,
  'budgetFee': 50.0,
  'hasUrgency': false,
  'revision': false,
  'deviceColors': <String>[],
  'entryDate': '2026-01-01T00:00:00',
  'departureDate': null,
  'lastUpdate': null,
  'customerContacts': <dynamic>[],
  'customerPhones': <dynamic>[],
  'otherDevices': <dynamic>[],
  'payments': <dynamic>[],
});

void main() {
  testWidgets(
    'AddNewPaymentDialog preserves typed value and date when category changes, and disposes cleanly',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = DeviceCustomerPageController()
        ..deviceCustomer = _sampleDevice();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: controller,
              child: const AddNewPaymentDialog(),
            ),
          ),
        ),
      );

      final valueField = find.widgetWithText(TextFormField, 'R\$\u00A00,00');
      expect(valueField, findsOneWidget);

      await tester.enterText(valueField, '15000');
      await tester.pump();
      expect(find.textContaining('150,00'), findsOneWidget);

      final now = DateTime.now();
      final targetDay = now.day == 15 ? 10 : 15;
      final expectedDate =
          '${targetDay.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

      final dateField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Data do Pagamento',
      );
      await tester.tap(dateField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('$targetDay'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text(expectedDate), findsOneWidget);

      // Switch category to Taxa de orçamento
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Taxa de orçamento').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('150,00'), findsOneWidget);
      expect(find.text(expectedDate), findsOneWidget);

      // Switch category to Serviços
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Serviços').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('150,00'), findsOneWidget);
      expect(find.text(expectedDate), findsOneWidget);

      // Dispose dialog cleanly (no double-dispose on _dateController/_valueController)
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();
    },
  );
}
