import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/controllers/customer_detail_controller.dart';

class InheritedCustomerDetailController extends InheritedWidget {
  final CustomerDetailController controller;

  const InheritedCustomerDetailController({
    super.key,
    required this.controller,
    required super.child,
  });

  static CustomerDetailController of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<
        InheritedCustomerDetailController>();
    assert(result != null,
        'Nenhum InheritedCustomerDetailController encontrado no contexto');
    return result!.controller;
  }

  @override
  bool updateShouldNotify(
      covariant InheritedCustomerDetailController oldWidget) {
    return oldWidget.controller != controller;
  }
}
