import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';

class DeviceBrandService {
  final Dio dio = CustomDio.dioInstance();

  Future<List<DeviceBrand>> getAllDeviceBrands([String? name]) async {
    Response result = await dio.get(
      '/v1/brand',
      queryParameters: {'name': name},
    );

    return (result.data as List).map((e) => DeviceBrand.fromJson(e)).toList();
  }
}
