import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer_device/create_device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';
import 'package:flutter_workshop_front/models/customer_device/input_payment.dart';
import 'package:flutter_workshop_front/models/device/device_input.dart';
import 'package:flutter_workshop_front/models/device/device_query.dart';
import 'package:flutter_workshop_front/models/device_statistics/device_statistics.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/repositories/device/device_repository.dart';

/// Fake tipado de [DeviceRepository] para testes unitários e de widget.
class FakeDeviceRepository extends Fake implements DeviceRepository {
  FakeDeviceRepository({
    this.onQueryDevices,
    this.queryDevicesResult,
    this.onGetCustomerDeviceById,
    this.customerDeviceResult,
    this.onCreateDeviceCustomer,
    this.createDeviceCustomerResult,
    this.onUpdateDeviceCustomer,
    this.updateDeviceCustomerResult,
    this.onUpdateDeviceStatus,
    this.updateDeviceStatusResult,
    this.onUpdateDeviceHasUrgency,
    this.updateDeviceHasUrgencyResult,
    this.onUpdateDeviceRevision,
    this.updateDeviceRevisionResult,
    this.onCreatePayment,
    this.createPaymentResult,
    this.onCreateCustomerContact,
    this.createCustomerContactResult,
    this.onUpdateCustomerContact,
    this.updateCustomerContactResult,
    this.onGetDeviceStatistics,
    this.deviceStatisticsResult,
  });

  Future<Result<Page<DeviceDataTable>>> Function(DeviceQuery query, int page)?
  onQueryDevices;
  Result<Page<DeviceDataTable>>? queryDevicesResult;
  final List<(DeviceQuery, int)> recordedDeviceQueries = [];

  Future<Result<DeviceCustomer>> Function(int id)? onGetCustomerDeviceById;
  Result<DeviceCustomer>? customerDeviceResult;
  final List<int> requestedDeviceIds = [];

  Future<Result<CreateDeviceCustomerResponse>> Function(DeviceInput device)?
  onCreateDeviceCustomer;
  Result<CreateDeviceCustomerResponse>? createDeviceCustomerResult;

  Future<Result<DeviceCustomer>> Function(DeviceCustomer deviceCustomer)?
  onUpdateDeviceCustomer;
  Result<DeviceCustomer>? updateDeviceCustomerResult;

  Future<Result<DeviceCustomer>> Function(int deviceId, StatusEnum status)?
  onUpdateDeviceStatus;
  Result<DeviceCustomer>? updateDeviceStatusResult;

  Future<Result<DeviceCustomer>> Function(int deviceId, bool hasUrgency)?
  onUpdateDeviceHasUrgency;
  Result<DeviceCustomer>? updateDeviceHasUrgencyResult;

  Future<Result<DeviceCustomer>> Function(int deviceId, bool revision)?
  onUpdateDeviceRevision;
  Result<DeviceCustomer>? updateDeviceRevisionResult;

  Future<Result<void>> Function(InputPayment payment)? onCreatePayment;
  Result<void>? createPaymentResult;

  Future<Result<void>> Function(InputCustomerContact customerContact)?
  onCreateCustomerContact;
  Result<void>? createCustomerContactResult;

  Future<Result<void>> Function(int id, InputCustomerContact customerContact)?
  onUpdateCustomerContact;
  Result<void>? updateCustomerContactResult;

  Future<Result<DeviceStatistics>> Function()? onGetDeviceStatistics;
  Result<DeviceStatistics>? deviceStatisticsResult;
  int getDeviceStatisticsCalls = 0;

  @override
  Future<Result<Page<DeviceDataTable>>> queryDevices(
    DeviceQuery query,
    int page,
  ) async {
    recordedDeviceQueries.add((query, page));
    if (onQueryDevices != null) {
      return onQueryDevices!(query, page);
    }
    if (queryDevicesResult != null) {
      return queryDevicesResult!;
    }
    throw UnimplementedError(
      'FakeDeviceRepository.queryDevices not configured',
    );
  }

  @override
  Future<Result<DeviceCustomer>> getCustomerDeviceById(int id) async {
    requestedDeviceIds.add(id);
    if (onGetCustomerDeviceById != null) {
      return onGetCustomerDeviceById!(id);
    }
    if (customerDeviceResult != null) {
      return customerDeviceResult!;
    }
    throw UnimplementedError(
      'FakeDeviceRepository.getCustomerDeviceById not configured',
    );
  }

