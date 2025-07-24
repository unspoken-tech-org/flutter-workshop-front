import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/controller/device_register_controller.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/widgets/device_register_form.dart';
import 'package:flutter_workshop_front/services/color/color_service.dart';
import 'package:flutter_workshop_front/services/customer/customer_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_customer_service.dart';
import 'package:flutter_workshop_front/services/technician/technician_service.dart';
import 'package:flutter_workshop_front/services/types_brands_models/type_brand_model_service.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';
import 'package:provider/provider.dart';

class DeviceRegisterPage extends StatelessWidget {
  static const route = 'device-register';

  final int? customerId;
  final String? customerName;

  const DeviceRegisterPage({
    super.key,
    this.customerId,
    this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      lazy: false,
      create: (context) {
        return DeviceRegisterController(
          TypeBrandModelService(),
          ColorService(),
          DeviceCustomerService(),
          TechnicianService(),
          CustomerService(),
        )..init(customerId, customerName);
      },
      child: WsScaffold(
        child: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: 800,
              child: Selector<DeviceRegisterController, bool>(
                selector: (context, controller) => controller.isLoading,
                builder: (context, isLoading, child) {
                  if (isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return const DeviceRegisterForm();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
