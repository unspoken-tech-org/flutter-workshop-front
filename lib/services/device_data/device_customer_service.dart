import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/models/customer_device/create_device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/models/device/device_search_filter.dart';
import 'package:flutter_workshop_front/models/device/device_input.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';

class DeviceCustomerService {
  final Dio dio = CustomDio.dioInstance();

  Future<Page<DeviceDataTable>> getAllDevicesFiltering([
    DeviceFilter? filter,
  ]) async {
    final body = filter?.toJson();
    final Response<Map<String, dynamic>> response = await dio
        .post<Map<String, dynamic>>('/v1/device/filter', data: body);

    if (response.statusCode != 200) {
      throw RequisitionException.fromJson(
        response.data!['error'] as Map<String, dynamic>,
      );
    }

    return Page.fromJson(
      response.data!,
      (json) => DeviceDataTable.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Page<DeviceDataTable>> searchDevices([
    DeviceSearchFilter? filter,
  ]) async {
    final body = filter?.toJson();
    final Response<Map<String, dynamic>> response = await dio
        .post<Map<String, dynamic>>('/v1/device/search', data: body);

    if (response.statusCode != 200) {
      throw RequisitionException.fromJson(
        response.data!['error'] as Map<String, dynamic>,
      );
    }

    return Page.fromJson(
      response.data!,
      (json) => DeviceDataTable.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<DeviceCustomer> getCustomerDeviceById(int id) async {
    final Response<Map<String, dynamic>> response = await dio
        .get<Map<String, dynamic>>('/v1/device/$id');

    if (response.statusCode != 200) {
      throw RequisitionException.fromJson(
        response.data!['error'] as Map<String, dynamic>,
      );
    }

    return DeviceCustomer.fromJson(response.data!);
  }

  Future<DeviceCustomer> updateDeviceCustomer(
    DeviceCustomer deviceCustomer,
  ) async {
    final json = deviceCustomer.toJson();

    final Response<Map<String, dynamic>> response = await dio
        .put<Map<String, dynamic>>('/v1/device/update', data: json);

    if (response.statusCode != 200) {
      throw RequisitionException.fromJson(
        response.data!['error'] as Map<String, dynamic>,
      );
    }

    return DeviceCustomer.fromJson(response.data!);
  }

  Future<DeviceCustomer> updateDeviceStatus(
    int deviceId,
    StatusEnum status,
  ) async {
    final Response<Map<String, dynamic>> response = await dio
        .put<Map<String, dynamic>>(
          '/v1/device/update/$deviceId/status',
          data: {'deviceStatus': status.dbName},
        );

    if (response.statusCode != 200) {
      throw RequisitionException.fromJson(
        response.data!['error'] as Map<String, dynamic>,
      );
    }

    return DeviceCustomer.fromJson(response.data!);
  }

  Future<DeviceCustomer> updateDeviceHasUrgency(
    int deviceId,
    bool hasUrgency,
  ) async {
    final Response<Map<String, dynamic>> response = await dio
        .put<Map<String, dynamic>>(
          '/v1/device/update/$deviceId/urgency',
          data: {'hasUrgency': hasUrgency},
        );

    if (response.statusCode != 200) {
      throw RequisitionException.fromJson(
        response.data!['error'] as Map<String, dynamic>,
      );
    }

    return DeviceCustomer.fromJson(response.data!);
  }

  Future<DeviceCustomer> updateDeviceRevision(
    int deviceId,
    bool revision,
  ) async {
    final Response<Map<String, dynamic>> response = await dio
        .put<Map<String, dynamic>>(
          '/v1/device/update/$deviceId/revision',
          data: {'revision': revision},
        );

    if (response.statusCode != 200) {
      throw RequisitionException.fromJson(
        response.data!['error'] as Map<String, dynamic>,
      );
    }

    return DeviceCustomer.fromJson(response.data!);
  }

  Future<CreateDeviceCustomerResponse> createDeviceCustomer(
    DeviceInput device,
  ) async {
    final json = device.toJson();

    final Response<Map<String, dynamic>> response = await dio
        .post<Map<String, dynamic>>('/v1/device/create', data: json);

    if (response.statusCode != 201) {
      throw RequisitionException.fromJson(
        response.data!['error'] as Map<String, dynamic>,
      );
    }
    return CreateDeviceCustomerResponse.fromJson(response.data!);
  }
}
