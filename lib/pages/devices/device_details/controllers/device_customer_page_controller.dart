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
  bool isUpdating = false;
  bool isCreatingContact = false;
  bool isEditingContact = false;
  bool isCreatingPayment = false;

  Future<void> init(int deviceId) async {
    isLoading = true;
    notifyListeners();
    try {
      await Future.wait([
        _getTechnicians(),
        _getCustomerDevice(deviceId, isNew: true),
      ]);
    } finally {
      isLoading = false;
      notifyListeners();
    }
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
      final deviceCustomer = await _deviceCustomerService.getCustomerDeviceById(
        deviceId,
      );
      this.deviceCustomer = deviceCustomer;
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil().showError('Erro ao buscar dispositivo. Tente novamente.');
    } finally {
      notifyListeners();
    }
  }

  DeviceCustomer? _editingSnapshot;

  void updateNewDeviceCustomer(DeviceCustomer newDeviceCustomer) {
    deviceCustomer = newDeviceCustomer;
  }

  void onEditingStarted() {
    _editingSnapshot = deviceCustomer;
  }

  void onEditingCancelled() {
    if (_editingSnapshot != null) {
      deviceCustomer = _editingSnapshot!;
      _editingSnapshot = null;
      notifyListeners();
    }
  }

  Future<void> updateDeviceHasUrgency(bool hasUrgency) async {
    if (isUpdating) return;
    isUpdating = true;
    notifyListeners();
    try {
      final DeviceCustomer value = await _deviceCustomerService
          .updateDeviceHasUrgency(deviceCustomer.deviceId, hasUrgency);
      deviceCustomer = value;
      SnackBarUtil().showSuccess(
        'Urgencia do dispositivo atualizada com sucesso',
      );
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil().showError(
        'Erro ao atualizar urgência do dispositivo. Tente novamente.',
      );
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> updateDeviceCustomer() async {
    if (isUpdating) return;
    isUpdating = true;
    notifyListeners();
    try {
      DeviceCustomer response = await _deviceCustomerService
          .updateDeviceCustomer(deviceCustomer);
      deviceCustomer = response;
      SnackBarUtil().showSuccess('Dispositivo atualizado com sucesso');
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil().showError(
        'Erro ao atualizar dispositivo. Tente novamente.',
      );
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> createCustomerContact(
    InputCustomerContact customerContact,
  ) async {
    if (isCreatingContact) return;
    isCreatingContact = true;
    notifyListeners();
    try {
      await _customerContactService.createCustomerContact(customerContact);
      await _getCustomerDevice(deviceCustomer.deviceId);

      SnackBarUtil().showSuccess('Contato criado com sucesso');
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil().showError('Erro ao criar contato. Tente novamente.');
    } finally {
      isCreatingContact = false;
      notifyListeners();
    }
  }

  Future<void> updateCustomerContact(
    int contactId,
    InputCustomerContact customerContact,
  ) async {
    if (isEditingContact) return;
    isEditingContact = true;
    notifyListeners();
    try {
      await _customerContactService.updateCustomerContact(
        contactId,
        customerContact,
      );
      await _getCustomerDevice(deviceCustomer.deviceId);

      SnackBarUtil().showSuccess('Contato editado com sucesso');
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil().showError('Erro ao editar contato. Tente novamente.');
    } finally {
      isEditingContact = false;
      notifyListeners();
    }
  }

  Future<void> updateDeviceRevision(bool revision) async {
    if (isUpdating) return;
    isUpdating = true;
    notifyListeners();
    try {
      final DeviceCustomer value = await _deviceCustomerService
          .updateDeviceRevision(deviceCustomer.deviceId, revision);
      deviceCustomer = value;
      SnackBarUtil().showSuccess(
        'Revisão do dispositivo atualizada com sucesso',
      );
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil().showError(
        'Erro ao atualizar revisão do dispositivo. Tente novamente.',
      );
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> updateDeviceStatus(StatusEnum status) async {
    if (isUpdating) return;
    isUpdating = true;
    notifyListeners();
    try {
      final DeviceCustomer value = await _deviceCustomerService
          .updateDeviceStatus(deviceCustomer.deviceId, status);
      deviceCustomer = value;
      SnackBarUtil().showSuccess(
        'Status do dispositivo atualizado com sucesso',
      );
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
    } catch (e) {
      SnackBarUtil().showError(
        'Erro ao atualizar status do dispositivo. Tente novamente.',
      );
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> createCustomerDevicePayment(InputPayment payment) async {
    try {
      isCreatingPayment = true;
      notifyListeners();
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
      isCreatingPayment = false;
      notifyListeners();
    }
  }
}
