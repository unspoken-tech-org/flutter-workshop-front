// ignore_for_file: unawaited_futures
import '../../support/offline_services.dart';

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/controllers/customer_detail_controller.dart';
import 'package:flutter_workshop_front/pages/customers/customer_register/controllers/customer_register_controller.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/controllers/all_devices_controller.dart';
import 'package:flutter_workshop_front/pages/home/controllers/home_controller.dart';
import 'package:flutter_workshop_front/pages/setup/setup_controller.dart';
import 'package:flutter_workshop_front/core/result/result.dart';

import '../../support/fakes/fake_auth_service.dart';
import '../../support/fakes/fake_catalog_repository.dart';
import '../../support/fakes/fake_customer_repository.dart';
import '../../support/fakes/fake_device_repository.dart';

// ---------------------------------------------------------------------------
// Stubs
// ---------------------------------------------------------------------------

FakeCustomerRepository _blockingCustomerRepository() => FakeCustomerRepository(
  onCreateCustomer: (_) => Completer<Result<CustomerModel>>().future,
  onGetCustomer: (_) => Completer<Result<CustomerModel>>().future,
  onUpdateCustomer: (_, __) => Completer<Result<CustomerModel>>().future,
);

FakeDeviceRepository _blockingDeviceRepository() => FakeDeviceRepository(
  onGetAllDevicesFiltering: (_) =>
      Completer<Result<Page<DeviceDataTable>>>().future,
  onSearchDevices: (_) => Completer<Result<Page<DeviceDataTable>>>().future,
);

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  group('SetupController — guard de autenticação', () {
    test(
      'authenticate retorna false imediatamente quando isLoading=true',
      () async {
        final controller = SetupController(authService: FakeAuthService());
        controller.isLoading = true;

        final result = await controller.authenticate('api-key');

        expect(result, false);
        // flag não foi resetada (método retornou antes do finally)
        expect(controller.isLoading, true);
      },
    );
  });

  // -------------------------------------------------------------------------
  group('CustomerRegisterController — guard de criação', () {
    test(
      'createCustomer retorna null imediatamente quando isCreatingCustomer=true',
      () async {
        final repo = _blockingCustomerRepository();
        final controller = CustomerRegisterController(repo);
        controller.isCreatingCustomer = true;

        final result = await controller.createCustomer(InputCustomer.empty());

        expect(result, isNull);
        expect(repo.createCalls, 0); // serviço não foi chamado
        expect(controller.isCreatingCustomer, true);
      },
    );

    test('segunda chamada concorrente é ignorada pelo guard', () async {
      final repo = _blockingCustomerRepository();
      final controller = CustomerRegisterController(repo);

      // Primeira chamada: bloqueia no repositório
      controller.createCustomer(InputCustomer.empty());
      expect(controller.isCreatingCustomer, true);
      expect(repo.createCalls, 1);

      // Segunda chamada enquanto a primeira ainda está em progresso
      final result = await controller.createCustomer(InputCustomer.empty());

      expect(result, isNull);
      expect(repo.createCalls, 1); // sem nova chamada ao serviço
    });
  });

  // -------------------------------------------------------------------------
  group('CustomerDetailController — guard de carregamento', () {
    test(
      'fetchCustomer retorna sem chamar o repo quando isLoading=true',
      () async {
        final repo = _blockingCustomerRepository();
        final controller = CustomerDetailController(repo);
        controller.isLoading = true;

        await controller.fetchCustomer(1);

        expect(repo.getCalls, 0);
        expect(controller.isLoading, true);
      },
    );

    test('segunda chamada concorrente a fetchCustomer é ignorada', () async {
      final repo = _blockingCustomerRepository();
      final controller = CustomerDetailController(repo);

      // Primeira chamada: bloqueia no repositório
      controller.fetchCustomer(1);
      expect(controller.isLoading, true);
      expect(repo.getCalls, 1);

      // Segunda chamada enquanto a primeira está em progresso
      await controller.fetchCustomer(1);

      expect(repo.getCalls, 1);
    });

    test(
      'updateCustomer retorna false sem chamar o repo quando isLoading=true',
      () async {
        final repo = _blockingCustomerRepository();
        final controller = CustomerDetailController(repo);
        controller.isLoading = true;

        final result = await controller.updateCustomer(1);

        expect(result, false);
        expect(repo.updateCalls, 0);
        expect(controller.isLoading, true);
      },
    );

    test('segunda chamada concorrente a updateCustomer é ignorada', () async {
      final repo = _blockingCustomerRepository();
      final controller = CustomerDetailController(repo);

      // Primeira chamada: bloqueia no repositório
      controller.updateCustomer(1);
      expect(controller.isLoading, true);
      expect(repo.updateCalls, 1);

      // Segunda chamada enquanto a primeira está em progresso
      final result = await controller.updateCustomer(1);

      expect(result, false);
      expect(repo.updateCalls, 1);
    });
  });

  // -------------------------------------------------------------------------
  group('AllDevicesController — geração de listagem e guard de filtros', () {
    // O construtor chama fetchAllDevicesFiltering() fire-and-forget.
    // Uma nova chamada a fetchAllDevicesFiltering() durante isLoading=true
    // NÃO deve ser descartada (ela incrementa a geração e invalida a anterior).

    test(
      'fetchAllDevicesFiltering não descarta nova chamada quando isLoading=true e invalida chamada anterior',
      () async {
        final deviceRepo = _blockingDeviceRepository();
        final catalogRepo = FakeCatalogRepository();
        final controller = AllDevicesController(deviceRepo, catalogRepo);

        // Construtor definiu isLoading = true sincronamente
        expect(controller.isLoading, true);
        // getAllDevicesFiltering ainda não foi chamado (está atrás do Future.delayed)
        expect(deviceRepo.recordedAllDevicesFilters, isEmpty);

        // Nova chamada enquanto a primeira está no Future.delayed(200ms)
        final secondCall = controller.fetchAllDevicesFiltering();
        expect(controller.isLoading, true);

        // Aguarda o debounce de 200ms: apenas a geração mais nova chega ao repo
        await Future<void>.delayed(const Duration(milliseconds: 250));
        expect(deviceRepo.recordedAllDevicesFilters, hasLength(1));

        // Não aguardamos secondCall porque _blockingDeviceRepository nunca completa
        unawaited(secondCall);
      },
    );

    test(
      'fetchFilterOptions não executa nova chamada quando isFiltersLoading=true',
      () async {
        final deviceRepo = _blockingDeviceRepository();
        final catalogRepo = FakeCatalogRepository();
        final controller = AllDevicesController(deviceRepo, catalogRepo);

        // Construtor definiu isFiltersLoading = true sincronamente
        expect(controller.isFiltersLoading, true);
        // getAllDeviceTypes e getAllDeviceBrands foram chamados pelo construtor
        final typesBefore = catalogRepo.getAllDeviceTypesCalls;
        final brandsBefore = catalogRepo.getAllDeviceBrandsCalls;

        await controller.fetchFilterOptions(); // guard dispara

        expect(
          catalogRepo.getAllDeviceTypesCalls,
          typesBefore,
        ); // sem nova chamada
        expect(catalogRepo.getAllDeviceBrandsCalls, brandsBefore);
      },
    );
  });

  // -------------------------------------------------------------------------
  group('HomeController — guard de estatísticas', () {
    test(
      'getDeviceStatistics retorna sem side effects quando isLoading=true',
      () async {
        final controller = HomeController(offlineDeviceRepository());
        controller.isLoading = true;
        int notifyCount = 0;
        controller.addListener(() => notifyCount++);

        await controller.getDeviceStatistics();

        expect(controller.isLoading, true);
        expect(notifyCount, 0); // nenhum listener notificado
      },
    );
  });

  // -------------------------------------------------------------------------
  group('DeviceCustomerPageController — guards de atualização', () {
    // Neste controller os serviços são instanciados internamente (sem DI).
    // Os testes verificam que o guard dispara antes de qualquer acesso
    // a serviços ou campos late (deviceCustomer, technicians).

    test(
      'updateDeviceCustomer retorna sem side effects quando isSaving=true',
      () async {
        final controller = testDeviceCustomerPageController();
        controller.isSaving = true;
        int notifyCount = 0;
        controller.addListener(() => notifyCount++);

        final saved = await controller.updateDeviceCustomer();

        expect(saved, false);
        expect(controller.isSaving, true);
        expect(notifyCount, 0);
      },
    );

    test(
      'updateDeviceHasUrgency retorna sem side effects quando isUpdating=true',
      () async {
        final controller = testDeviceCustomerPageController();
        controller.isUpdating = true;
        int notifyCount = 0;
        controller.addListener(() => notifyCount++);

        await controller.updateDeviceHasUrgency(true);

        expect(controller.isUpdating, true);
        expect(notifyCount, 0);
      },
    );

    test(
      'updateDeviceRevision retorna sem side effects quando isUpdating=true',
      () async {
        final controller = testDeviceCustomerPageController();
        controller.isUpdating = true;
        int notifyCount = 0;
        controller.addListener(() => notifyCount++);

        await controller.updateDeviceRevision(true);

        expect(controller.isUpdating, true);
        expect(notifyCount, 0);
      },
    );

    test(
      'updateDeviceStatus retorna sem side effects quando isUpdating=true',
      () async {
        final controller = testDeviceCustomerPageController();
        controller.isUpdating = true;
        int notifyCount = 0;
        controller.addListener(() => notifyCount++);

        await controller.updateDeviceStatus(StatusEnum.newDevice);

        expect(controller.isUpdating, true);
        expect(notifyCount, 0);
      },
    );

    test(
      'createCustomerContact retorna sem side effects quando isCreatingContact=true',
      () async {
        final controller = testDeviceCustomerPageController();
        controller.isCreatingContact = true;
        int notifyCount = 0;
        controller.addListener(() => notifyCount++);

        await controller.createCustomerContact(InputCustomerContact.empty(1));

        expect(controller.isCreatingContact, true);
        expect(notifyCount, 0);
      },
    );
  });
}
