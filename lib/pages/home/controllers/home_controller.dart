import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/home_table_filter.dart';
import 'package:flutter_workshop_front/pages/home/states/loading_home_state.dart';
import 'package:flutter_workshop_front/services/home_data/home_service.dart';

class HomeController {
  final homeService = HomeService();

  HomeTableFilter filter = HomeTableFilter();

  ValueNotifier<List<DeviceDataTable>> tableData = ValueNotifier([]);
  ValueNotifier<LoadingHomeState> loadingState =
      ValueNotifier(LoadingHomeState());

  Future<void> getTableData([HomeTableFilter? filter]) async {
    loadingState.value = loadingState.value.copyWith(isTableLoading: true);
    var result = await homeService.getTableData(filter);
    tableData.value = result;
    loadingState.value = loadingState.value.copyWith(isTableLoading: false);
  }
}
