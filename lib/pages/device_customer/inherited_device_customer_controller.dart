import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/device_customer_page_controller.dart';

class InheritedDeviceCustomerController extends InheritedWidget {
  final DeviceCustomerPageController controller;

  const InheritedDeviceCustomerController({
    super.key,
    required this.controller,
    required super.child,
  });

  static DeviceCustomerPageController of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<
        InheritedDeviceCustomerController>();
    assert(result != null,
        'Nenhum InheritedDeviceCustomerController encontrado no contexto');
    return result!.controller;
  }

  @override
  bool updateShouldNotify(InheritedDeviceCustomerController oldWidget) {
    return controller != oldWidget.controller;
  }
}
