import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/money/money.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_device_payment.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/customer_device_page_shimmer.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/customer_device_payment_item.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/payment_totals_widget.dart';
import 'package:flutter_workshop_front/widgets/shared/empty_list_widget.dart';

DeviceCustomer _deviceCustomer({
  Money? serviceValue,
  List<CustomerDevicePayment> payments = const [],
}) => DeviceCustomer(
  deviceId: 1,
  customerId: 1,
  customerName: 'Maria Silva',
  deviceStatus: StatusEnum.ready,
  brandName: 'Dell',
  modelName: 'Inspiron',
  typeName: 'Notebook',
  problem: 'Não liga',
  observation: '',
  hasUrgency: false,
  revision: false,
  deviceColors: const ['Preto'],
  entryDate: DateTime(2026, 1, 10),
  lastUpdate: DateTime(2026, 1, 12),
  serviceValue: serviceValue,
  payments: payments,
);

CustomerDevicePayment _payment({
  int id = 1,
  required Money value,
  PaymentType type = PaymentType.credito,
  PaymentCategory category = PaymentCategory.service,
  String? receivedBy = 'Carlos Eduardo Oliveira',
}) => CustomerDevicePayment(
  paymentId: id,
  paymentDate: DateTime(2026, 1, 15, 14, 30),
  paymentType: type,
  paymentValue: value,
  category: category,
  receivedBy: receivedBy,
);

void main() {
  group('PaymentTotalsWidget narrow width', () {
    testWidgets(
      'shows check icon and total paid value when fully paid at width <= 240px',
      (tester) async {
        const paidAmount = Money.fromCents(25000);
        final payment = _payment(value: paidAmount);
        final customer = _deviceCustomer(
          serviceValue: paidAmount,
          payments: [payment],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 240,
                child: PaymentTotalsWidget(
                  deviceCustomer: customer,
                  devicePayments: [payment],
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.text(paidAmount.toBrCurrency), findsNWidgets(2));
        expect(find.text('Valor total pago'), findsNothing);
      },
    );

    testWidgets(
      'shows pending value without overflowing when pending at width <= 240px',
      (tester) async {
        const serviceAmount = Money.fromCents(35000);
        const paidAmount = Money.fromCents(10000);
        const remainingAmount = Money.fromCents(25000);
        final payment = _payment(value: paidAmount);
        final customer = _deviceCustomer(
          serviceValue: serviceAmount,
          payments: [payment],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 240,
                child: PaymentTotalsWidget(
                  deviceCustomer: customer,
                  devicePayments: [payment],
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text(remainingAmount.toBrCurrency), findsOneWidget);
        expect(find.text('Valor a ser pago'), findsNothing);
      },
    );

    testWidgets(
      'shows label and check icon when fully paid at wide width (> 250px)',
      (tester) async {
        const paidAmount = Money.fromCents(25000);
        final payment = _payment(value: paidAmount);
        final customer = _deviceCustomer(
          serviceValue: paidAmount,
          payments: [payment],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 340,
                child: PaymentTotalsWidget(
                  deviceCustomer: customer,
                  devicePayments: [payment],
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.text('Valor total pago'), findsOneWidget);
      },
    );
  });

  group('Layout overflow regressions on smaller viewports', () {
    testWidgets(
      'CustomerDevicePaymentItem does not overflow in 1024x700 payment column',
      (tester) async {
        final payment = _payment(
          value: const Money.fromCents(125000),
          type: PaymentType.dinheiro,
          category: PaymentCategory.budgetFee,
          receivedBy: 'Carlos Eduardo Oliveira',
        );

        for (final width in [220.0, 250.0, 300.0, 360.0]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: width,
                  child: CustomerDevicePaymentItem(payment: payment),
                ),
              ),
            ),
          );

          expect(
            tester.takeException(),
            isNull,
            reason: 'Expected no overflow at width $width',
          );
          expect(find.text(payment.paymentValue.toBrCurrency), findsOneWidget);
        }
      },
    );

    testWidgets(
      'EmptyListWidget does not overflow vertically in tight height (filters open at 1280x720)',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 896,
                height: 85,
                child: EmptyListWidget(message: 'Nenhum aparelho encontrado'),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Nenhum aparelho encontrado'), findsOneWidget);
      },
    );

    testWidgets('CustomerDevicePageShimmer does not overflow at 1024x700', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CustomerDevicePageShimmer())),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
