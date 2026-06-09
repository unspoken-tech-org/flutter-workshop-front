import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/models/customer_device/create_device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/models/device/device_input.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';

class DeviceCustomerService {
  final Dio dio = CustomDio.dioInstance();

  Future<Page<DeviceDataTable>> getAllDevicesFiltering(
      [DeviceFilter? filter]) async {
    var body = filter?.toJson();
    Response response = await dio.post('/v1/device/filter', data: body);

    if (response.statusCode != 200) {
      throw RequisitionException.fromJson(response.data['error']);
    }

    return Page.fromJson(
        response.data, (json) => DeviceDataTable.fromJson(json));
  }

  Future<DeviceCustomer> getCustomerDeviceById(int id) async {
    Response response = await dio.get('/v1/device/$id');

    if (response.statusCode != 200) {
      throw RequisitionException.fromJson(response.data['error']);
    }

    return DeviceCustomer.fromJson(response.data);
  }

  Future<DeviceCustomer> updateDeviceCustomer(
      DeviceCustomer deviceCustomer) async {
    var json = deviceCustomer.toJson();

    Response response = await dio.put('/v1/device/update', data: json);

    if (response.statusCode != 200) {
      throw RequisitionException.fromJson(response.data['error']);
    }

    return DeviceCustomer.fromJson(response.data);
  }

  Future<DeviceCustomer> updateDeviceStatus(
      int deviceId, StatusEnum status) async {
    Response response = await dio.put(
      '/v1/device/update/$deviceId/status',
      data: {'deviceStatus': status.dbName},
    );

    if (response.statusCode != 200) {
      throw RequisitionException.fromJson(response.data['error']);
    }

    return DeviceCustomer.fromJson(response.data);
  }

  Future<DeviceCustomer> updateDeviceHasUrgency(
      int deviceId, bool hasUrgency) async {
    Response response = await dio.put(
      '/v1/device/update/$deviceId/urgency',
      data: {'hasUrgency': hasUrgency},
    );

    if (response.statusCode != 200) {
      throw RequisitionException.fromJson(response.data['error']);
    }

    return DeviceCustomer.fromJson(response.data);
  }

  Future<DeviceCustomer> updateDeviceRevision(
      int deviceId, bool revision) async {
    Response response = await dio.put(
      '/v1/device/update/$deviceId/revision',
      data: {'revision': revision},
    );

    if (response.statusCode != 200) {
      throw RequisitionException.fromJson(response.data['error']);
    }

    return DeviceCustomer.fromJson(response.data);
  }

  Future<CreateDeviceCustomerResponse> createDeviceCustomer(
      DeviceInput device) async {
    var json = device.toJson();

    Response response = await dio.post('/v1/device/create', data: json);

    if (response.statusCode != 201) {
      throw RequisitionException.fromJson(response.data['error']);
    }
    return CreateDeviceCustomerResponse.fromJson(response.data);
  }
}
