// ignore_for_file: unawaited_futures
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/core/security/security_storage.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/controllers/customer_detail_controller.dart';
import 'package:flutter_workshop_front/pages/customers/customer_register/controllers/customer_register_controller.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/controllers/all_devices_controller.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/home/controllers/home_controller.dart';
import 'package:flutter_workshop_front/pages/setup/setup_controller.dart';
import 'package:flutter_workshop_front/repositories/all_devices/all_devices_repository.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';

// ---------------------------------------------------------------------------
// Stubs
// ---------------------------------------------------------------------------

class _MemorySecurityStorage implements SecurityStorage {
  final _data = <String, String>{};

  @override
  Future<void> saveApiKey(String key) async => _data['api_key'] = key;

  @override
  Future<String?> getApiKey() async => _data['api_key'];

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _data['at'] = accessToken;
    _data['rt'] = refreshToken;
  }

  @override
  Future<void> saveAccessToken(String accessToken) async =>
      _data['at'] = accessToken;

  @override
  Future<String?> getAccessToken() async => _data['at'];

  @override
  Future<String?> getRefreshToken() async => _data['rt'];

  @override
  Future<String> getBoundDeviceId() async => 'test-device';

  @override
  Future<void> clearSession() async {
    _data.remove('at');
    _data.remove('rt');
  }

  @override
  Future<void> clearProvisioning({bool removeBoundDeviceId = false}) async {
    await clearSession();
    _data.remove('api_key');
  }

  @override
  Future<void> clearAll() async => _data.clear();
}

AuthService _stubAuthService() => AuthService(
      dio: Dio(),
      storage: _MemorySecurityStorage(),
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
  Future<CustomerModel> createCustomer(InputCustomer customer) {
    createCalls++;
    return _createCompleter.future;
  }

  @override
  Future<CustomerModel> getCustomer(int customerId) {
    getCalls++;
    return _getCompleter.future;
  }

  @override
  Future<CustomerModel> updateCustomer(
      int customerId, InputCustomer customer) {
    updateCalls++;
    return _updateCompleter.future;
  }

  @override
  Future<Page<MinifiedCustomerModel>> searchCustomers(
      CustomerSearchFilter? filter) {
    throw UnimplementedError();
  }
}

/// Repositório de dispositivos cuja chamada de filtragem nunca completa,
/// mantendo `isLoading = true` indefinidamente após o construtor.
class _BlockingAllDevicesRepository implements AllDevicesRepository {
  int filteringCalls = 0;
  int typesCalls = 0;
  int brandsCalls = 0;

  @override
  Future<Page<DeviceDataTable>> getAllDevicesFiltering([DeviceFilter? filter]) {
    filteringCalls++;
    return Completer<Page<DeviceDataTable>>().future; // nunca completa
  }

  @override
  Future<List<DeviceType>> getAllDeviceTypes([String? name]) async {
    typesCalls++;
    return [];
  }

