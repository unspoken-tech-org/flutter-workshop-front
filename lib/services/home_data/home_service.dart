import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/home_table_filter.dart';

class HomeService {
  final Dio dio = CustomDio.dioInstance();

  Future<List<DeviceDataTable>> getTableData([HomeTableFilter? filter]) async {
    var body = filter?.toJson();
    Response result = await dio.post('/v1/device/filter', data: body);

    return (result.data as List)
        .map((e) => DeviceDataTable.fromJson(e))
        .toList();
  }
}
