import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/core/http/response_validation.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';

class DeviceBrandService {
  final Dio dio = CustomDio.dioInstance();

  Future<List<DeviceBrand>> getAllDeviceBrands([String? name]) async {
    final Response<List<dynamic>> result = await dio.get<List<dynamic>>(
      '/v1/brand',
      queryParameters: {'name': name},
    );
    result.ensureSuccess();

    return result.data!
        .map((e) => DeviceBrand.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
