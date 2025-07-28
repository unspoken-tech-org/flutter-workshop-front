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

class DeviceCustomerPageController extends ChangeNotifier {
  final DeviceCustomerService _deviceCustomerService = DeviceCustomerService();
  final TechnicianService _technicianService = TechnicianService();
  final CustomerContactService _customerContactService =
      CustomerContactService();
  final PaymentService _paymentService = PaymentService();

  late DeviceCustomer deviceCustomer;
  late List<Technician> technicians;

  bool isLoading = false;

  Future<void> init(int deviceId) async {
    isLoading = true;
    notifyListeners();
    await Future.wait([
      _getTechnicians(),
      _getCustomerDevice(deviceId, isNew: true),
    ]);
    isLoading = false;
    notifyListeners();
  }

  Future<void> _getTechnicians() async {
    try {
      technicians = await _technicianService.getTechnicians();
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil().showError('Erro ao buscar técnicos. Tente novamente.');
    } finally {
      notifyListeners();
    }
  }

  Future<void> _getCustomerDevice(int deviceId, {bool isNew = false}) async {
    try {
      final deviceCustomer =
          await _deviceCustomerService.getCustomerDeviceById(deviceId);
      this.deviceCustomer = deviceCustomer;
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil().showError('Erro ao buscar dispositivo. Tente novamente.');
    } finally {
      notifyListeners();
    }
  }

  void updateNewDeviceCustomer(DeviceCustomer newDeviceCustomer) {
    deviceCustomer = newDeviceCustomer;
  }

  Future<void> updateDeviceHasUrgency(bool hasUrgency) async {
    try {
      StatusEnum actualStatus = deviceCustomer.deviceStatus;
      if ([StatusEnum.delivered, StatusEnum.disposed].contains(actualStatus)) {
        actualStatus = StatusEnum.newDevice;
      }
      final updatedDeviceCustomer = deviceCustomer.copyWith(
        hasUrgency: hasUrgency,
        deviceStatus: actualStatus,
      );
      final DeviceCustomer value = await _deviceCustomerService
          .updateDeviceCustomer(updatedDeviceCustomer);
      deviceCustomer = value;
      SnackBarUtil().showSuccess(
        'Urgencia do dispositivo atualizada com sucesso',
      );
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil().showError(
          'Erro ao atualizar urgência do dispositivo. Tente novamente.');
    } finally {
      notifyListeners();
    }
  }

  void updateDeviceCustomer() async {
    try {
      DeviceCustomer response =
          await _deviceCustomerService.updateDeviceCustomer(deviceCustomer);

      deviceCustomer = response;

      SnackBarUtil().showSuccess('Dispositivo atualizado com sucesso');
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil()
          .showError('Erro ao atualizar dispositivo. Tente novamente.');
    } finally {
      notifyListeners();
    }
  }

  Future<void> createCustomerContact(
      InputCustomerContact customerContact) async {
    try {
      await _customerContactService.createCustomerContact(customerContact);
      await _getCustomerDevice(deviceCustomer.deviceId);

      SnackBarUtil().showSuccess('Contato criado com sucesso');
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil().showError('Erro ao criar contato. Tente novamente.');
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateDeviceRevision(bool revision) async {
    try {
      StatusEnum actualStatus = deviceCustomer.deviceStatus;
      if ([StatusEnum.delivered, StatusEnum.disposed].contains(actualStatus)) {
        actualStatus = StatusEnum.newDevice;
      }
      final updatedDeviceCustomer = deviceCustomer.copyWith(
          revision: revision, deviceStatus: actualStatus);
      final DeviceCustomer value = await _deviceCustomerService
          .updateDeviceCustomer(updatedDeviceCustomer);
      deviceCustomer = value;
      SnackBarUtil()
          .showSuccess('Revisão do dispositivo atualizada com sucesso');
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil().showError(
          'Erro ao atualizar revisão do dispositivo. Tente novamente.');
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateDeviceStatus(StatusEnum status) async {
    try {
      bool isUrgency = deviceCustomer.hasUrgency;
      bool isRevision = deviceCustomer.revision;
      if ([StatusEnum.delivered, StatusEnum.disposed].contains(status)) {
        isUrgency = false;
        isRevision = false;
      }
      final updatedDeviceCustomer = deviceCustomer.copyWith(
        deviceStatus: status,
        hasUrgency: isUrgency,
        revision: isRevision,
      );
      final DeviceCustomer value = await _deviceCustomerService
          .updateDeviceCustomer(updatedDeviceCustomer);
      deviceCustomer = value;
      SnackBarUtil()
          .showSuccess('Status do dispositivo atualizada com sucesso');
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil().showError(
          'Erro ao atualizar status do dispositivo. Tente novamente.');
    } finally {
      notifyListeners();
    }
  }

  Future<void> createCustomerDevicePayment(InputPayment payment) async {
    try {
      await _paymentService.createPayment(payment);
      deviceCustomer = deviceCustomer.copyWith(
        payments: [
          ...deviceCustomer.payments,
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
    } finally {
      notifyListeners();
    }
  }
}
