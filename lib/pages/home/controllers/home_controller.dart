import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/pages/home/states/loading_home_state.dart';
import 'package:flutter_workshop_front/services/home_data/home_service.dart';

class HomeController {
  final homeService = HomeService();

  ValueNotifier<List<DeviceDataTable>> tableData = ValueNotifier([]);
  ValueNotifier<LoadingHomeState> loadingState =
      ValueNotifier(LoadingHomeState());

  Future<void> getTableData() async {
    loadingState.value = loadingState.value.copyWith(isTableLoading: true);
    var result = await homeService.getTableData();
    tableData.value = result;
    loadingState.value = loadingState.value.copyWith(isTableLoading: false);
  }
}
