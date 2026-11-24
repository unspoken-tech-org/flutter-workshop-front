import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

class CustomerDetailController extends ChangeNotifier {
  final CustomerRepository _customerRepository;
  final SnackBarUtil _snackBarUtil = SnackBarUtil();

  CustomerDetailController(this._customerRepository);

  CustomerModel? _customer;
  CustomerModel? get customer => _customer;

  String? errorMessage;

  bool isLoading = false;

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
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      switch (await _customerRepository.getCustomer(customerId)) {
        case Ok(:final value):
          _customer = value;
        case Err(:final failure):
          final message = failure.messageOr(
            'Erro ao buscar cliente. Tente novamente.',
          );
          errorMessage = message;
          _snackBarUtil.showError(message);
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCustomer(int customerId) async {
    if (isLoading) return false;
    isLoading = true;
    notifyListeners();
    try {
      switch (await _customerRepository.updateCustomer(
        customerId,
        updatedCustomerData,
      )) {
        case Ok(:final value):
          _customer = value;
          _isEditing = false;
          _snackBarUtil.showSuccess('Cliente atualizado com sucesso');
          notifyListeners();
          return true;
        case Err(:final failure):
          _snackBarUtil.showError(
            failure.messageOr('Erro ao atualizar cliente. Tente novamente.'),
          );
          return false;
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
