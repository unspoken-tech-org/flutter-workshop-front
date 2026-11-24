import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/core/state/safe_change_notifier_mixin.dart';
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

class DeviceCustomerPageController extends ChangeNotifier
    with SafeChangeNotifierMixin {
  final DeviceCustomerService _deviceCustomerService;
  final TechnicianService _technicianService;
  final CustomerContactService _customerContactService;
  final PaymentService _paymentService;

  DeviceCustomerPageController({
    DeviceCustomerService? deviceCustomerService,
    TechnicianService? technicianService,
    CustomerContactService? customerContactService,
    PaymentService? paymentService,
  }) : _deviceCustomerService =
           deviceCustomerService ?? DeviceCustomerService(),
       _technicianService = technicianService ?? TechnicianService(),
       _customerContactService =
           customerContactService ?? CustomerContactService(),
       _paymentService = paymentService ?? PaymentService();

  DeviceCustomer? deviceCustomer;
  List<Technician> technicians = [];
  String? loadError;

  bool isLoading = false;

  /// Guard das ações rápidas do cabeçalho (urgência, revisão e status).
  bool isUpdating = false;

  /// Guard do salvamento da edição. Separado de [isUpdating] para que uma
  /// ação rápida em andamento não descarte o save em silêncio.
  bool isSaving = false;
  bool isCreatingContact = false;
  bool isEditingContact = false;
  bool isCreatingPayment = false;

  Future<void> init(int deviceId) async {
    isLoading = true;
    loadError = null;
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
      switch (await _technicianService.getTechnicians()) {
        case Ok(:final value):
          technicians = value;
        case Err(:final failure):
          SnackBarUtil().showError(
            failure.messageOr('Erro ao buscar técnicos. Tente novamente.'),
          );
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> _getCustomerDevice(int deviceId, {bool isNew = false}) async {
    try {
      switch (await _deviceCustomerService.getCustomerDeviceById(deviceId)) {
        case Ok(:final value):
          deviceCustomer = value;
          loadError = null;
        case Err(:final failure):
          final message = failure.messageOr(
            'Erro ao buscar dispositivo. Tente novamente.',
          );
          if (isNew) {
            loadError = message;
          }
          SnackBarUtil().showError(message);
      }
    } finally {
      notifyListeners();
    }
  }

  DeviceCustomer? _editingSnapshot;

  /// Retorna o aparelho com os valores persistidos no servidor, ignorando
  /// alterações de rascunho enquanto uma edição estiver em andamento.
  DeviceCustomer? get persistedDeviceCustomer =>
      _editingSnapshot ?? deviceCustomer;

  void updateNewDeviceCustomer(DeviceCustomer newDeviceCustomer) {
    deviceCustomer = newDeviceCustomer;
  }

  void onEditingStarted() {
    _editingSnapshot = deviceCustomer;
  }

  /// Aplica a resposta de uma ação rápida. Se houver edição em andamento,
  /// atualiza também o snapshot, para que cancelar não reverta o que o
  /// servidor já gravou (o rascunho fica nos campos do formulário).
  void _applyQuickActionResponse(DeviceCustomer value) {
    deviceCustomer = value;
    if (_editingSnapshot != null) {
      _editingSnapshot = value;
    }
  }

  void onEditingCancelled() {
    if (_editingSnapshot != null) {
      deviceCustomer = _editingSnapshot!;
      _editingSnapshot = null;
      notifyListeners();
    }
  }

  Future<void> updateDeviceHasUrgency(bool hasUrgency) async {
    final current = deviceCustomer;
    if (current == null || isUpdating || isSaving) return;
    isUpdating = true;
    notifyListeners();
    try {
      switch (await _deviceCustomerService.updateDeviceHasUrgency(
        current.deviceId,
        hasUrgency,
      )) {
        case Ok(:final value):
          _applyQuickActionResponse(value);
          SnackBarUtil().showSuccess(
            'Urgencia do dispositivo atualizada com sucesso',
          );
        case Err(:final failure):
          SnackBarUtil().showError(
            failure.messageOr(
              'Erro ao atualizar urgência do dispositivo. Tente novamente.',
            ),
          );
      }
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }

  /// Salva a edição e retorna `true` só quando o servidor confirma. Em erro,
  /// o chamador deve manter o modo de edição (e o rascunho).
  Future<bool> updateDeviceCustomer() async {
    final current = deviceCustomer;
    if (current == null || isSaving) return false;
    isSaving = true;
    notifyListeners();
    try {
      switch (await _deviceCustomerService.updateDeviceCustomer(current)) {
        case Ok(:final value):
          deviceCustomer = value;
          _editingSnapshot = null;
          SnackBarUtil().showSuccess('Dispositivo atualizado com sucesso');
          return true;
        case Err(:final failure):
          SnackBarUtil().showError(
            failure.messageOr(
              'Erro ao atualizar dispositivo. Tente novamente.',
            ),
          );
          return false;
      }
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> createCustomerContact(
    InputCustomerContact customerContact,
  ) async {
    final current = deviceCustomer;
    if (current == null || isCreatingContact) return false;
    isCreatingContact = true;
    notifyListeners();
    try {
      switch (await _customerContactService.createCustomerContact(
        customerContact,
      )) {
        case Ok():
          await _getCustomerDevice(current.deviceId);
          SnackBarUtil().showSuccess('Contato criado com sucesso');
          return true;
        case Err(:final failure):
          SnackBarUtil().showError(
            failure.messageOr('Erro ao criar contato. Tente novamente.'),
          );
          return false;
      }
    } finally {
      isCreatingContact = false;
      notifyListeners();
    }
  }

  Future<bool> updateCustomerContact(
    int contactId,
    InputCustomerContact customerContact,
  ) async {
    final current = deviceCustomer;
    if (current == null || isEditingContact) return false;
    isEditingContact = true;
    notifyListeners();
    try {
      switch (await _customerContactService.updateCustomerContact(
        contactId,
        customerContact,
      )) {
        case Ok():
          await _getCustomerDevice(current.deviceId);
          SnackBarUtil().showSuccess('Contato editado com sucesso');
          return true;
        case Err(:final failure):
          SnackBarUtil().showError(
            failure.messageOr('Erro ao editar contato. Tente novamente.'),
          );
          return false;
      }
    } finally {
      isEditingContact = false;
      notifyListeners();
    }
  }

  Future<void> updateDeviceRevision(bool revision) async {
    final current = deviceCustomer;
    if (current == null || isUpdating || isSaving) return;
    isUpdating = true;
    notifyListeners();
    try {
      switch (await _deviceCustomerService.updateDeviceRevision(
        current.deviceId,
        revision,
      )) {
        case Ok(:final value):
          _applyQuickActionResponse(value);
          SnackBarUtil().showSuccess(
            'Revisão do dispositivo atualizada com sucesso',
          );
        case Err(:final failure):
          SnackBarUtil().showError(
            failure.messageOr(
              'Erro ao atualizar revisão do dispositivo. Tente novamente.',
            ),
          );
      }
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> updateDeviceStatus(StatusEnum status) async {
    final current = deviceCustomer;
    if (current == null || isUpdating || isSaving) return;
    isUpdating = true;
    notifyListeners();
    try {
      switch (await _deviceCustomerService.updateDeviceStatus(
        current.deviceId,
        status,
      )) {
        case Ok(:final value):
          _applyQuickActionResponse(value);
          SnackBarUtil().showSuccess(
            'Status do dispositivo atualizado com sucesso',
          );
        case Err(:final failure):
          SnackBarUtil().showError(
            failure.messageOr(
              'Erro ao atualizar status do dispositivo. Tente novamente.',
            ),
          );
      }
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }

  /// Cria o pagamento e retorna `true` só quando o servidor confirma; em
  /// erro exibe a mensagem e retorna `false` (o diálogo permanece aberto).
  Future<bool> createCustomerDevicePayment(InputPayment payment) async {
    final current = deviceCustomer;
    if (current == null) return false;
    try {
      isCreatingPayment = true;
      notifyListeners();
      switch (await _paymentService.createPayment(payment)) {
        case Ok():
          final newPayment = CustomerDevicePayment(
            paymentId: 0,
            paymentValue: payment.value,
            paymentDate: payment.paymentDate!,
            paymentType: payment.paymentType!,
            category: payment.category!,
            receivedBy: payment.receivedBy,
          );
          deviceCustomer = current.copyWith(
            payments: [...current.payments, newPayment],
          );
          if (_editingSnapshot != null) {
            _editingSnapshot = _editingSnapshot!.copyWith(
              payments: [..._editingSnapshot!.payments, newPayment],
            );
          }
          SnackBarUtil().showSuccess('Pagamento criado com sucesso');
          return true;
        case Err(:final failure):
          SnackBarUtil().showError(
            failure.messageOr('Erro ao criar pagamento. Tente novamente.'),
          );
          return false;
      }
    } finally {
      isCreatingPayment = false;
      notifyListeners();
    }
  }
}
