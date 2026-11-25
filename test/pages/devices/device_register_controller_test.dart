import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/models/colors/color_model.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/controller/device_register_controller.dart';
import 'package:flutter_workshop_front/repositories/catalog/catalog_repository.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/repositories/device/device_repository.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import '../../helpers/result_guard.dart';

class _FakeDeviceRepository extends Fake implements DeviceRepository {}

class _StubCatalogRepository extends Fake implements CatalogRepository {
  @override
  Future<Result<List<ColorModel>>> getColors({
    bool forceRefresh = false,
  }) async => const Ok([]);

  @override
  Future<Result<List<Technician>>> getTechnicians({
    bool forceRefresh = false,
  }) async => const Ok([]);
}

class _StubCustomerRepository extends Fake implements CustomerRepository {
  final Future<CustomerModel> Function(int customerId) onGet;
  final List<int> requestedIds = [];

  _StubCustomerRepository(this.onGet);

  @override
  Future<Result<CustomerModel>> getCustomer(int customerId) {
    requestedIds.add(customerId);
    return guardResult(() => onGet(customerId));
  }
}

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
      catalogRepository: _StubCatalogRepository(),
      deviceRepository: _FakeDeviceRepository(),
      customerRepository: repository,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceRegisterController.init', () {
    test(
      'carrega customerName pelo repositório quando só customerId chega',
      () async {
        final repository = _StubCustomerRepository(
          (id) async => _customer(id, 'Maria'),
        );
        final controller = _controller(repository);

        await controller.init(10, null);

        expect(repository.requestedIds, [10]);
        expect(controller.customerId, 10);
        expect(controller.customerName, 'Maria');
        expect(controller.isCustomerSelected, isTrue);
        expect(controller.isLoading, isFalse);
      },
    );

    test('não consulta o repositório quando o nome veio via extra', () async {
      final repository = _StubCustomerRepository(
        (id) async => _customer(id, 'Outro'),
      );
      final controller = _controller(repository);

      await controller.init(10, 'Maria');

      expect(repository.requestedIds, isEmpty);
      expect(controller.customerName, 'Maria');
    });

    test('não consulta o repositório sem cliente pré-selecionado', () async {
      final repository = _StubCustomerRepository(
        (id) async => _customer(id, 'Outro'),
      );
      final controller = _controller(repository);

      await controller.init(null, null);

      expect(repository.requestedIds, isEmpty);
      expect(controller.customerId, isNull);
      expect(controller.isCustomerSelected, isFalse);
    });

    test(
      'falha ao carregar o cliente volta para a busca manual sem travar',
      () async {
        final repository = _StubCustomerRepository(
          (id) async => throw Exception('offline'),
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
