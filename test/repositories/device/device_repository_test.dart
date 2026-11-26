import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer_device/create_device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';
import 'package:flutter_workshop_front/models/customer_device/input_payment.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/models/device/device_input.dart';
import 'package:flutter_workshop_front/models/device/device_search_filter.dart';
import 'package:flutter_workshop_front/models/device_statistics/device_statistics.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/repositories/device/device_repository.dart';
import 'package:flutter_workshop_front/services/customer_contact/customer_contact_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_customer_service.dart';
import 'package:flutter_workshop_front/services/device_statistics/device_statistics_service.dart';
import 'package:flutter_workshop_front/services/payment/payment_service.dart';

import '../../support/fixtures/device_customer_fixture.dart';
import '../../support/fixtures/device_statistics_fixture.dart';
import '../../support/fixtures/page_fixture.dart';

class _FakeDeviceCustomerService extends Fake implements DeviceCustomerService {
  DeviceFilter? lastDeviceFilter;
  DeviceSearchFilter? lastSearchFilter;
  int? lastDeviceId;
  DeviceInput? lastDeviceInput;
  DeviceCustomer? lastUpdatedDevice;
  (int, StatusEnum)? lastStatusUpdate;
  (int, bool)? lastUrgencyUpdate;
  (int, bool)? lastRevisionUpdate;

  Result<Page<DeviceDataTable>> allDevicesResult = Ok(
    makePage([makeDeviceDataTable()]),
  );
  Result<Page<DeviceDataTable>> searchDevicesResult = Ok(
    makePage([makeDeviceDataTable(deviceId: 2)]),
  );
  Result<DeviceCustomer> deviceByIdResult = Ok(makeDeviceCustomer());
  Result<CreateDeviceCustomerResponse> createResult = Ok(
    CreateDeviceCustomerResponse(deviceId: 99),
  );
  Result<DeviceCustomer> updateResult = Ok(makeDeviceCustomer(deviceId: 10));

  @override
  Future<Result<Page<DeviceDataTable>>> getAllDevicesFiltering([
    DeviceFilter? filter,
  ]) async {
    lastDeviceFilter = filter;
    return allDevicesResult;
  }

  @override
  Future<Result<Page<DeviceDataTable>>> searchDevices([
    DeviceSearchFilter? filter,
  ]) async {
    lastSearchFilter = filter;
    return searchDevicesResult;
  }

  @override
  Future<Result<DeviceCustomer>> getCustomerDeviceById(int id) async {
    lastDeviceId = id;
    return deviceByIdResult;
  }

  @override
  Future<Result<CreateDeviceCustomerResponse>> createDeviceCustomer(
    DeviceInput device,
  ) async {
    lastDeviceInput = device;
    return createResult;
  }

  @override
  Future<Result<DeviceCustomer>> updateDeviceCustomer(
    DeviceCustomer deviceCustomer,
  ) async {
    lastUpdatedDevice = deviceCustomer;
    return updateResult;
  }

  @override
  Future<Result<DeviceCustomer>> updateDeviceStatus(
    int deviceId,
    StatusEnum status,
  ) async {
    lastStatusUpdate = (deviceId, status);
    return updateResult;
  }

  @override
  Future<Result<DeviceCustomer>> updateDeviceHasUrgency(
    int deviceId,
    bool hasUrgency,
  ) async {
    lastUrgencyUpdate = (deviceId, hasUrgency);
    return updateResult;
  }

  @override
  Future<Result<DeviceCustomer>> updateDeviceRevision(
    int deviceId,
    bool revision,
  ) async {
    lastRevisionUpdate = (deviceId, revision);
    return updateResult;
  }
}

class _FakePaymentService extends Fake implements PaymentService {
  InputPayment? lastPayment;
  Result<void> nextResult = const Ok(null);

  @override
  Future<Result<void>> createPayment(InputPayment payment) async {
    lastPayment = payment;
    return nextResult;
  }
}

class _FakeCustomerContactService extends Fake
    implements CustomerContactService {
  InputCustomerContact? lastCreatedContact;
  (int, InputCustomerContact)? lastUpdatedContact;
  Result<void> nextResult = const Ok(null);

  @override
  Future<Result<void>> createCustomerContact(
    InputCustomerContact customerContact,
  ) async {
    lastCreatedContact = customerContact;
    return nextResult;
  }

  @override
  Future<Result<void>> updateCustomerContact(
    int id,
    InputCustomerContact customerContact,
  ) async {
    lastUpdatedContact = (id, customerContact);
    return nextResult;
  }
}

