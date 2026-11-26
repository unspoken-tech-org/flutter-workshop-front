import 'package:flutter_workshop_front/core/di/app_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/core/state/safe_change_notifier_mixin.dart';
import 'package:flutter_workshop_front/core/ui/command.dart';
import 'package:flutter_workshop_front/core/ui/ui_message.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_device_payment.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';
import 'package:flutter_workshop_front/models/customer_device/input_payment.dart';
import 'package:flutter_workshop_front/models/device/device_input.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/models/types_brands_models/type_brand_model_input.dart';
import 'package:flutter_workshop_front/repositories/catalog/catalog_repository.dart';
import 'package:flutter_workshop_front/repositories/device/device_repository.dart';

class DeviceCustomerPageController extends ChangeNotifier
    with SafeChangeNotifierMixin, UiMessageSource {
  final DeviceRepository _deviceRepository;
  final CatalogRepository _catalogRepository;

  DeviceCustomerPageController({
    required DeviceRepository deviceRepository,
    required CatalogRepository catalogRepository,
  }) : _deviceRepository = deviceRepository,
       _catalogRepository = catalogRepository {
    load = Command<int, void>(_load);
    save = Command<DeviceCustomer, DeviceCustomer>(_save);
    setUrgency = Command<bool, DeviceCustomer>(
      (hasUrgency) => _quickAction(
        (id) => _deviceRepository.updateDeviceHasUrgency(id, hasUrgency),
      ),
    );
    setRevision = Command<bool, DeviceCustomer>(
      (revision) => _quickAction(
        (id) => _deviceRepository.updateDeviceRevision(id, revision),
      ),
    );
    setStatus = Command<StatusEnum, DeviceCustomer>(
      (status) => _quickAction(
        (id) => _deviceRepository.updateDeviceStatus(id, status),
      ),
    );
    createContact = Command<InputCustomerContact, void>(_createContact);
    updateContact = Command<(int, InputCustomerContact), void>(_updateContact);
    createPayment = Command<InputPayment, void>(_createPayment);
    openRevision = Command<DeviceCustomer, int>(_openRevision);
    for (final command in _commands) {
      command.addListener(notifyListeners);
    }
  }

  /// Uma flag (`running`) e um resultado por ação; nenhuma delas compartilha
  /// estado com as outras.
  late final Command<int, void> load;
  late final Command<DeviceCustomer, DeviceCustomer> save;
  late final Command<bool, DeviceCustomer> setUrgency;
  late final Command<bool, DeviceCustomer> setRevision;
  late final Command<StatusEnum, DeviceCustomer> setStatus;
  late final Command<InputCustomerContact, void> createContact;
  late final Command<(int, InputCustomerContact), void> updateContact;
  late final Command<InputPayment, void> createPayment;
  late final Command<DeviceCustomer, int> openRevision;

  List<ChangeNotifier> get _commands => [
    load,
    save,
    setUrgency,
    setRevision,
    setStatus,
    createContact,
    updateContact,
    createPayment,
    openRevision,
  ];

  /// Monta o controller com os repositórios do [AppDependencies].
  factory DeviceCustomerPageController.fromDependencies(AppDependencies deps) {
    return DeviceCustomerPageController(
      deviceRepository: deps.deviceRepository,
      catalogRepository: deps.catalogRepository,
    );
  }

  DeviceCustomer? deviceCustomer;
  List<Technician> technicians = [];
  String? loadError;

  bool get isLoading => load.running;

  /// Alguma ação rápida do cabeçalho (urgência, revisão ou status) rodando.
  bool get isUpdating =>
      setUrgency.running ||
      setRevision.running ||
      setStatus.running ||
      openRevision.running;

  /// Salvamento da edição. Separado de [isUpdating] para que uma ação rápida
  /// em andamento não descarte o save em silêncio.
  bool get isSaving => save.running;
  bool get isCreatingContact => createContact.running;
  bool get isEditingContact => updateContact.running;
  bool get isCreatingPayment => createPayment.running;

  Future<void> init(int deviceId) async {
    loadError = null;
    await load.execute(deviceId);
  }

  Future<Result<void>> _load(int deviceId) async {
    await Future.wait([
      _getTechnicians(),
      _getCustomerDevice(deviceId, isNew: true),
    ]);
    return const Ok<void>(null);
  }

  Future<void> _getTechnicians() async {
    try {
      switch (await _catalogRepository.getTechnicians()) {
        case Ok(:final value):
          technicians = value;
        case Err(:final failure):
          emitFailure(failure, 'Erro ao buscar técnicos. Tente novamente.');
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> _getCustomerDevice(int deviceId, {bool isNew = false}) async {
    try {
      switch (await _deviceRepository.getCustomerDeviceById(deviceId)) {
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
          emitFailure(failure, message);
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

  Future<Result<DeviceCustomer>> _quickAction(
    Future<Result<DeviceCustomer>> Function(int deviceId) call,
  ) async {
    final result = await call(deviceCustomer!.deviceId);
    if (result case Ok(:final value)) _applyQuickActionResponse(value);
    return result;
  }

  Future<void> _runQuickAction<A>(
    Command<A, DeviceCustomer> command,
    A argument, {
    required String success,
    required String failure,
  }) async {
    if (deviceCustomer == null || isUpdating || isSaving) return;
    switch (await command.execute(argument)) {
      case null:
        return;
      case Ok():
        emitSuccess(success);
      case Err(failure: final error):
        emitFailure(error, failure);
    }
  }

  static const closedOrderMessage =
      'OS encerrada: não é possível alterar urgência ou contatos.';
  static const closedOrderRevisionHint =
      ' Use "Abrir revisão" para abrir uma nova OS.';

  /// Motivo do bloqueio; a dica de revisão só vale para OS `ENTREGUE`.
  String get _closedOrderMessage => (deviceCustomer?.canOpenRevision ?? false)
      ? '$closedOrderMessage$closedOrderRevisionHint'
      : closedOrderMessage;

  Future<void> updateDeviceHasUrgency(bool hasUrgency) async {
    if (deviceCustomer?.isClosed ?? false) {
      emitError(_closedOrderMessage);
      return;
    }
    await _runQuickAction(
      setUrgency,
      hasUrgency,
      success: 'Urgencia do dispositivo atualizada com sucesso',
      failure: 'Erro ao atualizar urgência do dispositivo. Tente novamente.',
    );
  }

  Future<void> updateDeviceRevision(bool revision) => _runQuickAction(
    setRevision,
    revision,
    success: 'Revisão do dispositivo atualizada com sucesso',
    failure: 'Erro ao atualizar revisão do dispositivo. Tente novamente.',
  );

  Future<void> updateDeviceStatus(StatusEnum status) => _runQuickAction(
    setStatus,
    status,
    success: 'Status do dispositivo atualizado com sucesso',
    failure: 'Erro ao atualizar status do dispositivo. Tente novamente.',
  );

  Future<Result<DeviceCustomer>> _save(DeviceCustomer current) async {
    final result = await _deviceRepository.updateDeviceCustomer(current);
    if (result case Ok(:final value)) {
      deviceCustomer = value;
      _editingSnapshot = null;
    }
    return result;
  }

  /// Salva a edição e retorna `true` só quando o servidor confirma. Em erro,
  /// o chamador deve manter o modo de edição (e o rascunho).
  Future<bool> updateDeviceCustomer() async {
    final current = deviceCustomer;
    if (current == null) return false;
    switch (await save.execute(current)) {
      case null:
        return false;
      case Ok():
        emitSuccess('Dispositivo atualizado com sucesso');
        return true;
      case Err(:final failure):
        emitFailure(failure, 'Erro ao atualizar dispositivo. Tente novamente.');
        return false;
    }
  }

  /// Abre uma OS de revisão a partir da OS encerrada [origin] (plano §4.3):
  /// cria a OS nova com cliente, tipo/marca/modelo, cores e defeito da origem
  /// (`originOrderId` + `revision`) e, como a API anterior à Fase 2 ignora
  /// esses campos, marca a revisão na OS nova (aberta, então permitido).
  /// A OS de origem não é alterada. Devolve o id da OS nova.
  Future<Result<int>> _openRevision(DeviceCustomer origin) async {
    final created = await _deviceRepository.createDeviceCustomer(
      DeviceInput(
        customerId: origin.customerId,
        problem: origin.problem,
        typeBrandModel: TypeBrandModelInput(
          type: origin.typeName,
          brand: origin.brandName,
          model: origin.modelName,
        ),
        colors: origin.deviceColors,
        originOrderId: origin.deviceId,
        revision: true,
      ),
    );
    switch (created) {
      case Err(:final failure):
        return Err<int>(failure);
      case Ok(:final value):
        final newId = value.deviceId;
        if (await _deviceRepository.updateDeviceRevision(newId, true)
            case Err()) {
          emitError(
            'A OS nova foi criada, mas não foi possível marcá-la como '
            'revisão. Marque a revisão no detalhe dela.',
          );
        }
        return Ok<int>(newId);
    }
  }

  /// Retorna o id da OS de revisão criada, ou `null` (OS não `ENTREGUE`, ação
  /// em andamento ou erro, já publicado como mensagem).
  Future<int?> openRevisionOrder() async {
    final origin = deviceCustomer;
    if (origin == null || !origin.canOpenRevision || isUpdating || isSaving) {
      return null;
    }
    switch (await openRevision.execute(origin)) {
      case null:
        return null;
      case Ok(:final value):
        emitSuccess('Revisão aberta em uma nova OS');
        return value;
      case Err(:final failure):
        emitFailure(failure, 'Erro ao abrir a revisão. Tente novamente.');
        return null;
    }
  }

  Future<Result<void>> _createContact(InputCustomerContact contact) async {
    final result = await _deviceRepository.createCustomerContact(contact);
    if (result is Ok<void>) await _getCustomerDevice(deviceCustomer!.deviceId);
    return result;
  }

  Future<bool> createCustomerContact(
    InputCustomerContact customerContact,
  ) async {
    if (deviceCustomer == null) return false;
    if (deviceCustomer!.isClosed) {
      emitError(_closedOrderMessage);
      return false;
    }
    switch (await createContact.execute(customerContact)) {
      case null:
        return false;
      case Ok():
        emitSuccess('Contato criado com sucesso');
        return true;
      case Err(:final failure):
        emitFailure(failure, 'Erro ao criar contato. Tente novamente.');
        return false;
    }
  }

  Future<Result<void>> _updateContact((int, InputCustomerContact) args) async {
    final result = await _deviceRepository.updateCustomerContact(
      args.$1,
      args.$2,
    );
    if (result is Ok<void>) await _getCustomerDevice(deviceCustomer!.deviceId);
    return result;
  }

  Future<bool> updateCustomerContact(
    int contactId,
    InputCustomerContact customerContact,
  ) async {
    if (deviceCustomer == null) return false;
    if (deviceCustomer!.isClosed) {
      emitError(_closedOrderMessage);
      return false;
    }
    switch (await updateContact.execute((contactId, customerContact))) {
      case null:
        return false;
      case Ok():
        emitSuccess('Contato editado com sucesso');
        return true;
      case Err(:final failure):
        emitFailure(failure, 'Erro ao editar contato. Tente novamente.');
        return false;
    }
  }

  Future<Result<void>> _createPayment(InputPayment payment) async {
    final result = await _deviceRepository.createPayment(payment);
    final current = deviceCustomer;
    if (result is Ok<void> && current != null) {
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
    }
    return result;
  }

  /// Cria o pagamento e retorna `true` só quando o servidor confirma; em
  /// erro exibe a mensagem e retorna `false` (o diálogo permanece aberto).
  Future<bool> createCustomerDevicePayment(InputPayment payment) async {
    if (deviceCustomer == null) return false;
    switch (await createPayment.execute(payment)) {
      case null:
        return false;
      case Ok():
        emitSuccess('Pagamento criado com sucesso');
        return true;
      case Err(:final failure):
        emitFailure(failure, 'Erro ao criar pagamento. Tente novamente.');
        return false;
    }
  }

  @override
  void dispose() {
    for (final command in _commands) {
      command.dispose();
    }
    super.dispose();
  }
}
