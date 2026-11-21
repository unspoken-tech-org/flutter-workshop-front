import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/core/http/response_validation.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';

class DeviceTypeService {
  final Dio dio = CustomDio.dioInstance();

  Future<List<DeviceType>> getAllDeviceTypes([String? name]) async {
    final Response<List<dynamic>> result = await dio.get<List<dynamic>>(
      '/v1/type',
      queryParameters: {'name': name},
    );
    result.ensureSuccess();

    return result.data!
        .map((e) => DeviceType.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