  @override
  Future<List<DeviceBrand>> getAllDeviceBrands([String? name]) async {
    brandsCalls++;
    return [];
  }
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=https://test.example.com\n');
  });

  // -------------------------------------------------------------------------
  group('SetupController — guard de autenticação', () {
    test('authenticate retorna false imediatamente quando isLoading=true',
        () async {
      final controller = SetupController(authService: _stubAuthService());
      controller.isLoading = true;

      final result = await controller.authenticate('api-key');

      expect(result, false);
      // flag não foi resetada (método retornou antes do finally)
      expect(controller.isLoading, true);
    });
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
    });

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
        'fetchCustomer retorna sem chamar o repo quando isLoading.value=true',
        () async {
      final repo = _BlockingCustomerRepository();
      final controller = CustomerDetailController(repo);
      controller.isLoading.value = true;

      await controller.fetchCustomer(1);

      expect(repo.getCalls, 0);
      expect(controller.isLoading.value, true);
    });

    test('segunda chamada concorrente a fetchCustomer é ignorada', () async {
      final repo = _BlockingCustomerRepository();
      final controller = CustomerDetailController(repo);

      // Primeira chamada: bloqueia no repositório
      controller.fetchCustomer(1);
      expect(controller.isLoading.value, true);
      expect(repo.getCalls, 1);

      // Segunda chamada enquanto a primeira está em progresso
      await controller.fetchCustomer(1);

      expect(repo.getCalls, 1);
    });

    test(
        'updateCustomer retorna false sem chamar o repo quando isLoading.value=true',
        () async {
      final repo = _BlockingCustomerRepository();
      final controller = CustomerDetailController(repo);
      controller.isLoading.value = true;

      final result = await controller.updateCustomer(1);

      expect(result, false);
      expect(repo.updateCalls, 0);
      expect(controller.isLoading.value, true);
    });

    test('segunda chamada concorrente a updateCustomer é ignorada', () async {
      final repo = _BlockingCustomerRepository();
      final controller = CustomerDetailController(repo);

      // Primeira chamada: bloqueia no repositório
      controller.updateCustomer(1);
      expect(controller.isLoading.value, true);
      expect(repo.updateCalls, 1);

      // Segunda chamada enquanto a primeira está em progresso
      final result = await controller.updateCustomer(1);

      expect(result, false);
      expect(repo.updateCalls, 1);
    });
  });

  // -------------------------------------------------------------------------
  group('AllDevicesController — guard de listagem', () {
    // O construtor chama fetchAllDevicesFiltering() fire-and-forget.
    // A parte síncrona do método define isLoading = true antes do primeiro
    // await, portanto isLoading já é true logo após a construção do controller.

    test(
        'fetchAllDevicesFiltering não executa nova chamada quando isLoading=true',
        () async {
      final repo = _BlockingAllDevicesRepository();
      final controller = AllDevicesController(repo);

      // Construtor definiu isLoading = true sincronamente
      expect(controller.isLoading, true);
      // getAllDevicesFiltering ainda não foi chamado (está atrás do Future.delayed)
      expect(repo.filteringCalls, 0);

      await controller.fetchAllDevicesFiltering(); // guard dispara

      expect(repo.filteringCalls, 0); // nenhuma nova chamada
    });

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
    });
  });

  // -------------------------------------------------------------------------
  group('HomeController — guard de estatísticas', () {
    test(
        'getDeviceStatistics retorna sem side effects quando isLoading=true',
        () async {
      final controller = HomeController();
      controller.isLoading = true;
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.getDeviceStatistics();

      expect(controller.isLoading, true);
      expect(notifyCount, 0); // nenhum listener notificado
    });
  });

  // -------------------------------------------------------------------------
  group('DeviceCustomerPageController — guards de atualização', () {
    // Neste controller os serviços são instanciados internamente (sem DI).
    // Os testes verificam que o guard dispara antes de qualquer acesso
    // a serviços ou campos late (deviceCustomer, technicians).

    test('updateDeviceCustomer retorna sem side effects quando isUpdating=true',
        () async {
      final controller = DeviceCustomerPageController();
      controller.isUpdating = true;
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.updateDeviceCustomer();

      expect(controller.isUpdating, true);
      expect(notifyCount, 0);
    });

    test(
        'updateDeviceHasUrgency retorna sem side effects quando isUpdating=true',
        () async {
      final controller = DeviceCustomerPageController();
      controller.isUpdating = true;
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.updateDeviceHasUrgency(true);

      expect(controller.isUpdating, true);
      expect(notifyCount, 0);
    });

    test(
        'updateDeviceRevision retorna sem side effects quando isUpdating=true',
        () async {
      final controller = DeviceCustomerPageController();
      controller.isUpdating = true;
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.updateDeviceRevision(true);

      expect(controller.isUpdating, true);
      expect(notifyCount, 0);
    });

    test('updateDeviceStatus retorna sem side effects quando isUpdating=true',
        () async {
      final controller = DeviceCustomerPageController();
      controller.isUpdating = true;
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.updateDeviceStatus(StatusEnum.newDevice);

      expect(controller.isUpdating, true);
      expect(notifyCount, 0);
    });

    test(
        'createCustomerContact retorna sem side effects quando isCreatingContact=true',
        () async {
      final controller = DeviceCustomerPageController();
      controller.isCreatingContact = true;
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.createCustomerContact(InputCustomerContact.empty(1));

      expect(controller.isCreatingContact, true);
      expect(notifyCount, 0);
    });
  });
}
