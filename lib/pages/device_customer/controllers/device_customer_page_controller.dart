import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/services/customer_contact/customer_contact_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_customer_service.dart';
import 'package:flutter_workshop_front/services/technician/technician_service.dart';

class DeviceCustomerPageController {
  final DeviceCustomerService _deviceCustomerService = DeviceCustomerService();
  final TechnicianService _technicianService = TechnicianService();
  final CustomerContactService _customerContactService =
      CustomerContactService();

  late ValueNotifier<DeviceCustomer> currentDeviceCustomer;
  late ValueNotifier<DeviceCustomer> newDeviceCustomer;
  late final List<Technician> technicians;

  ValueNotifier<bool> isLoading = ValueNotifier(false);

  Future<void> init(int deviceId) async {
    isLoading.value = true;
    technicians = await _technicianService.getTechnicians();
    await _getCustomerDevice(deviceId);
    isLoading.value = false;
  }

  Future<void> _getCustomerDevice(int deviceId) async {
    final deviceCustomer =
        await _deviceCustomerService.getCustomerDeviceById(deviceId);
    currentDeviceCustomer = ValueNotifier(deviceCustomer);
    newDeviceCustomer = ValueNotifier(deviceCustomer);
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

  Future<void> createCustomerContact(
      InputCustomerContact customerContact) async {
    await _customerContactService.createCustomerContact(customerContact);
    await _getCustomerDevice(currentDeviceCustomer.value.deviceId);
  }
}
