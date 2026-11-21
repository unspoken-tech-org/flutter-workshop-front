import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/money/money.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_device_payment.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/input_payment.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/dialogs/add_new_payment_dialog.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/payment_totals_widget.dart';
import 'package:flutter_workshop_front/services/payment/payment_service.dart';
import 'package:flutter_workshop_front/widgets/customer_device/device_values_widget.dart';
import 'package:provider/provider.dart';

DeviceCustomer _deviceWithPayments({
  double? budgetFee,
  double? serviceValue,
  List<Map<String, dynamic>> payments = const [],
}) => DeviceCustomer.fromJson({
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
  'serviceValue': serviceValue,
  'budgetFee': budgetFee,
  'hasUrgency': false,
  'revision': false,
  'deviceColors': const <String>[],
  'entryDate': '2026-01-01T00:00:00',
  'departureDate': null,
  'lastUpdate': null,
  'customerContacts': const <dynamic>[],
  'customerPhones': const <dynamic>[],
  'otherDevices': const <dynamic>[],
  'payments': payments,
});

class _RecordingPaymentService implements PaymentService {
  InputPayment? lastCreated;

  @override
  Future<void> createPayment(InputPayment payment) async {
    lastCreated = payment;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('IEEE-754 money edge cases across models and widgets', () {
    test(
      'DeviceCustomer.computedBudgetFeeCollected handles 70.10 + 0.10 == 70.20',
      () {
        final paid = _deviceWithPayments(
          budgetFee: 70.20,
          payments: const [
            {
              'paymentId': 1,
              'paymentDate': '2026-01-01T00:00:00',
              'paymentType': 'pix',
              'paymentValue': 70.10,
              'category': 'taxa_orcamento',
            },
            {
              'paymentId': 2,
              'paymentDate': '2026-01-02T00:00:00',
              'paymentType': 'pix',
              'paymentValue': 0.10,
              'category': 'taxa_orcamento',
            },
          ],
        );

        expect(paid.totalPaidFee, const Money.fromCents(7020));
        expect(paid.computedBudgetFeeCollected, isTrue);

        final underpaid = _deviceWithPayments(
          budgetFee: 70.20,
          payments: const [
            {
              'paymentId': 1,
              'paymentDate': '2026-01-01T00:00:00',
              'paymentType': 'pix',
              'paymentValue': 70.19,
              'category': 'taxa_orcamento',
            },
          ],
        );
        expect(underpaid.computedBudgetFeeCollected, isFalse);
      },
    );

    testWidgets(
      'PaymentTotalsWidget shows Valor total pago when 35.10 + 66.67 settles 101.77',
      (tester) async {
        final device = _deviceWithPayments(
          serviceValue: 101.77,
          payments: const [
            {
              'paymentId': 1,
              'paymentDate': '2026-01-01T00:00:00',
              'paymentType': 'pix',
              'paymentValue': 35.10,
              'category': 'servicos',
            },
            {
              'paymentId': 2,
              'paymentDate': '2026-01-02T00:00:00',
              'paymentType': 'pix',
              'paymentValue': 66.67,
              'category': 'servicos',
            },
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                child: PaymentTotalsWidget(
                  deviceCustomer: device,
                  devicePayments: device.payments,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Valor total pago'), findsOneWidget);
        expect(find.text('Valor a ser pago'), findsNothing);
      },
    );

    testWidgets(
      'DeviceValuesWidget accepts budgetFee == 101.77 when payments sum 35.10 + 66.67 and rejects 101.76',
      (tester) async {
        final formKey = GlobalKey<FormState>();
        final controller = DeviceCustomerPageController()
          ..deviceCustomer = _deviceWithPayments(
            budgetFee: 101.77,
            payments: const [
              {
                'paymentId': 1,
                'paymentDate': '2026-01-01T00:00:00',
                'paymentType': 'pix',
                'paymentValue': 35.10,
                'category': 'taxa_orcamento',
              },
              {
                'paymentId': 2,
                'paymentDate': '2026-01-02T00:00:00',
                'paymentType': 'pix',
                'paymentValue': 66.67,
                'category': 'taxa_orcamento',
              },
            ],
          );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider.value(
                value: controller,
                child: Form(
                  key: formKey,
                  child: const DeviceValuesWidget(isEditing: true),
                ),
              ),
            ),
          ),
        );

        expect(formKey.currentState!.validate(), isTrue);

        final budgetField = find.byType(TextFormField).first;
        await tester.enterText(budgetField, '10176');
        await tester.pump();

        expect(formKey.currentState!.validate(), isFalse);
        await tester.pump();
        expect(find.text('Valor mínimo: R\$\u00A0101,77'), findsOneWidget);
      },
    );

    testWidgets(
      'AddNewPaymentDialog accepts exact remaining balance 66.67 of 101.77 after 35.10',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final paymentService = _RecordingPaymentService();
        final controller =
            DeviceCustomerPageController(paymentService: paymentService)
              ..technicians = [
                Technician(id: 1, name: 'Carlos', number: '11999999999'),
              ]
              ..deviceCustomer = _deviceWithPayments(
                budgetFee: 101.77,
                payments: const [
                  {
                    'paymentId': 1,
                    'paymentDate': '2026-01-01T00:00:00',
                    'paymentType': 'pix',
                    'paymentValue': 35.10,
                    'category': 'taxa_orcamento',
                  },
                ],
              );

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

        // Select Category -> Taxa de orçamento
        await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Taxa de orçamento').last);
        await tester.pumpAndSettle();

        // Select PaymentType -> Pix
        await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pix').last);
        await tester.pumpAndSettle();

        // Enter remaining balance 66.67
        final valueField = find.widgetWithText(TextFormField, 'R\$\u00A00,00');
        await tester.enterText(valueField, '6667');
        await tester.pump();

        // Select ReceivedBy -> Carlos
        await tester.tap(find.byType(DropdownButtonFormField<String>).at(2));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Carlos').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Adicionar Pagamento'));
        await tester.pumpAndSettle();

        expect(paymentService.lastCreated, isNotNull);
        expect(paymentService.lastCreated!.value, const Money.fromCents(6667));
        expect(paymentService.lastCreated!.category, PaymentCategory.budgetFee);
      },
    );

    testWidgets(
      'AddNewPaymentDialog rejects invalid currency string without silently treating it as 0',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final paymentService = _RecordingPaymentService();
        final controller = DeviceCustomerPageController(
          paymentService: paymentService,
        )..deviceCustomer = _deviceWithPayments(budgetFee: 100.0);

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

        final valueTextField = find.widgetWithText(TextField, 'R\$\u00A00,00');
        tester.widget<TextField>(valueTextField).controller!.text = 'abc';
        await tester.pump();

        await tester.tap(find.text('Adicionar Pagamento'));
        await tester.pump();

        expect(find.text('Valor inválido'), findsOneWidget);
        expect(paymentService.lastCreated, isNull);
      },
    );
  });
}
