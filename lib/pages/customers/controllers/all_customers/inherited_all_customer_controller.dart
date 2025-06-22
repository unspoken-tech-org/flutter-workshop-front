import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/customers/controllers/all_customers/all_customer_controller.dart';

class InheritedAllCustomerController
    extends InheritedNotifier<AllCustomerController> {
  const InheritedAllCustomerController({
    super.key,
    required AllCustomerController controller,
    required super.child,
  }) : super(notifier: controller);

  static AllCustomerController of(BuildContext context) {
    final inheritedWidget = context
        .dependOnInheritedWidgetOfExactType<InheritedAllCustomerController>();
    if (inheritedWidget == null) {
      throw Exception('InheritedAllCustomerController not found');
    }
    return inheritedWidget.notifier!;
  }
}
