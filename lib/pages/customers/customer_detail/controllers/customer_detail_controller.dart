import 'package:flutter/foundation.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

class CustomerDetailController {
  final CustomerRepository _customerRepository;

  final SnackBarUtil _snackBarUtil = SnackBarUtil();

  CustomerDetailController(this._customerRepository);

  final ValueNotifier<CustomerModel?> customer = ValueNotifier(null);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  InputCustomer updatedCustomerData = InputCustomer.empty();

  Future<void> fetchCustomer(int customerId) async {
    isLoading.value = true;
    try {
      final result = await _customerRepository.getCustomer(customerId);
      customer.value = result;
    } catch (e) {
      _snackBarUtil.showError('Erro ao buscar cliente: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateCustomer(int customerId) async {
    try {
      final result = await _customerRepository.updateCustomer(
          customerId, updatedCustomerData);
      customer.value = result;
      _snackBarUtil.showSuccess('Cliente atualizado com sucesso');
      return true;
    } on RequisitionException catch (e) {
      _snackBarUtil.showError(e.message);
      return false;
    } catch (e) {
      _snackBarUtil.showError('Erro ao atualizar cliente. Tente novamente.');
      return false;
    }
  }
}
