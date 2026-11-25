import 'package:flutter_workshop_front/core/http/api_client.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';

class DeviceBrandService {
  DeviceBrandService(this._api);

  final ApiClient _api;

  Future<Result<List<DeviceBrand>>> getAllDeviceBrands([String? name]) {
    return _api.send(
      (dio) => dio.get<dynamic>('/v1/brand', queryParameters: {'name': name}),
      decode: (data) => parseList(data, DeviceBrand.fromJson),
    );
  }
}
