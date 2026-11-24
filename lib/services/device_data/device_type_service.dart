import 'package:flutter_workshop_front/core/http/api_client.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';

class DeviceTypeService {
  DeviceTypeService(this._api);

  final ApiClient _api;

  Future<Result<List<DeviceType>>> getAllDeviceTypes([String? name]) {
    return _api.send(
      (dio) => dio.get<dynamic>('/v1/type', queryParameters: {'name': name}),
      decode: (data) => parseList(data, DeviceType.fromJson),
    );
  }
}
