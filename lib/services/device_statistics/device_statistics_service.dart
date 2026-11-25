import 'package:flutter_workshop_front/core/http/api_client.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/device_statistics/device_statistics.dart';

class DeviceStatisticsService {
  DeviceStatisticsService(this._api);

  final ApiClient _api;

  Future<Result<DeviceStatistics>> getDeviceStatistics() {
    return _api.send(
      (dio) => dio.get<dynamic>('/v1/device-statistics'),
      decode: (data) => DeviceStatistics.fromJson(asJsonMap(data)),
    );
  }
}
