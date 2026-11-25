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
import 'package:flutter_workshop_front/services/customer_contact/customer_contact_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_customer_service.dart';
import 'package:flutter_workshop_front/services/device_statistics/device_statistics_service.dart';
import 'package:flutter_workshop_front/services/payment/payment_service.dart';

class DeviceRepository {
  DeviceRepository({
    required DeviceCustomerService deviceCustomerService,
    required PaymentService paymentService,
    required CustomerContactService customerContactService,
    required DeviceStatisticsService deviceStatisticsService,
  }) : _deviceCustomerService = deviceCustomerService,
       _paymentService = paymentService,
       _customerContactService = customerContactService,
       _deviceStatisticsService = deviceStatisticsService;

  final DeviceCustomerService _deviceCustomerService;
  final PaymentService _paymentService;
  final CustomerContactService _customerContactService;
  final DeviceStatisticsService _deviceStatisticsService;

  Future<Result<Page<DeviceDataTable>>> getAllDevicesFiltering([
    DeviceFilter? filter,
  ]) => _deviceCustomerService.getAllDevicesFiltering(filter);

  Future<Result<Page<DeviceDataTable>>> searchDevices([
    DeviceSearchFilter? filter,
  ]) => _deviceCustomerService.searchDevices(filter);

  Future<Result<DeviceCustomer>> getCustomerDeviceById(int id) =>
      _deviceCustomerService.getCustomerDeviceById(id);

  Future<Result<CreateDeviceCustomerResponse>> createDeviceCustomer(
    DeviceInput device,
  ) => _deviceCustomerService.createDeviceCustomer(device);

  Future<Result<DeviceCustomer>> updateDeviceCustomer(
    DeviceCustomer deviceCustomer,
  ) => _deviceCustomerService.updateDeviceCustomer(deviceCustomer);

  Future<Result<DeviceCustomer>> updateDeviceStatus(
    int deviceId,
    StatusEnum status,
  ) => _deviceCustomerService.updateDeviceStatus(deviceId, status);

  Future<Result<DeviceCustomer>> updateDeviceHasUrgency(
    int deviceId,
    bool hasUrgency,
  ) => _deviceCustomerService.updateDeviceHasUrgency(deviceId, hasUrgency);

  Future<Result<DeviceCustomer>> updateDeviceRevision(
    int deviceId,
    bool revision,
  ) => _deviceCustomerService.updateDeviceRevision(deviceId, revision);

  Future<Result<void>> createPayment(InputPayment payment) =>
      _paymentService.createPayment(payment);

  Future<Result<void>> createCustomerContact(
    InputCustomerContact customerContact,
  ) => _customerContactService.createCustomerContact(customerContact);

  Future<Result<void>> updateCustomerContact(
    int id,
    InputCustomerContact customerContact,
  ) => _customerContactService.updateCustomerContact(id, customerContact);

  Future<Result<DeviceStatistics>> getDeviceStatistics() =>
      _deviceStatisticsService.getDeviceStatistics();
}
