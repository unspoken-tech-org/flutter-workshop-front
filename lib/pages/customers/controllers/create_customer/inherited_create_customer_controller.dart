import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/customers/controllers/create_customer/customer_register_controller.dart';

class InheritedCreateCustomerController extends InheritedWidget {
  final CustomerRegisterController controller;

  const InheritedCreateCustomerController({
    super.key,
    required this.controller,
    required super.child,
  });

  static CustomerRegisterController of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<
        InheritedCreateCustomerController>();
    assert(result != null,
        'Nenhum InheritedCreateCustomerController encontrado no contexto');
    return result!.controller;
  }

  @override
  bool updateShouldNotify(
      covariant InheritedCreateCustomerController oldWidget) {
    return oldWidget.controller != controller;
  }
}