  @override
  Future<Result<CreateDeviceCustomerResponse>> createDeviceCustomer(
    DeviceInput device,
  ) async {
    if (onCreateDeviceCustomer != null) {
      return onCreateDeviceCustomer!(device);
    }
    if (createDeviceCustomerResult != null) {
      return createDeviceCustomerResult!;
    }
    throw UnimplementedError(
      'FakeDeviceRepository.createDeviceCustomer not configured',
    );
  }

  @override
  Future<Result<DeviceCustomer>> updateDeviceCustomer(
    DeviceCustomer deviceCustomer,
  ) async {
    if (onUpdateDeviceCustomer != null) {
      return onUpdateDeviceCustomer!(deviceCustomer);
    }
    if (updateDeviceCustomerResult != null) {
      return updateDeviceCustomerResult!;
    }
    throw UnimplementedError(
      'FakeDeviceRepository.updateDeviceCustomer not configured',
    );
  }

  @override
  Future<Result<DeviceCustomer>> updateDeviceStatus(
    int deviceId,
    StatusEnum status,
  ) async {
    if (onUpdateDeviceStatus != null) {
      return onUpdateDeviceStatus!(deviceId, status);
    }
    if (updateDeviceStatusResult != null) {
      return updateDeviceStatusResult!;
    }
    throw UnimplementedError(
      'FakeDeviceRepository.updateDeviceStatus not configured',
    );
  }

  @override
  Future<Result<DeviceCustomer>> updateDeviceHasUrgency(
    int deviceId,
    bool hasUrgency,
  ) async {
    if (onUpdateDeviceHasUrgency != null) {
      return onUpdateDeviceHasUrgency!(deviceId, hasUrgency);
    }
    if (updateDeviceHasUrgencyResult != null) {
      return updateDeviceHasUrgencyResult!;
    }
    throw UnimplementedError(
      'FakeDeviceRepository.updateDeviceHasUrgency not configured',
    );
  }

  @override
  Future<Result<DeviceCustomer>> updateDeviceRevision(
    int deviceId,
    bool revision,
  ) async {
    if (onUpdateDeviceRevision != null) {
      return onUpdateDeviceRevision!(deviceId, revision);
    }
    if (updateDeviceRevisionResult != null) {
      return updateDeviceRevisionResult!;
    }
    throw UnimplementedError(
      'FakeDeviceRepository.updateDeviceRevision not configured',
    );
  }

  @override
  Future<Result<void>> createPayment(InputPayment payment) async {
    if (onCreatePayment != null) {
      return onCreatePayment!(payment);
    }
    if (createPaymentResult != null) {
      return createPaymentResult!;
    }
    throw UnimplementedError(
      'FakeDeviceRepository.createPayment not configured',
    );
  }

  @override
  Future<Result<void>> createCustomerContact(
    InputCustomerContact customerContact,
  ) async {
    if (onCreateCustomerContact != null) {
      return onCreateCustomerContact!(customerContact);
    }
    if (createCustomerContactResult != null) {
      return createCustomerContactResult!;
    }
    throw UnimplementedError(
      'FakeDeviceRepository.createCustomerContact not configured',
    );
  }

  @override
  Future<Result<void>> updateCustomerContact(
    int id,
    InputCustomerContact customerContact,
  ) async {
    if (onUpdateCustomerContact != null) {
      return onUpdateCustomerContact!(id, customerContact);
    }
    if (updateCustomerContactResult != null) {
      return updateCustomerContactResult!;
    }
    throw UnimplementedError(
      'FakeDeviceRepository.updateCustomerContact not configured',
    );
  }

  @override
  Future<Result<DeviceStatistics>> getDeviceStatistics() async {
    getDeviceStatisticsCalls++;
    if (onGetDeviceStatistics != null) {
      return onGetDeviceStatistics!();
    }
    if (deviceStatisticsResult != null) {
      return deviceStatisticsResult!;
    }
    throw UnimplementedError(
      'FakeDeviceRepository.getDeviceStatistics not configured',
    );
  }
}
