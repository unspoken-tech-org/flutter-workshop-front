// ignore_for_file: unawaited_futures
import '../../support/memory_security_storage.dart';
import '../../support/offline_services.dart';
import 'package:flutter_workshop_front/services/device_statistics/device_statistics_service.dart';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/models/device/device_search_filter.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/controllers/customer_detail_controller.dart';
import 'package:flutter_workshop_front/pages/customers/customer_register/controllers/customer_register_controller.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/controllers/all_devices_controller.dart';
import 'package:flutter_workshop_front/pages/home/controllers/home_controller.dart';
import 'package:flutter_workshop_front/pages/setup/setup_controller.dart';
import 'package:flutter_workshop_front/repositories/all_devices/all_devices_repository.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import '../../helpers/result_guard.dart';

// ---------------------------------------------------------------------------
// Stubs
// ---------------------------------------------------------------------------

AuthService _stubAuthService() => AuthService(
  dio: Dio(),
  storage: MemorySecurityStorage(),
  authNotifier: AuthNotifier(),
);

/// Repositório de cliente que bloqueia cada operação em um Completer individual,
/// permitindo que o teste controle quando (e se) a Future completa.
class _BlockingCustomerRepository implements CustomerRepository {
  int createCalls = 0;
  int getCalls = 0;
  int updateCalls = 0;

  final _createCompleter = Completer<CustomerModel>();
  final _getCompleter = Completer<CustomerModel>();
  final _updateCompleter = Completer<CustomerModel>();

  @override
  Future<Result<CustomerModel>> createCustomer(InputCustomer customer) =>
      guardResult(() {
        createCalls++;
        return _createCompleter.future;
      });

  @override
  Future<Result<CustomerModel>> getCustomer(int customerId) => guardResult(() {
    getCalls++;
    return _getCompleter.future;
  });

  @override
  Future<Result<CustomerModel>> updateCustomer(
    int customerId,
    InputCustomer customer,
  ) => guardResult(() {
    updateCalls++;
    return _updateCompleter.future;
  });

  @override
  Future<Result<Page<MinifiedCustomerModel>>> searchCustomers(
    CustomerSearchFilter? filter,
  ) => guardResult(() {
    throw UnimplementedError();
  });
}

/// Repositório de dispositivos cuja chamada de filtragem nunca completa,
/// mantendo `isLoading = true` indefinidamente após o construtor.
class _BlockingAllDevicesRepository implements AllDevicesRepository {
  int filteringCalls = 0;
  int searchCalls = 0;
  int typesCalls = 0;
  int brandsCalls = 0;

  @override
  Future<Result<Page<DeviceDataTable>>> getAllDevicesFiltering([
    DeviceFilter? filter,
  ]) => guardResult(() {
    filteringCalls++;
    return Completer<Page<DeviceDataTable>>().future; // nunca completa
  });

  @override
  Future<Result<Page<DeviceDataTable>>> searchDevices([
    DeviceSearchFilter? filter,
  ]) => guardResult(() {
    searchCalls++;
    return Completer<Page<DeviceDataTable>>().future;
  });

  @override
  Future<Result<List<DeviceType>>> getAllDeviceTypes([String? name]) =>
      guardResult(() async {
        typesCalls++;
        return [];
      });

  @override
  Future<Result<List<DeviceBrand>>> getAllDeviceBrands([String? name]) =>
      guardResult(() async {
        brandsCalls++;
        return [];
      });
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  group('SetupController — guard de autenticação', () {
    test(
      'authenticate retorna false imediatamente quando isLoading=true',
      () async {
        final controller = SetupController(authService: _stubAuthService());
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
        final repo = _BlockingCustomerRepository();
        final controller = CustomerRegisterController(repo);
        controller.isCreatingCustomer = true;

        final result = await controller.createCustomer(InputCustomer.empty());

        expect(result, isNull);
        expect(repo.createCalls, 0); // serviço não foi chamado
        expect(controller.isCreatingCustomer, true);
      },
    );

    test('segunda chamada concorrente é ignorada pelo guard', () async {
      final repo = _BlockingCustomerRepository();
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
        final repo = _BlockingCustomerRepository();
        final controller = CustomerDetailController(repo);
        controller.isLoading = true;

        await controller.fetchCustomer(1);

        expect(repo.getCalls, 0);
        expect(controller.isLoading, true);
      },
    );

    test('segunda chamada concorrente a fetchCustomer é ignorada', () async {
      final repo = _BlockingCustomerRepository();
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
        final repo = _BlockingCustomerRepository();
        final controller = CustomerDetailController(repo);
        controller.isLoading = true;

        final result = await controller.updateCustomer(1);

        expect(result, false);
        expect(repo.updateCalls, 0);
        expect(controller.isLoading, true);
      },
    );

    test('segunda chamada concorrente a updateCustomer é ignorada', () async {
      final repo = _BlockingCustomerRepository();
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
        final repo = _BlockingAllDevicesRepository();
        final controller = AllDevicesController(repo);

        // Construtor definiu isLoading = true sincronamente
        expect(controller.isLoading, true);
        // getAllDevicesFiltering ainda não foi chamado (está atrás do Future.delayed)
        expect(repo.filteringCalls, 0);

        // Nova chamada enquanto a primeira está no Future.delayed(200ms)
        final secondCall = controller.fetchAllDevicesFiltering();
        expect(controller.isLoading, true);

        // Aguarda o debounce de 200ms: apenas a geração mais nova chega ao repo
        await Future<void>.delayed(const Duration(milliseconds: 250));
        expect(repo.filteringCalls, 1);

        // Não aguardamos secondCall porque _BlockingAllDevicesRepository nunca completa
        unawaited(secondCall);
      },
    );

    test(
      'fetchFilterOptions não executa nova chamada quando isFiltersLoading=true',
      () async {
        final repo = _BlockingAllDevicesRepository();
        final controller = AllDevicesController(repo);

        // Construtor definiu isFiltersLoading = true sincronamente
        expect(controller.isFiltersLoading, true);
        // getAllDeviceTypes e getAllDeviceBrands foram chamados pelo construtor
        final typesBefore = repo.typesCalls;
        final brandsBefore = repo.brandsCalls;

        await controller.fetchFilterOptions(); // guard dispara

        expect(repo.typesCalls, typesBefore); // sem nova chamada
        expect(repo.brandsCalls, brandsBefore);
      },
    );
  });

  // -------------------------------------------------------------------------
  group('HomeController — guard de estatísticas', () {
    test(
      'getDeviceStatistics retorna sem side effects quando isLoading=true',
      () async {
        final controller = HomeController(
          DeviceStatisticsService(offlineApiClient()),
        );
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
