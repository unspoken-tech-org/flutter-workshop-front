import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/models/device/device_search_filter.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';

abstract class AllDevicesRepository {
  Future<Result<Page<DeviceDataTable>>> getAllDevicesFiltering([
    DeviceFilter? filter,
  ]);
  Future<Result<Page<DeviceDataTable>>> searchDevices([
    DeviceSearchFilter? filter,
  ]);
  Future<Result<List<DeviceType>>> getAllDeviceTypes([String? name]);
  Future<Result<List<DeviceBrand>>> getAllDeviceBrands([String? name]);
}
