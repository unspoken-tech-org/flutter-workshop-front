import 'package:flutter_workshop_front/core/http/api_client.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer_device/create_device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/models/device/device_input.dart';
import 'package:flutter_workshop_front/models/device/device_search_filter.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';

class DeviceCustomerService {
  DeviceCustomerService(this._api);

  final ApiClient _api;

  static Page<DeviceDataTable> _decodePage(Object? data) => Page.fromJson(
    asJsonMap(data),
    (json) => DeviceDataTable.fromJson(json as Map<String, dynamic>),
  );

  static DeviceCustomer _decodeDevice(Object? data) =>
      DeviceCustomer.fromJson(asJsonMap(data));

  Future<Result<Page<DeviceDataTable>>> getAllDevicesFiltering([
    DeviceFilter? filter,
  ]) {
    return _api.send(
      (dio) => dio.post<dynamic>('/v1/device/filter', data: filter?.toJson()),
      decode: _decodePage,
    );
  }

  Future<Result<Page<DeviceDataTable>>> searchDevices([
    DeviceSearchFilter? filter,
  ]) {
    return _api.send(
      (dio) => dio.post<dynamic>('/v1/device/search', data: filter?.toJson()),
      decode: _decodePage,
    );
  }

  Future<Result<DeviceCustomer>> getCustomerDeviceById(int id) {
    return _api.send(
      (dio) => dio.get<dynamic>('/v1/device/$id'),
      decode: _decodeDevice,
    );
  }

  Future<Result<DeviceCustomer>> updateDeviceCustomer(
    DeviceCustomer deviceCustomer,
  ) {
    return _api.send(
      (dio) =>
          dio.put<dynamic>('/v1/device/update', data: deviceCustomer.toJson()),
      decode: _decodeDevice,
    );
  }

  Future<Result<DeviceCustomer>> updateDeviceStatus(
    int deviceId,
    StatusEnum status,
  ) {
    return _api.send(
      (dio) => dio.put<dynamic>(
        '/v1/device/update/$deviceId/status',
        data: {'deviceStatus': status.dbName},
      ),
      decode: _decodeDevice,
    );
  }

  Future<Result<DeviceCustomer>> updateDeviceHasUrgency(
    int deviceId,
    bool hasUrgency,
  ) {
    return _api.send(
      (dio) => dio.put<dynamic>(
        '/v1/device/update/$deviceId/urgency',
        data: {'hasUrgency': hasUrgency},
      ),
      decode: _decodeDevice,
    );
  }

  Future<Result<DeviceCustomer>> updateDeviceRevision(
    int deviceId,
    bool revision,
  ) {
    return _api.send(
      (dio) => dio.put<dynamic>(
        '/v1/device/update/$deviceId/revision',
        data: {'revision': revision},
      ),
      decode: _decodeDevice,
    );
  }

  Future<Result<CreateDeviceCustomerResponse>> createDeviceCustomer(
    DeviceInput device,
  ) {
    return _api.send(
      (dio) => dio.post<dynamic>('/v1/device/create', data: device.toJson()),
      expectedStatus: {201},
      decode: (data) => CreateDeviceCustomerResponse.fromJson(asJsonMap(data)),
    );
  }
}
