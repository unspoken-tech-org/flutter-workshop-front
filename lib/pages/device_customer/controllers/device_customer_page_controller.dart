import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';
import 'package:flutter_workshop_front/models/customer_device/input_payment.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/services/customer_contact/customer_contact_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_customer_service.dart';
import 'package:flutter_workshop_front/services/payment/payment_service.dart';
import 'package:flutter_workshop_front/services/technician/technician_service.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

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
    await Future.wait([
      _getTechnicians(),
      _getCustomerDevice(deviceId, isNew: true),
    ]);
    isLoading.value = false;
  }

  Future<void> _getTechnicians() async {
    try {
      technicians = await _technicianService.getTechnicians();
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil().showError('Erro ao buscar técnicos. Tente novamente.');
    }
  }

  Future<void> _getCustomerDevice(int deviceId, {bool isNew = false}) async {
    try {
      final deviceCustomer =
          await _deviceCustomerService.getCustomerDeviceById(deviceId);
      if (isNew) {
        currentDeviceCustomer = ValueNotifier(deviceCustomer);
        newDeviceCustomer = ValueNotifier(deviceCustomer);
      } else {
        currentDeviceCustomer.value = deviceCustomer;
        newDeviceCustomer.value = deviceCustomer;
      }
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil().showError('Erro ao buscar dispositivo. Tente novamente.');
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
    try {
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
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil()
          .showError('Erro ao atualizar dispositivo. Tente novamente.');
    }
  }

  Future<void> createCustomerContact(
      InputCustomerContact customerContact) async {
    try {
      await _customerContactService.createCustomerContact(customerContact);

      if (newPayment.value != null && !newPayment.value!.isEmpty) {
        await _paymentService.createPayment(newPayment.value!);
        clearNewPayment();
      }
      await _getCustomerDevice(currentDeviceCustomer.value.deviceId);
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil().showError('Erro ao criar contato. Tente novamente.');
    }
  }

  void revertDeviceCustomer() {
    newDeviceCustomer.value = currentDeviceCustomer.value;
    customerDeviceState.value = CustomerDeviceEvent.revert;
    customerDeviceState.value = CustomerDeviceEvent.initial;
  }
}
