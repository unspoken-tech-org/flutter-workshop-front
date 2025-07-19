import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';

abstract class AllDevicesRepository {
  Future<List<DeviceDataTable>> getAllDevicesFiltering([DeviceFilter? filter]);
  Future<List<DeviceType>> getAllDeviceTypes([String? name]);
  Future<List<DeviceBrand>> getAllDeviceBrands([String? name]);
}