class _FakeDeviceStatisticsService extends Fake
    implements DeviceStatisticsService {
  int calls = 0;
  Result<DeviceStatistics> nextResult = Ok(makeDeviceStatistics());

  @override
  Future<Result<DeviceStatistics>> getDeviceStatistics() async {
    calls++;
    return nextResult;
  }
}

void main() {
  late _FakeDeviceCustomerService deviceCustomerService;
  late _FakePaymentService paymentService;
  late _FakeCustomerContactService customerContactService;
  late _FakeDeviceStatisticsService statisticsService;
  late DeviceRepository repository;

  setUp(() {
    deviceCustomerService = _FakeDeviceCustomerService();
    paymentService = _FakePaymentService();
    customerContactService = _FakeCustomerContactService();
    statisticsService = _FakeDeviceStatisticsService();
    repository = DeviceRepository(
      deviceCustomerService: deviceCustomerService,
      paymentService: paymentService,
      customerContactService: customerContactService,
      deviceStatisticsService: statisticsService,
    );
  });

  group('DeviceRepository', () {
    test('getAllDevicesFiltering forwards filter and returns Result', () async {
      final filter = DeviceFilter(customerName: 'Maria', page: 2);
      final result = await repository.getAllDevicesFiltering(filter);

      expect(deviceCustomerService.lastDeviceFilter, same(filter));
      expect(result.valueOrNull?.content, hasLength(1));
    });

    test('searchDevices forwards filter and returns Result', () async {
      final filter = DeviceSearchFilter(searchQuery: 'Galaxy');
      final result = await repository.searchDevices(filter);

      expect(deviceCustomerService.lastSearchFilter, same(filter));
      expect(result.valueOrNull?.content.single.deviceId, 2);
    });

    test('getCustomerDeviceById forwards id and propagates Err', () async {
      deviceCustomerService.deviceByIdResult = const Err(NetworkFailure());
      final result = await repository.getCustomerDeviceById(42);

      expect(deviceCustomerService.lastDeviceId, 42);
      expect(result, isA<Err<DeviceCustomer>>());
    });

    test('createDeviceCustomer forwards payload and returns id', () async {
      final input = DeviceInput.empty().copyWith(customerId: 7);
      final result = await repository.createDeviceCustomer(input);

      expect(deviceCustomerService.lastDeviceInput, same(input));
      expect(result.valueOrNull?.deviceId, 99);
    });

    test('updateDeviceCustomer forwards entity', () async {
      final device = makeDeviceCustomer(deviceId: 10);
      final result = await repository.updateDeviceCustomer(device);

      expect(deviceCustomerService.lastUpdatedDevice, same(device));
      expect(result.valueOrNull?.deviceId, 10);
    });

    test(
      'updateDeviceStatus, urgency, and revision forward arguments',
      () async {
        await repository.updateDeviceStatus(5, StatusEnum.ready);
        await repository.updateDeviceHasUrgency(5, true);
        await repository.updateDeviceRevision(5, false);

        expect(deviceCustomerService.lastStatusUpdate, (5, StatusEnum.ready));
        expect(deviceCustomerService.lastUrgencyUpdate, (5, true));
        expect(deviceCustomerService.lastRevisionUpdate, (5, false));
      },
    );

    test('createPayment forwards payment and propagates Err', () async {
      final payment = InputPayment.empty(1);
      paymentService.nextResult = const Err(
        ValidationFailure(
          message: 'Valor inválido',
          code: '400',
          statusCode: 400,
        ),
      );

      final result = await repository.createPayment(payment);

      expect(paymentService.lastPayment, same(payment));
      expect(result, isA<Err<void>>());
    });

    test(
      'createCustomerContact and updateCustomerContact forward arguments',
      () async {
        final contact = InputCustomerContact.empty(3);
        await repository.createCustomerContact(contact);
        await repository.updateCustomerContact(12, contact);

        expect(customerContactService.lastCreatedContact, same(contact));
        expect(customerContactService.lastUpdatedContact, (12, contact));
      },
    );

    test('getDeviceStatistics delegates to statistics service', () async {
      final result = await repository.getDeviceStatistics();

      expect(statisticsService.calls, 1);
      expect(result, isA<Ok<DeviceStatistics>>());
    });
  });
}
