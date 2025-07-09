import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

class CustomerRegisterController {
  final CustomerRepository _customerRepository;

  CustomerRegisterController(this._customerRepository);

  Future<int?> createCustomer(InputCustomer newCustomer) async {
    try {
      var customer = await _customerRepository.createCustomer(newCustomer);
      SnackBarUtil().showSuccess('Cliente cadastrado com sucesso');
      return customer.customerId;
    } on RequisitionException catch (e) {
      SnackBarUtil().showError(e.message);
      return null;
    } catch (e) {
      SnackBarUtil().showError('Erro ao cadastrar cliente');
      return null;
    }
  }
}
