import 'package:flutter_workshop_front/widgets/core/ui_message_listener.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/controller/device_register_controller.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/widgets/device_register_form.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/widgets/device_register_shimmer.dart';
import 'package:flutter_workshop_front/repositories/catalog/catalog_repository.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/repositories/device/device_repository.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';
import 'package:provider/provider.dart';

class DeviceRegisterPage extends StatelessWidget {
  static const route = 'device-register';

  final int? customerId;
  final String? customerName;

  const DeviceRegisterPage({super.key, this.customerId, this.customerName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      lazy: false,
      create: (context) {
        final controller = DeviceRegisterController(
          catalogRepository: context.read<CatalogRepository>(),
          deviceRepository: context.read<DeviceRepository>(),
          customerRepository: context.read<CustomerRepository>(),
        );
        unawaited(controller.init(customerId, customerName));
        return controller;
      },
      child: ProviderUiMessageListener<DeviceRegisterController>(
        child: WsScaffold(
          child: SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: 800,
                child: Selector<DeviceRegisterController, bool>(
                  selector: (context, controller) => controller.isLoading,
                  builder: (context, isLoading, child) {
                    if (isLoading) {
                      return const DeviceRegisterShimmer();
                    }

                    return const DeviceRegisterForm();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
