import 'package:flutter_workshop_front/core/http/api_client.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/home_table_filter.dart';

class HomeService {
  HomeService(this._api);

  final ApiClient _api;

  Future<Result<List<DeviceDataTable>>> getTableData([
    HomeTableFilter? filter,
  ]) {
    return _api.send(
      (dio) => dio.post<dynamic>('/v1/device/filter', data: filter?.toJson()),
      decode: (data) => parseList(data, DeviceDataTable.fromJson),
    );
  }
}
