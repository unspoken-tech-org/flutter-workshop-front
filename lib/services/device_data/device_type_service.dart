import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';

class DeviceTypeService {
  final Dio dio = Dio();

  Future<List<DeviceType>> getAllDeviceTypes([String? name]) async {
    Response result = await dio.get('http://localhost:8080/v1/type',
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
        queryParameters: {
          'name': name,
        });

    return (result.data as List).map((e) => DeviceType.fromJson(e)).toList();
  }
}
