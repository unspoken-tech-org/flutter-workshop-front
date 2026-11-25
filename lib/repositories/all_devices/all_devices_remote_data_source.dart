import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/models/device/device_search_filter.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/repositories/all_devices/all_devices_repository.dart';
import 'package:flutter_workshop_front/services/device_data/device_brand_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_customer_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_type_service.dart';

class AllDevicesRemoteDataSource implements AllDevicesRepository {
  AllDevicesRemoteDataSource(
    this._deviceCustomerService,
    this._deviceTypeService,
    this._deviceBrandService,
  );

  final DeviceCustomerService _deviceCustomerService;
  final DeviceTypeService _deviceTypeService;
  final DeviceBrandService _deviceBrandService;

  @override
  Future<Result<Page<DeviceDataTable>>> getAllDevicesFiltering([
    DeviceFilter? filter,
  ]) {
    return _deviceCustomerService.getAllDevicesFiltering(filter);
  }

  @override
  Future<Result<Page<DeviceDataTable>>> searchDevices([
    DeviceSearchFilter? filter,
  ]) {
    return _deviceCustomerService.searchDevices(filter);
  }

  @override
  Future<Result<List<DeviceType>>> getAllDeviceTypes([String? name]) {
    return _deviceTypeService.getAllDeviceTypes(name);
  }

  @override
  Future<Result<List<DeviceBrand>>> getAllDeviceBrands([String? name]) {
    return _deviceBrandService.getAllDeviceBrands(name);
  }
}
