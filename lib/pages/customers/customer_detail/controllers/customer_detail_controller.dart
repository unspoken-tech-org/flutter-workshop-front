import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/core/ui/command.dart';
import 'package:flutter_workshop_front/core/ui/ui_message.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';

class CustomerDetailController extends ChangeNotifier with UiMessageSource {
  final CustomerRepository _customerRepository;

  CustomerDetailController(this._customerRepository) {
    fetch = Command<int, CustomerModel>(_customerRepository.getCustomer)
      ..addListener(notifyListeners);
    update = Command<int, CustomerModel>(
      (customerId) =>
          _customerRepository.updateCustomer(customerId, updatedCustomerData),
    )..addListener(notifyListeners);
  }

  /// Busca do cliente e salvamento da edição, cada um com a sua flag.
  late final Command<int, CustomerModel> fetch;
  late final Command<int, CustomerModel> update;

  CustomerModel? _customer;
  CustomerModel? get customer => _customer;

  String? errorMessage;

  /// Guarda comum: não busca nem salva enquanto a outra ação roda.
  bool get isLoading => fetch.running || update.running;

  bool _isEditing = false;
  bool get isEditing => _isEditing;

  InputCustomer updatedCustomerData = InputCustomer.empty();

  void setEditing(bool value) {
    if (_isEditing == value) return;
    _isEditing = value;
    notifyListeners();
  }

  Future<void> fetchCustomer(int customerId) async {
    if (isLoading) return;
    errorMessage = null;
    switch (await fetch.execute(customerId)) {
      case null:
        return;
      case Ok(:final value):
        _customer = value;
      case Err(:final failure):
        final message = failure.messageOr(
          'Erro ao buscar cliente. Tente novamente.',
        );
        errorMessage = message;
        emitError(message);
    }
    notifyListeners();
  }

  Future<bool> updateCustomer(int customerId) async {
    if (isLoading) return false;
    switch (await update.execute(customerId)) {
      case null:
        return false;
      case Ok(:final value):
        _customer = value;
        _isEditing = false;
        emitSuccess('Cliente atualizado com sucesso');
        notifyListeners();
        return true;
      case Err(:final failure):
        emitError(
          failure.messageOr('Erro ao atualizar cliente. Tente novamente.'),
        );
        return false;
    }
  }

  @override
  void dispose() {
    fetch.dispose();
    update.dispose();
    super.dispose();
  }
}
