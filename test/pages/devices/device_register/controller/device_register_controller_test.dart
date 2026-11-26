import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer_device/create_device_customer.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/controller/device_register_controller.dart';

import '../../../../support/fakes/fake_catalog_repository.dart';
import '../../../../support/fakes/fake_customer_repository.dart';
import '../../../../support/fakes/fake_device_repository.dart';
import '../../../../support/ui_message_recorder.dart';

DeviceRegisterController _controller(FakeDeviceRepository devices) {
  final controller = DeviceRegisterController(
    catalogRepository: FakeCatalogRepository(),
    deviceRepository: devices,
    customerRepository: FakeCustomerRepository(),
  );
  controller
    ..setSelectedType(Type(idType: 1, type: 'Notebook'))
    ..setSelectedBrand(Brand(idBrand: 1, brand: 'Dell'))
    ..setSelectedModel(Model(idModel: 1, model: 'Inspiron'));
  return controller;
}

void main() {
  group('DeviceRegisterController.createDevice', () {
    test('sucesso devolve o id e publica a mensagem', () async {
      final controller = _controller(
        FakeDeviceRepository(
          createDeviceCustomerResult: Ok(
            CreateDeviceCustomerResponse(deviceId: 42),
          ),
        ),
      );
      final messages = recordMessages(controller);

      expect(await controller.createDevice(), 42);

      expect(controller.isCreatingDevice, isFalse);
      expect(messages, [isUiSuccess('Dispositivo criado com sucesso')]);
    });

    test('falha devolve null e publica o texto padrão', () async {
      final controller = _controller(
        FakeDeviceRepository(
          createDeviceCustomerResult: const Err(NetworkFailure()),
        ),
      );
      final messages = recordMessages(controller);

      expect(await controller.createDevice(), isNull);

      expect(controller.create.error, isA<NetworkFailure>());
      expect(messages, [isUiError('Erro ao criar dispositivo')]);
    });

    test('segunda chamada durante a criação é ignorada', () async {
      final blocker = Completer<Result<CreateDeviceCustomerResponse>>();
      var calls = 0;
      final controller = _controller(
        FakeDeviceRepository(
          onCreateDeviceCustomer: (_) {
            calls++;
            return blocker.future;
          },
        ),
      );

      final first = controller.createDevice();
      expect(controller.isCreatingDevice, isTrue);
      expect(await controller.createDevice(), isNull);
      expect(calls, 1);

      blocker.complete(Ok(CreateDeviceCustomerResponse(deviceId: 1)));
      expect(await first, 1);
    });
  });

  group('DeviceRegisterController.init', () {
    test(
      'falha ao carregar cores e técnicos publica um erro de cada',
      () async {
        final controller = DeviceRegisterController(
          catalogRepository: FakeCatalogRepository(
            colorsResult: const Err(NetworkFailure()),
            techniciansResult: const Err(NetworkFailure()),
          ),
          deviceRepository: FakeDeviceRepository(),
          customerRepository: FakeCustomerRepository(),
        );
        final messages = recordMessages(controller);

        await controller.init(null, null);

        expect(messages, [
          isUiError('Erro ao buscar as cores'),
          isUiError('Erro ao buscar os técnicos'),
        ]);
        expect(controller.isLoading, isFalse);
      },
    );
  });
}
