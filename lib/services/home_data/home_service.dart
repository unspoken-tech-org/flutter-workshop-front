import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/home_table_filter.dart';

class HomeService {
  final Dio dio = CustomDio.dioInstance();

  Future<List<DeviceDataTable>> getTableData([HomeTableFilter? filter]) async {
    final body = filter?.toJson();
    final Response<List<dynamic>> result = await dio.post<List<dynamic>>(
      '/v1/device/filter',
      data: body,
    );

    return result.data!
        .map((e) => DeviceDataTable.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
