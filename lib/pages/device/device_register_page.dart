import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/device/controller/device_register_controller.dart';
import 'package:flutter_workshop_front/pages/device/controller/inherited_device_register_controller.dart';
import 'package:flutter_workshop_front/pages/device/widgets/device_register_form.dart';
import 'package:flutter_workshop_front/services/color/color_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_customer_service.dart';
import 'package:flutter_workshop_front/services/technician/technician_service.dart';
import 'package:flutter_workshop_front/services/types_brands_models/type_brand_model_service.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';

class DeviceRegisterPage extends StatefulWidget {
  static const route = 'device-register';

  final int customerId;
  final String customerName;

  const DeviceRegisterPage({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<DeviceRegisterPage> createState() => _DeviceRegisterPageState();
}

class _DeviceRegisterPageState extends State<DeviceRegisterPage> {
  final DeviceRegisterController _controller = DeviceRegisterController(
    TypeBrandModelService(),
    ColorService(),
    DeviceCustomerService(),
    TechnicianService(),
  );

  @override
  void initState() {
    super.initState();
    _controller.init(widget.customerId, widget.customerName);
  }

  @override
  Widget build(BuildContext context) {
    return InheritedDeviceRegisterController(
      controller: _controller,
      child: WsScaffold(
        child: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: 800,
              child: ValueListenableBuilder(
                valueListenable: _controller.isLoading,
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
