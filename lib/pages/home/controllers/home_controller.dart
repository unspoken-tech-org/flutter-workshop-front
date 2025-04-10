import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/home_table_filter.dart';
import 'package:flutter_workshop_front/pages/home/states/loading_home_state.dart';
import 'package:flutter_workshop_front/services/device_data/device_brand_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_type_service.dart';
import 'package:flutter_workshop_front/services/home_data/home_service.dart';

class HomeController {
  final homeService = HomeService();
  final typeService = DeviceTypeService();
  final brandService = DeviceBrandService();
  bool isDatePickerOpen = false;

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

  Future<List<DeviceTypeModel>> getAllDeviceTypes([String? name]) async {
    var result = await typeService.getAllDeviceTypes(name);
    return result;
  }

  Future<List<DeviceBrandModel>> getAllDeviceBrands([String? name]) async {
    var result = await brandService.getAllDeviceBrands(name);
    return result;
  }
}
