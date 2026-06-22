import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
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
    notifyListeners();
    try {
      final result = await _customerRepository.getCustomer(customerId);
      _customer = result;
    } catch (e) {
      _snackBarUtil.showError('Erro ao buscar cliente: $e');
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
      final result = await _customerRepository.updateCustomer(
        customerId,
        updatedCustomerData,
      );
      _customer = result;
      _isEditing = false;
      _snackBarUtil.showSuccess('Cliente atualizado com sucesso');
      notifyListeners();
      return true;
    } on RequisitionException catch (e) {
      _snackBarUtil.showError(e.message);
      return false;
    } catch (e) {
      _snackBarUtil.showError('Erro ao atualizar cliente. Tente novamente.');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
