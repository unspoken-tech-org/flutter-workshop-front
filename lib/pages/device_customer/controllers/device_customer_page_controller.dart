import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_device_payment.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';
import 'package:flutter_workshop_front/models/customer_device/input_payment.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/services/customer_contact/customer_contact_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_customer_service.dart';
import 'package:flutter_workshop_front/services/payment/payment_service.dart';
import 'package:flutter_workshop_front/services/technician/technician_service.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';
import 'package:intl/intl.dart';

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

  late DeviceCustomer currentDeviceCustomer;
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
        currentDeviceCustomer = deviceCustomer;
        newDeviceCustomer = ValueNotifier(deviceCustomer);
      } else {
        currentDeviceCustomer = deviceCustomer;
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

  Future<void> updateDeviceHasUrgency(bool hasUrgency) async {
    try {
      final updatedDeviceCustomer =
          newDeviceCustomer.value.copyWith(hasUrgency: hasUrgency);
      final DeviceCustomer value = await _deviceCustomerService
          .updateDeviceCustomer(updatedDeviceCustomer);
      newDeviceCustomer.value = value;
      currentDeviceCustomer = value;
      SnackBarUtil().showSuccess(
        'Urgencia do dispositivo atualizada com sucesso',
      );
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil().showError(
          'Erro ao atualizar urgência do dispositivo. Tente novamente.');
    }
  }

  void saveNewPayment(InputPayment inputPayment) {
    newPayment.value = inputPayment;
  }

  void clearNewPayment() {
    newPayment.value = null;
  }

  void updateDeviceCustomer() async {
    try {
      var currentDeviceCustomer = this.currentDeviceCustomer;
      var newDeviceCustomer = this.newDeviceCustomer.value;
      var updatedDeviceCustomer =
          currentDeviceCustomer.copyWithDeviceCustomer(newDeviceCustomer);
      this.currentDeviceCustomer = updatedDeviceCustomer;

      DeviceCustomer value = await _deviceCustomerService
          .updateDeviceCustomer(updatedDeviceCustomer);

      this.currentDeviceCustomer = updatedDeviceCustomer;
      this.currentDeviceCustomer = value;
      this.newDeviceCustomer.value = value;

      SnackBarUtil().showSuccess('Dispositivo atualizado com sucesso');
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
      await _getCustomerDevice(currentDeviceCustomer.deviceId);
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil().showError('Erro ao criar contato. Tente novamente.');
    }
  }

  void revertDeviceCustomer() {
    newDeviceCustomer.value = currentDeviceCustomer;
    customerDeviceState.value = CustomerDeviceEvent.revert;
    customerDeviceState.value = CustomerDeviceEvent.initial;
  }

  Future<void> updateDeviceRevision(bool revision) async {
    try {
      final updatedDeviceCustomer =
          newDeviceCustomer.value.copyWith(revision: revision);
      final DeviceCustomer value = await _deviceCustomerService
          .updateDeviceCustomer(updatedDeviceCustomer);
      newDeviceCustomer.value = value;
      currentDeviceCustomer = value;
      SnackBarUtil()
          .showSuccess('Revisão do dispositivo atualizada com sucesso');
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil().showError(
          'Erro ao atualizar revisão do dispositivo. Tente novamente.');
    }
  }

  Future<void> updateDeviceStatus(StatusEnum status) async {
    try {
      final updatedDeviceCustomer =
          newDeviceCustomer.value.copyWith(deviceStatus: status);
      final DeviceCustomer value = await _deviceCustomerService
          .updateDeviceCustomer(updatedDeviceCustomer);
      newDeviceCustomer.value = value;
      currentDeviceCustomer = value;
      SnackBarUtil()
          .showSuccess('Status do dispositivo atualizada com sucesso');
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil().showError(
          'Erro ao atualizar status do dispositivo. Tente novamente.');
    }
  }

  Future<void> createCustomerDevicePayment(InputPayment payment) async {
    try {
      await _paymentService.createPayment(payment);
      newDeviceCustomer.value = newDeviceCustomer.value.copyWith(
        payments: [
          ...newDeviceCustomer.value.payments,
          CustomerDevicePayment(
            paymentId: 0,
            paymentValue: payment.value,
            paymentDate: DateFormat('dd/MM/yyyy').format(payment.paymentDate!),
            paymentType: payment.paymentType!,
          ),
        ],
      );
      SnackBarUtil().showSuccess('Pagamento criado com sucesso');
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
      rethrow;
    } catch (e) {
      SnackBarUtil().showError('Erro ao criar pagamento. Tente novamente.');
      rethrow;
    }
  }
}
