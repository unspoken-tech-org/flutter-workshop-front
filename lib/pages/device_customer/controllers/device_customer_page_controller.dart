import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';
import 'package:flutter_workshop_front/models/customer_device/input_payment.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/services/customer_contact/customer_contact_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_customer_service.dart';
import 'package:flutter_workshop_front/services/payment/payment_service.dart';
import 'package:flutter_workshop_front/services/technician/technician_service.dart';

enum CustomerDeviceEvent {
  revert,
  initial,
}

class DeviceCustomerPageController {
  final DeviceCustomerService _deviceCustomerService = DeviceCustomerService();
  final TechnicianService _technicianService = TechnicianService();
  final CustomerContactService _customerContactService =
      CustomerContactService();
  final PaymentService _paymentService = PaymentService();

  late ValueNotifier<DeviceCustomer> currentDeviceCustomer;
  late ValueNotifier<DeviceCustomer> newDeviceCustomer;
  final ValueNotifier<InputPayment?> newPayment = ValueNotifier(null);

  late List<Technician> technicians;

  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<bool> isPaymentsWidgetVisible = ValueNotifier(false);
  ValueNotifier<CustomerDeviceEvent> customerDeviceState =
      ValueNotifier(CustomerDeviceEvent.initial);

  Future<void> init(int deviceId) async {
    isLoading.value = true;
    technicians = await _technicianService.getTechnicians();
    await _getCustomerDevice(deviceId, isNew: true);
    isLoading.value = false;
  }

  Future<void> _getCustomerDevice(int deviceId, {bool isNew = false}) async {
    final deviceCustomer =
        await _deviceCustomerService.getCustomerDeviceById(deviceId);
    if (isNew) {
      currentDeviceCustomer = ValueNotifier(deviceCustomer);
      newDeviceCustomer = ValueNotifier(deviceCustomer);
    } else {
      currentDeviceCustomer.value = deviceCustomer;
      newDeviceCustomer.value = deviceCustomer;
    }
  }

  void updateNewDeviceCustomer(DeviceCustomer newDeviceCustomer) {
    this.newDeviceCustomer.value = newDeviceCustomer;
  }

  void saveNewPayment(InputPayment inputPayment) {
    newPayment.value = inputPayment;
  }

  void clearNewPayment() {
    newPayment.value = null;
  }

  void saveDeviceCustomer() async {
    var currentDeviceCustomer = this.currentDeviceCustomer.value;
    var newDeviceCustomer = this.newDeviceCustomer.value;
    var updatedDeviceCustomer =
        currentDeviceCustomer.copyWithDeviceCustomer(newDeviceCustomer);
    this.currentDeviceCustomer.value = updatedDeviceCustomer;

    DeviceCustomer value = await _deviceCustomerService
        .updateDeviceCustomer(updatedDeviceCustomer);

    this.currentDeviceCustomer.value = updatedDeviceCustomer;
    this.currentDeviceCustomer.value = value;
    this.newDeviceCustomer.value = value;
  }

  Future<void> createCustomerContact(
      InputCustomerContact customerContact) async {
    await _customerContactService.createCustomerContact(customerContact);

    if (newPayment.value != null && !newPayment.value!.isEmpty) {
      await _paymentService.createPayment(newPayment.value!);
      clearNewPayment();
    }
    await _getCustomerDevice(currentDeviceCustomer.value.deviceId);
  }

  void revertDeviceCustomer() {
    newDeviceCustomer.value = currentDeviceCustomer.value;
    customerDeviceState.value = CustomerDeviceEvent.revert;
    customerDeviceState.value = CustomerDeviceEvent.initial;
  }
}
