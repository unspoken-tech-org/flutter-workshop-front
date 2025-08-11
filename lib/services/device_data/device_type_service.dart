import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';

class DeviceTypeService {
  final Dio dio = CustomDio.dioInstance();

  Future<List<DeviceType>> getAllDeviceTypes([String? name]) async {
    Response result = await dio.get(
      '/v1/type',
      queryParameters: {'name': name},
    );

    return (result.data as List).map((e) => DeviceType.fromJson(e)).toList();
  }
}
