import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/repositories/all_devices/all_devices_repository.dart';
import 'package:flutter_workshop_front/services/device_data/device_brand_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_customer_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_type_service.dart';

class AllDevicesRemoteDataSource implements AllDevicesRepository {
  final DeviceCustomerService _deviceCustomerService = DeviceCustomerService();
  final DeviceTypeService _deviceTypeService = DeviceTypeService();
  final DeviceBrandService _deviceBrandService = DeviceBrandService();

  @override
  Future<List<DeviceDataTable>> getAllDevicesFiltering(
      [DeviceFilter? filter]) async {
    return _deviceCustomerService.getAllDevicesFiltering(filter);
  }

  @override
  Future<List<DeviceType>> getAllDeviceTypes([String? name]) async {
    return _deviceTypeService.getAllDeviceTypes(name);
  }

  @override
  Future<List<DeviceBrand>> getAllDeviceBrands([String? name]) async {
    return _deviceBrandService.getAllDeviceBrands(name);
  }
}
