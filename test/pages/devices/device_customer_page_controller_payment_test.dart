import '../../support/offline_services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/money/money.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_device_payment.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/input_payment.dart';
import 'package:flutter_workshop_front/services/payment/payment_service.dart';

class _StubPaymentService implements PaymentService {
  _StubPaymentService(this.result);

  final Result<void> result;

  @override
  Future<Result<void>> createPayment(InputPayment payment) async => result;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DeviceCustomer _device() => DeviceCustomer.fromJson(const {
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
  'serviceValue': null,
  'budgetFee': null,
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

InputPayment _payment() => InputPayment(
  deviceId: 1,
  value: const Money.fromCents(1000),
  paymentType: PaymentType.pix,
  category: PaymentCategory.service,
  paymentDate: DateTime(2026),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceCustomerPageController.createCustomerDevicePayment', () {
    test('Ok adiciona o pagamento e devolve true', () async {
      final controller = testDeviceCustomerPageController(
        paymentService: _StubPaymentService(const Ok(null)),
      )..deviceCustomer = _device();

      final created = await controller.createCustomerDevicePayment(_payment());

      expect(created, isTrue);
      expect(controller.deviceCustomer!.payments, hasLength(1));
      expect(controller.isCreatingPayment, isFalse);
    });

    test('Err devolve false e não altera os pagamentos', () async {
      final controller = testDeviceCustomerPageController(
        paymentService: _StubPaymentService(
          const Err(
            ValidationFailure(
              message: 'Pagamento recusado',
              code: 'payment.invalid',
              statusCode: 400,
            ),
          ),
        ),
      )..deviceCustomer = _device();

      final created = await controller.createCustomerDevicePayment(_payment());

      expect(created, isFalse);
      expect(controller.deviceCustomer!.payments, isEmpty);
      expect(controller.isCreatingPayment, isFalse);
    });

    test('falha de rede também devolve false', () async {
      final controller = testDeviceCustomerPageController(
        paymentService: _StubPaymentService(const Err(NetworkFailure())),
      )..deviceCustomer = _device();

      expect(await controller.createCustomerDevicePayment(_payment()), isFalse);
    });
  });
}
