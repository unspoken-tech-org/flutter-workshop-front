import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/services/device_data/device_customer_service.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import '../../helpers/result_guard.dart';

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

class _FakeDeviceCustomerService implements DeviceCustomerService {
  Future<DeviceCustomer> Function(DeviceCustomer) onUpdate;
  Future<DeviceCustomer> Function(bool) onUrgency;

  _FakeDeviceCustomerService({required this.onUpdate, required this.onUrgency});

  @override
  Future<Result<DeviceCustomer>> updateDeviceCustomer(
    DeviceCustomer deviceCustomer,
  ) => guardResult(() => onUpdate(deviceCustomer));

  @override
  Future<Result<DeviceCustomer>> updateDeviceHasUrgency(
    int deviceId,
    bool hasUrgency,
  ) => guardResult(() => onUrgency(hasUrgency));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceCustomerPageController.updateDeviceCustomer', () {
    test(
      'retorna true e aplica a resposta quando o servidor confirma',
      () async {
        final saved = _device(problem: 'Tela quebrada');
        final controller = DeviceCustomerPageController(
          deviceCustomerService: _FakeDeviceCustomerService(
            onUpdate: (_) async => saved,
            onUrgency: (_) async => throw UnimplementedError(),
          ),
        )..deviceCustomer = _device();

        expect(await controller.updateDeviceCustomer(), isTrue);
        expect(controller.deviceCustomer, same(saved));
        expect(controller.isSaving, isFalse);
      },
    );

    test('retorna false quando o servidor rejeita', () async {
      final controller = DeviceCustomerPageController(
        deviceCustomerService: _FakeDeviceCustomerService(
          onUpdate: (_) async => throw RequisitionException('Inválido', '400'),
          onUrgency: (_) async => throw UnimplementedError(),
        ),
      )..deviceCustomer = _device();

      expect(await controller.updateDeviceCustomer(), isFalse);
      expect(controller.isSaving, isFalse);
    });

    test('save não é descartado por uma ação rápida em andamento', () async {
      final urgency = Completer<DeviceCustomer>();
      var saveCalls = 0;
      final controller = DeviceCustomerPageController(
        deviceCustomerService: _FakeDeviceCustomerService(
          onUpdate: (d) async {
            saveCalls++;
            return d;
          },
          onUrgency: (_) => urgency.future,
        ),
      )..deviceCustomer = _device();

      final urgencyFuture = controller.updateDeviceHasUrgency(true);
      expect(controller.isUpdating, isTrue);

      expect(await controller.updateDeviceCustomer(), isTrue);
      expect(saveCalls, 1);

      urgency.complete(_device(hasUrgency: true));
      await urgencyFuture;
    });

    test('cancelar após ação rápida mantém o que o servidor gravou', () async {
      final controller = DeviceCustomerPageController(
        deviceCustomerService: _FakeDeviceCustomerService(
          onUpdate: (d) async => d,
          onUrgency: (value) async => _device(hasUrgency: value),
        ),
      )..deviceCustomer = _device();

      controller.onEditingStarted();
      await controller.updateDeviceHasUrgency(true);
      controller.onEditingCancelled();

      expect(controller.deviceCustomer?.hasUrgency, isTrue);
    });
  });
}
