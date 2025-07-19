import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';

class DeviceBrandService {
  final Dio dio = Dio();

  Future<List<DeviceBrand>> getAllDeviceBrands([String? name]) async {
    Response result = await dio.get('http://localhost:8080/v1/brand',
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
        queryParameters: {
          'name': name,
        });

    return (result.data as List).map((e) => DeviceBrand.fromJson(e)).toList();
  }
}
