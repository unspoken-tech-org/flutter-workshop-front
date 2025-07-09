import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/device/controller/device_register_controller.dart';

class InheritedDeviceRegisterController extends InheritedWidget {
  final DeviceRegisterController controller;

  const InheritedDeviceRegisterController({
    super.key,
    required this.controller,
    required super.child,
  });

  static DeviceRegisterController of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<
        InheritedDeviceRegisterController>();
    assert(result != null,
        'Nenhum InheritedDeviceRegisterController encontrado no contexto');
    return result!.controller;
  }

  @override
  bool updateShouldNotify(
      covariant InheritedDeviceRegisterController oldWidget) {
    return oldWidget.controller != controller;
  }
}
