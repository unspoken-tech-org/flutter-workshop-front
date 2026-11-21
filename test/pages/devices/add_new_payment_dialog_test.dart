import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/money/money.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_device_payment.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/input_payment.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/customer_device_payments.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/dialogs/add_new_payment_dialog.dart';
import 'package:provider/provider.dart';

class _FakeDeviceCustomerPageController extends DeviceCustomerPageController {
  InputPayment? lastCreatedPayment;

  @override
  DeviceCustomer? get persistedDeviceCustomer => deviceCustomer;

  @override
  Future<void> createCustomerDevicePayment(InputPayment payment) async {
    lastCreatedPayment = payment;
  }
}

DeviceCustomer _sampleDevice({
  String deviceStatus = 'EM_ANDAMENTO',
  double? serviceValue = 200.0,
  double? budgetFee = 50.0,
  String entryDate = '2026-01-01T00:00:00',
  List<Map<String, dynamic>> payments = const [],
}) => DeviceCustomer.fromJson({
  'deviceId': 1,
  'customerId': 1,
  'customerName': 'Cliente',
  'deviceStatus': deviceStatus,
  'brandName': 'Marca',
  'modelName': 'Modelo',
  'typeName': 'Tipo',
  'technicianId': 1,
  'technicianName': 'Tecnico',
  'problem': 'Não liga',
  'observation': '',
  'budget': null,
  'serviceValue': serviceValue,
  'budgetFee': budgetFee,
  'hasUrgency': false,
  'revision': false,
  'deviceColors': const <String>[],
  'entryDate': entryDate,
  'departureDate': null,
  'lastUpdate': null,
  'customerContacts': const <dynamic>[],
  'customerPhones': const <dynamic>[],
  'otherDevices': const <dynamic>[],
  'payments': payments,
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

  Future<void> pumpDialog(
    WidgetTester tester,
    _FakeDeviceCustomerPageController controller,
  ) async {
    tester.view.physicalSize = const Size(1600, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<DeviceCustomerPageController>.value(
            value: controller,
            child: const AddNewPaymentDialog(),
          ),
        ),
      ),
    );
  }

  Future<void> fillRequiredFields(
    WidgetTester tester, {
    required String categoryLabel,
    required String centsDigits,
    String paymentTypeLabel = 'Pix',
  }) async {
    final dropdowns = find.byType(DropdownButtonFormField<String>);

    // Category
    await tester.tap(dropdowns.at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text(categoryLabel).last);
    await tester.pumpAndSettle();

    // Payment type
    await tester.tap(dropdowns.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text(paymentTypeLabel).last);
    await tester.pumpAndSettle();

    // Value
    final valueField = find.widgetWithText(TextFormField, 'R\$\u00A00,00');
    await tester.enterText(valueField, centsDigits);
    await tester.pump();

    // Received by
    await tester.tap(dropdowns.at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tecnico').last);
    await tester.pumpAndSettle();
  }

  testWidgets('NOVO allows Taxa de orçamento payment', (tester) async {
    final controller = _FakeDeviceCustomerPageController()
      ..technicians = [Technician(id: 1, name: 'tecnico', number: '123')]
      ..deviceCustomer = _sampleDevice(deviceStatus: 'NOVO');

    await pumpDialog(tester, controller);
    await fillRequiredFields(
      tester,
      categoryLabel: 'Taxa de orçamento',
      centsDigits: '5000',
    );

    await tester.tap(find.text('Adicionar Pagamento'));
    await tester.pumpAndSettle();

    expect(controller.lastCreatedPayment, isNotNull);
    expect(controller.lastCreatedPayment!.category, PaymentCategory.budgetFee);
    expect(controller.lastCreatedPayment!.value, const Money.fromCents(5000));
  });

  testWidgets('NOVO rejects Serviços payment', (tester) async {
    final controller = _FakeDeviceCustomerPageController()
      ..technicians = [Technician(id: 1, name: 'tecnico', number: '123')]
      ..deviceCustomer = _sampleDevice(deviceStatus: 'NOVO');

    await pumpDialog(tester, controller);
    await fillRequiredFields(
      tester,
      categoryLabel: 'Serviços',
      centsDigits: '5000',
    );

    await tester.tap(find.text('Adicionar Pagamento'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Pagamentos de serviços não são permitidos para aparelho com status Novo',
      ),
      findsOneWidget,
    );
    expect(controller.lastCreatedPayment, isNull);
  });

  testWidgets('Serviços rejects when serviceValue is null or zero', (
    tester,
  ) async {
    final controller = _FakeDeviceCustomerPageController()
      ..technicians = [Technician(id: 1, name: 'tecnico', number: '123')]
      ..deviceCustomer = _sampleDevice(serviceValue: null);

    await pumpDialog(tester, controller);
    await fillRequiredFields(
      tester,
      categoryLabel: 'Serviços',
      centsDigits: '5000',
    );

    await tester.tap(find.text('Adicionar Pagamento'));
    await tester.pumpAndSettle();

    expect(find.text('Valor do serviço não definido'), findsOneWidget);
    expect(controller.lastCreatedPayment, isNull);
  });

  testWidgets('Serviços rejects when totalPaid + value exceeds serviceValue', (
    tester,
  ) async {
    final controller = _FakeDeviceCustomerPageController()
      ..technicians = [Technician(id: 1, name: 'tecnico', number: '123')]
      ..deviceCustomer = _sampleDevice(
        serviceValue: 200.0,
        payments: const [
          {
            'paymentId': 1,
            'paymentDate': '2026-01-02T00:00:00',
            'paymentType': 'pix',
            'paymentValue': 50.0,
            'category': 'taxa_orcamento',
            'receivedBy': 'Tecnico',
          },
          {
            'paymentId': 2,
            'paymentDate': '2026-01-03T00:00:00',
            'paymentType': 'pix',
            'paymentValue': 100.0,
            'category': 'servicos',
            'receivedBy': 'Tecnico',
          },
        ],
      );

    await pumpDialog(tester, controller);
    await fillRequiredFields(
      tester,
      categoryLabel: 'Serviços',
      centsDigits: '5001',
    );

    await tester.tap(find.text('Adicionar Pagamento'));
    await tester.pumpAndSettle();

    expect(find.textContaining('excede o valor do serviço'), findsOneWidget);
    expect(controller.lastCreatedPayment, isNull);
  });

  testWidgets('paymentDate before entryDate is rejected', (tester) async {
    final now = DateTime.now();
    final futureEntry = DateTime(now.year, now.month, now.day + 1, 14, 30);
    final controller = _FakeDeviceCustomerPageController()
      ..technicians = [Technician(id: 1, name: 'tecnico', number: '123')]
      ..deviceCustomer = _sampleDevice(
        entryDate: futureEntry.toIso8601String(),
      );

    await pumpDialog(tester, controller);
    await fillRequiredFields(
      tester,
      categoryLabel: 'Serviços',
      centsDigits: '5000',
    );

    await tester.tap(find.text('Adicionar Pagamento'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'A data do pagamento não pode ser anterior à data de entrada',
      ),
      findsOneWidget,
    );
    expect(controller.lastCreatedPayment, isNull);
  });

  testWidgets(
    'same-day paymentDate is allowed when entryDate has non-midnight time',
    (tester) async {
      final now = DateTime.now();
      final sameDayEntry = DateTime(now.year, now.month, now.day, 14, 30);
      final controller = _FakeDeviceCustomerPageController()
        ..technicians = [Technician(id: 1, name: 'tecnico', number: '123')]
        ..deviceCustomer = _sampleDevice(
          entryDate: sameDayEntry.toIso8601String(),
        );

      await pumpDialog(tester, controller);
      await fillRequiredFields(
        tester,
        categoryLabel: 'Serviços',
        centsDigits: '5000',
      );

      await tester.tap(find.text('Adicionar Pagamento'));
      await tester.pumpAndSettle();

      expect(controller.lastCreatedPayment, isNotNull);
    },
  );

  testWidgets(
    'CustomerDevicePayments disables add button for DESCARTADO and enables for NOVO',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final disposedController = _FakeDeviceCustomerPageController()
        ..deviceCustomer = _sampleDevice(deviceStatus: 'DESCARTADO');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DeviceCustomerPageController>.value(
              value: disposedController,
              child: const CustomerDevicePayments(),
            ),
          ),
        ),
      );

      final disposedButton = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      expect(disposedButton.onPressed, isNull);

      final newController = _FakeDeviceCustomerPageController()
        ..deviceCustomer = _sampleDevice(deviceStatus: 'NOVO');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DeviceCustomerPageController>.value(
              value: newController,
              child: const CustomerDevicePayments(),
            ),
          ),
        ),
      );

      final newButton = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      expect(newButton.onPressed, isNotNull);
    },
  );

  test('DeviceCustomer.toJson defaults null budgetFee to 0.0', () {
    final device = _sampleDevice(budgetFee: null);
    final json = device.toJson();
    expect(json['budgetFee'], 0.0);
  });
}
