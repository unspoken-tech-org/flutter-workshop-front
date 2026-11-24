import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';
import 'package:flutter/material.dart';

class CustomerRegisterController extends ChangeNotifier {
  final CustomerRepository _customerRepository;

  CustomerRegisterController(this._customerRepository);

  bool isCreatingCustomer = false;

  Future<int?> createCustomer(InputCustomer newCustomer) async {
    if (isCreatingCustomer) return null;
    try {
      isCreatingCustomer = true;
      notifyListeners();
      switch (await _customerRepository.createCustomer(newCustomer)) {
        case Ok(:final value):
          SnackBarUtil().showSuccess('Cliente cadastrado com sucesso');
          return value.customerId;
        case Err(:final failure):
          SnackBarUtil().showError(
            failure.messageOr('Erro ao cadastrar cliente'),
          );
          return null;
      }
    } finally {
      isCreatingCustomer = false;
      notifyListeners();
    }
  }
}
