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

class DeviceCustomerPageController {
  final DeviceCustomerService _deviceCustomerService = DeviceCustomerService();
  final TechnicianService _technicianService = TechnicianService();
  final CustomerContactService _customerContactService =
      CustomerContactService();
  final PaymentService _paymentService = PaymentService();

  late ValueNotifier<DeviceCustomer> deviceCustomer;
  late List<Technician> technicians;

  ValueNotifier<bool> isLoading = ValueNotifier(false);

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
        this.deviceCustomer = ValueNotifier(deviceCustomer);
      } else {
        this.deviceCustomer.value = deviceCustomer;
      }
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil().showError('Erro ao buscar dispositivo. Tente novamente.');
    }
  }

  void updateNewDeviceCustomer(DeviceCustomer newDeviceCustomer) {
    deviceCustomer.value = newDeviceCustomer;
  }

  Future<void> updateDeviceHasUrgency(bool hasUrgency) async {
    try {
      final updatedDeviceCustomer =
          deviceCustomer.value.copyWith(hasUrgency: hasUrgency);
      final DeviceCustomer value = await _deviceCustomerService
          .updateDeviceCustomer(updatedDeviceCustomer);
      deviceCustomer.value = value;
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

  void updateDeviceCustomer() async {
    try {
      var newDeviceCustomer = deviceCustomer.value;
      var updatedDeviceCustomer =
          newDeviceCustomer.copyWithDeviceCustomer(newDeviceCustomer);

      DeviceCustomer value = await _deviceCustomerService
          .updateDeviceCustomer(updatedDeviceCustomer);

      deviceCustomer.value = value;

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

      await _getCustomerDevice(deviceCustomer.value.deviceId);
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil().showError('Erro ao criar contato. Tente novamente.');
    }
  }

  Future<void> updateDeviceRevision(bool revision) async {
    try {
      final updatedDeviceCustomer =
          deviceCustomer.value.copyWith(revision: revision);
      final DeviceCustomer value = await _deviceCustomerService
          .updateDeviceCustomer(updatedDeviceCustomer);
      deviceCustomer.value = value;
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
          deviceCustomer.value.copyWith(deviceStatus: status);
      final DeviceCustomer value = await _deviceCustomerService
          .updateDeviceCustomer(updatedDeviceCustomer);
      deviceCustomer.value = value;
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
      deviceCustomer.value = deviceCustomer.value.copyWith(
        payments: [
          ...deviceCustomer.value.payments,
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
