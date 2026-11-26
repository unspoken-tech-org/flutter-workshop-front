import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/controller/device_register_controller.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';

import '../../support/fakes/fake_catalog_repository.dart';
import '../../support/fakes/fake_customer_repository.dart';
import '../../support/fakes/fake_device_repository.dart';

CustomerModel _customer(int id, String name) => CustomerModel(
  customerId: id,
  name: name,
  createdAt: DateTime(2026),
  cpf: '00000000000',
  gender: 'F',
  phones: const [],
  customerDevices: const [],
);

DeviceRegisterController _controller(CustomerRepository repository) =>
    DeviceRegisterController(
      catalogRepository: FakeCatalogRepository(),
      deviceRepository: FakeDeviceRepository(),
      customerRepository: repository,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceRegisterController.init', () {
    test(
      'carrega customerName pelo repositório quando só customerId chega',
      () async {
        final repository = FakeCustomerRepository(
          onGetCustomer: (id) async => Ok(_customer(id, 'Maria')),
        );
        final controller = _controller(repository);

        await controller.init(10, null);

        expect(repository.requestedCustomerIds, [10]);
        expect(controller.customerId, 10);
        expect(controller.customerName, 'Maria');
        expect(controller.isCustomerSelected, isTrue);
        expect(controller.isLoading, isFalse);
      },
    );

    test('não consulta o repositório quando o nome veio via extra', () async {
      final repository = FakeCustomerRepository(
        onGetCustomer: (id) async => Ok(_customer(id, 'Outro')),
      );
      final controller = _controller(repository);

      await controller.init(10, 'Maria');

      expect(repository.requestedCustomerIds, isEmpty);
      expect(controller.customerName, 'Maria');
    });

    test('não consulta o repositório sem cliente pré-selecionado', () async {
      final repository = FakeCustomerRepository(
        onGetCustomer: (id) async => Ok(_customer(id, 'Outro')),
      );
      final controller = _controller(repository);

      await controller.init(null, null);

      expect(repository.requestedCustomerIds, isEmpty);
      expect(controller.customerId, isNull);
      expect(controller.isCustomerSelected, isFalse);
    });

    test(
      'falha ao carregar o cliente volta para a busca manual sem travar',
      () async {
        final repository = FakeCustomerRepository(
          onGetCustomer: (_) async => const Err(NetworkFailure()),
        );
        final controller = _controller(repository);

        await controller.init(10, null);

        expect(controller.customerId, isNull);
        expect(controller.customerName, isNull);
        expect(controller.isCustomerSelected, isFalse);
        expect(controller.isLoading, isFalse);
      },
    );
  });
}
