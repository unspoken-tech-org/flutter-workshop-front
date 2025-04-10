import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/services/device_data/device_customer.dart';

class DeviceCustomerPageController {
  final DeviceCustomerService _deviceCustomerService = DeviceCustomerService();

  late ValueNotifier<DeviceCustomer> currentDeviceCustomer;
  late ValueNotifier<DeviceCustomer> newDeviceCustomer;

  ValueNotifier<bool> isLoading = ValueNotifier(false);

  Future<void> getDeviceCustomer(int deviceId) async {
    isLoading.value = true;
    final deviceCustomer =
        await _deviceCustomerService.getCustomerDeviceById(deviceId);
    currentDeviceCustomer = ValueNotifier(deviceCustomer);
    newDeviceCustomer = ValueNotifier(deviceCustomer);
    isLoading.value = false;
  }

  void updateNewDeviceCustomer(DeviceCustomer newDeviceCustomer) {
    this.newDeviceCustomer.value = newDeviceCustomer;
  }

  void saveDeviceCustomer() async {
    var currentDeviceCustomer = this.currentDeviceCustomer.value;
    var newDeviceCustomer = this.newDeviceCustomer.value;
    var updatedDeviceCustomer =
        currentDeviceCustomer.copyWithDeviceCustomer(newDeviceCustomer);
    this.currentDeviceCustomer.value = updatedDeviceCustomer;

    var value = await _deviceCustomerService
        .updateDeviceCustomer(updatedDeviceCustomer);
    this.currentDeviceCustomer.value = updatedDeviceCustomer;

    this.currentDeviceCustomer.value = value;
    this.newDeviceCustomer.value = value;
  }
}
