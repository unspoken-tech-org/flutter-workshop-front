import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';

import '../../support/fakes/fake_device_repository.dart';
import '../../support/offline_services.dart';

DeviceCustomer _device({
  String problem = 'Não liga',
  bool hasUrgency = false,
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
  'problem': problem,
  'observation': '',
  'budget': null,
  'serviceValue': null,
  'budgetFee': null,
  'hasUrgency': hasUrgency,
  'revision': false,
  'deviceColors': const <String>[],
  'entryDate': '2026-01-01T00:00:00',
  'departureDate': null,
  'lastUpdate': null,
  'customerContacts': const <dynamic>[],
  'customerPhones': const <dynamic>[],
  'otherDevices': const <dynamic>[],
  'payments': const <dynamic>[],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceCustomerPageController.updateDeviceCustomer', () {
    test(
      'retorna true e aplica a resposta quando o servidor confirma',
      () async {
        final saved = _device(problem: 'Tela quebrada');
        final controller = testDeviceCustomerPageController(
          deviceRepository: FakeDeviceRepository(
            onUpdateDeviceCustomer: (_) async => Ok(saved),
          ),
        )..deviceCustomer = _device();

        expect(await controller.updateDeviceCustomer(), isTrue);
        expect(controller.deviceCustomer, same(saved));
        expect(controller.isSaving, isFalse);
      },
    );

    test('retorna false quando o servidor rejeita', () async {
      final controller = testDeviceCustomerPageController(
        deviceRepository: FakeDeviceRepository(
          onUpdateDeviceCustomer: (_) async => const Err(
            ValidationFailure(
              message: 'Inválido',
              code: '400',
              statusCode: 400,
            ),
          ),
        ),
      )..deviceCustomer = _device();

      expect(await controller.updateDeviceCustomer(), isFalse);
      expect(controller.isSaving, isFalse);
    });

    test('save não é descartado por uma ação rápida em andamento', () async {
      final urgency = Completer<Result<DeviceCustomer>>();
      var saveCalls = 0;
      final controller = testDeviceCustomerPageController(
        deviceRepository: FakeDeviceRepository(
          onUpdateDeviceCustomer: (d) async {
            saveCalls++;
            return Ok(d);
          },
          onUpdateDeviceHasUrgency: (_, __) => urgency.future,
        ),
      )..deviceCustomer = _device();

      final urgencyFuture = controller.updateDeviceHasUrgency(true);
      expect(controller.isUpdating, isTrue);

      expect(await controller.updateDeviceCustomer(), isTrue);
      expect(saveCalls, 1);

      urgency.complete(Ok(_device(hasUrgency: true)));
      await urgencyFuture;
    });

    test('cancelar após ação rápida mantém o que o servidor gravou', () async {
      final controller = testDeviceCustomerPageController(
        deviceRepository: FakeDeviceRepository(
          onUpdateDeviceCustomer: (d) async => Ok(d),
          onUpdateDeviceHasUrgency: (_, value) async =>
              Ok(_device(hasUrgency: value)),
        ),
      )..deviceCustomer = _device();

      controller.onEditingStarted();
      await controller.updateDeviceHasUrgency(true);
      controller.onEditingCancelled();

      expect(controller.deviceCustomer?.hasUrgency, isTrue);
    });
  });
}
