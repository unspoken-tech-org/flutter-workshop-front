import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';
import 'package:flutter/material.dart';

class CustomerRegisterController extends ChangeNotifier {
  final CustomerRepository _customerRepository;

  CustomerRegisterController(this._customerRepository);

  bool isCreatingCustomer = false;

  Future<int?> createCustomer(InputCustomer newCustomer) async {
    try {
      isCreatingCustomer = true;
      notifyListeners();
      var customer = await _customerRepository.createCustomer(newCustomer);
      SnackBarUtil().showSuccess('Cliente cadastrado com sucesso');
      return customer.customerId;
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
      return null;
    } catch (e) {
      SnackBarUtil().showError('Erro ao cadastrar cliente');
      return null;
    } finally {
      isCreatingCustomer = false;
      notifyListeners();
    }
  }
}
