import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/core/ui/command.dart';
import 'package:flutter_workshop_front/core/ui/ui_message.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';

class CustomerRegisterController extends ChangeNotifier with UiMessageSource {
  final CustomerRepository _customerRepository;

  CustomerRegisterController(this._customerRepository) {
    create = Command<InputCustomer, CustomerModel>(
      _customerRepository.createCustomer,
    )..addListener(notifyListeners);
  }

  late final Command<InputCustomer, CustomerModel> create;

  bool get isCreatingCustomer => create.running;

  /// Devolve o id do cliente criado, ou `null` em falha (ou se já estava
  /// criando).
  Future<int?> createCustomer(InputCustomer newCustomer) async {
    switch (await create.execute(newCustomer)) {
      case null:
        return null;
      case Ok(:final value):
        emitSuccess('Cliente cadastrado com sucesso');
        return value.customerId;
      case Err(:final failure):
        emitFailure(failure, 'Erro ao cadastrar cliente');
        return null;
    }
  }

  @override
  void dispose() {
    create.dispose();
    super.dispose();
  }
}
