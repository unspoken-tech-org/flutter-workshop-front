import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';

class HomeService {
  final Dio dio = Dio();

  Future<List<DeviceDataTable>> getTableData() async {
    Response result = await dio.get(
      'http://localhost:8080/v1/device',
      options: Options(
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    return (result.data as List)
        .map((e) => DeviceDataTable.fromJson(e))
        .toList();
  }
}
