import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/models/device_statistics/device_statistics.dart';

class DeviceStatisticsService {
  final _dio = CustomDio.dioInstance();
  Future<DeviceStatistics> getDeviceStatistics() async {
    final response = await _dio.get('/v1/device-statistics');
    if (response.statusCode != 200) {
      throw RequisitionException.fromJson(response.data['error']);
    }
    return DeviceStatistics.fromJson(response.data);
  }
}
