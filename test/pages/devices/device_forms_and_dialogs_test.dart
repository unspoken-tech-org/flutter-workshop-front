import '../../support/offline_services.dart';

import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/core/money/money.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/controllers/customer_detail_controller.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/widgets/customer_detail_form.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/customer_device_payments.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/device_status_chip.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/dialogs/add_new_payment_dialog.dart';
import 'package:flutter_workshop_front/pages/setup/setup_controller.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_workshop_front/core/result/result.dart';

import '../../support/result_guard.dart';

class _FakeAuthService extends Fake implements AuthService {
  String? lastApiKey;

  @override
  Future<String?> get apiKey async => null;

  @override
  Future<void> authenticate(String apiKey) async {
    lastApiKey = apiKey;
  }
}

class _StubCustomerRepository implements CustomerRepository {
  @override
  Future<Result<CustomerModel>> createCustomer(InputCustomer customer) =>
      guardResult(() => throw UnimplementedError());

  @override
  Future<Result<CustomerModel>> getCustomer(int customerId) =>
      guardResult(() => throw UnimplementedError());

  @override
  Future<Result<Page<MinifiedCustomerModel>>> searchCustomers(
    CustomerSearchFilter? filter,
  ) => guardResult(() => throw UnimplementedError());

  @override
  Future<Result<CustomerModel>> updateCustomer(
    int customerId,
    InputCustomer customer,
  ) => guardResult(() => throw UnimplementedError());
}

DeviceCustomer _sampleDevice({
  DateTime? departureDate,
  double serviceValue = 100.0,
}) => DeviceCustomer.fromJson({
  'deviceId': 1,
  'customerId': 1,
  'customerName': 'Cliente Teste',
  'deviceStatus': 'EM_ANDAMENTO',
  'brandName': 'Marca',
  'modelName': 'Modelo',
  'typeName': 'Tipo',
  'problem': 'Problema',
  'observation': '',
  'serviceValue': serviceValue,
  'hasUrgency': false,
  'revision': false,
  'deviceColors': const ['Preto'],
  'entryDate': '2026-01-01T00:00:00',
  'departureDate': departureDate?.toIso8601String(),
  'customerContacts': const <dynamic>[],
  'customerPhones': const <dynamic>[],
  'otherDevices': const <dynamic>[],
  'payments': const <dynamic>[],
});

void main() {
  test('DeviceCustomer.copyWith(departureDate: null) clears departureDate', () {
    final device = _sampleDevice(departureDate: DateTime(2026, 2, 1));
    expect(device.departureDate, isNotNull);

    final kept = device.copyWith(problem: 'Novo');
    expect(kept.departureDate, DateTime(2026, 2, 1));

    final cleared = device.copyWith(departureDate: null);
    expect(cleared.departureDate, isNull);
  });

  test('RequisitionException.fromJson handles null message and code', () {
    final ex = RequisitionException.fromJson(<String, dynamic>{
      'message': null,
      'code': null,
    });
    expect(ex.message, isNotEmpty);
    expect(ex.code, isEmpty);
  });

  test(
    'SetupController.authenticate trims leading/trailing whitespace',
    () async {
      final authService = _FakeAuthService();
      final controller = SetupController(authService: authService);
      final ok = await controller.authenticate('  my-secret-key\n');
      expect(ok, isTrue);
      expect(authService.lastApiKey, 'my-secret-key');
    },
  );

  testWidgets('DeviceStatusChip opens status menu on tap without hover', (
    tester,
  ) async {
    StatusEnum? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: DeviceStatusChip(
              status: StatusEnum.inProgress,
              onSelect: (s) => selected = s,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text(StatusEnum.inProgress.displayName));
    await tester.pumpAndSettle();

    expect(find.text(StatusEnum.ready.displayName), findsOneWidget);
    await tester.tap(find.text(StatusEnum.ready.displayName));
    await tester.pumpAndSettle();

    expect(selected, StatusEnum.ready);
  });

  testWidgets('CustomerDetailForm handles legacy MALE/FEMALE gender values', (
    tester,
  ) async {
    final controller = CustomerDetailController(_StubCustomerRepository());
    final customer = CustomerModel(
      customerId: 1,
      name: 'João',
      createdAt: DateTime(2026, 1, 1),
      cpf: '12345678909',
      gender: 'MALE',
      phones: [PhoneModel(idCellphone: 1, number: '11999999999', main: true)],
      customerDevices: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: controller,
            child: SingleChildScrollView(
              child: CustomerDetailForm(
                customer: customer,
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Masculino'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'CustomerDevicePayments shows persisted serviceValue while editing draft',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = testDeviceCustomerPageController()
        ..deviceCustomer = _sampleDevice(serviceValue: 100.0);
      controller.onEditingStarted();
      controller.updateNewDeviceCustomer(
        controller.deviceCustomer!.copyWith(
          serviceValue: const Money.fromCents(25000),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: controller,
              child: const CustomerDevicePayments(),
            ),
          ),
        ),
      );

      expect(find.text('R\$\u00A0100,00'), findsWidgets);
      expect(find.text('R\$\u00A0250,00'), findsNothing);
    },
  );

  testWidgets('AddNewPaymentDialog requires Recebido por', (tester) async {
    tester.view.physicalSize = const Size(1600, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = testDeviceCustomerPageController()
      ..technicians = [Technician(id: 1, name: 'Carlos', number: '11999999999')]
      ..deviceCustomer = _sampleDevice(serviceValue: 100.0);

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

    await tester.tap(find.text('Adicionar Pagamento'));
    await tester.pumpAndSettle();

    expect(find.text('Selecione quem recebeu o pagamento'), findsOneWidget);
  });
}
