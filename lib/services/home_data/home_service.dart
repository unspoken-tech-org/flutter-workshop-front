import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/home_table_filter.dart';

class HomeService {
  final Dio dio = Dio();

  Future<List<DeviceDataTable>> getTableData([HomeTableFilter? filter]) async {
    var body = filter?.toJson();
    Response result = await dio.post(
      'http://localhost:8080/v1/device/filter',
      options: Options(
        headers: {
          'Accept': 'application/json',
        },
      ),
      data: body,
    );

    return (result.data as List)
        .map((e) => DeviceDataTable.fromJson(e))
        .toList();
  }
}
