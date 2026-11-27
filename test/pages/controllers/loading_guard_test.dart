// ignore_for_file: unawaited_futures
import '../../support/offline_services.dart';

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/device_statistics/device_statistics.dart';
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
import '../../support/fixtures/device_customer_fixture.dart';
import '../../support/fixtures/device_statistics_fixture.dart';

// ---------------------------------------------------------------------------
// Stubs
// ---------------------------------------------------------------------------

FakeCustomerRepository _blockingCustomerRepository() => FakeCustomerRepository(
  onCreateCustomer: (_) => Completer<Result<CustomerModel>>().future,
  onGetCustomer: (_) => Completer<Result<CustomerModel>>().future,
  onUpdateCustomer: (_, __) => Completer<Result<CustomerModel>>().future,
);

FakeDeviceRepository _blockingDeviceRepository() => FakeDeviceRepository(
  onQueryDevices: (_, _) => Completer<Result<Page<DeviceDataTable>>>().future,
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
    // O construtor chama reload() fire-and-forget.
    // Uma nova chamada a reload() durante isLoading=true
    // NÃO deve ser descartada (ela incrementa a geração e invalida a anterior).

    test(
      'reload não descarta nova chamada quando isLoading=true e invalida chamada anterior',
      () async {
        final deviceRepo = _blockingDeviceRepository();
        final catalogRepo = FakeCatalogRepository();
        final controller = AllDevicesController(deviceRepo, catalogRepo);

        // Construtor definiu isLoading = true sincronamente
        expect(controller.isLoading, true);
        // queryDevices ainda não foi chamado (está atrás do Future.delayed)
        expect(deviceRepo.recordedDeviceQueries, isEmpty);

        // Nova chamada enquanto a primeira está no Future.delayed(200ms)
        final secondCall = controller.reload();
        expect(controller.isLoading, true);

        // Aguarda o debounce de 200ms: apenas a geração mais nova chega ao repo
        await Future<void>.delayed(const Duration(milliseconds: 250));
        expect(deviceRepo.recordedDeviceQueries, hasLength(1));

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
    test('segunda chamada concorrente é ignorada', () async {
      final blocker = Completer<Result<DeviceStatistics>>();
      var calls = 0;
      final controller = HomeController(
        FakeDeviceRepository(
          onGetDeviceStatistics: () {
            calls++;
            return blocker.future;
          },
        ),
      );

      final first = controller.getDeviceStatistics();
      expect(controller.isLoading, true);
      await controller.getDeviceStatistics();
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(calls, 1);
      blocker.complete(Ok(makeDeviceStatistics()));
      await first;
      expect(controller.isLoading, false);
    });
  });

  // -------------------------------------------------------------------------
  group('DeviceCustomerPageController — guards de atualização', () {
    test(
      'updateDeviceCustomer ignora segunda chamada enquanto salva',
      () async {
        final blocker = Completer<Result<DeviceCustomer>>();
        var calls = 0;
        final controller = testDeviceCustomerPageController(
          deviceRepository: FakeDeviceRepository(
            onUpdateDeviceCustomer: (_) {
              calls++;
              return blocker.future;
            },
          ),
        )..deviceCustomer = makeDeviceCustomer();

        final first = controller.updateDeviceCustomer();
        expect(controller.isSaving, true);
        expect(await controller.updateDeviceCustomer(), false);
        expect(calls, 1);

        blocker.complete(Ok(makeDeviceCustomer()));
        expect(await first, true);
        expect(controller.isSaving, false);
      },
    );

    test('ações rápidas ignoram chamadas enquanto uma delas roda', () async {
      final blocker = Completer<Result<DeviceCustomer>>();
      var urgencyCalls = 0;
      var revisionCalls = 0;
      var statusCalls = 0;
      final controller = testDeviceCustomerPageController(
        deviceRepository: FakeDeviceRepository(
          onUpdateDeviceHasUrgency: (_, __) {
            urgencyCalls++;
            return blocker.future;
          },
          onUpdateDeviceRevision: (_, __) async {
            revisionCalls++;
            return Ok(makeDeviceCustomer());
          },
          onUpdateDeviceStatus: (_, __) async {
            statusCalls++;
            return Ok(makeDeviceCustomer());
          },
        ),
      )..deviceCustomer = makeDeviceCustomer();

      final first = controller.updateDeviceHasUrgency(true);
      expect(controller.isUpdating, true);
      await controller.updateDeviceHasUrgency(true);
      await controller.updateDeviceRevision(true);
      await controller.updateDeviceStatus(StatusEnum.newDevice);

      expect([urgencyCalls, revisionCalls, statusCalls], [1, 0, 0]);
      blocker.complete(Ok(makeDeviceCustomer()));
      await first;
      expect(controller.isUpdating, false);
    });

    test(
      'createCustomerContact ignora segunda chamada enquanto cria',
      () async {
        final blocker = Completer<Result<void>>();
        var calls = 0;
        final controller = testDeviceCustomerPageController(
          deviceRepository: FakeDeviceRepository(
            onCreateCustomerContact: (_) {
              calls++;
              return blocker.future;
            },
            onGetCustomerDeviceById: (_) async => Ok(makeDeviceCustomer()),
          ),
        )..deviceCustomer = makeDeviceCustomer();

        final first = controller.createCustomerContact(
          InputCustomerContact.empty(1),
        );
        expect(controller.isCreatingContact, true);
        expect(
          await controller.createCustomerContact(InputCustomerContact.empty(1)),
          false,
        );
        expect(calls, 1);

        blocker.complete(const Ok<void>(null));
        expect(await first, true);
        expect(controller.isCreatingContact, false);
      },
    );
  });
}
