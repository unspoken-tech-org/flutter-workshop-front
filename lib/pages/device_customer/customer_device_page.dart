import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/widgets/customer_device/customer_device_infos_widget.dart';
import 'package:flutter_workshop_front/widgets/customer_device/device_tabs_widget.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/inherited_device_customer_controller.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';

class CustomerDevicePage extends StatefulWidget {
  final int deviceId;
  const CustomerDevicePage({super.key, required this.deviceId});

  @override
  State<CustomerDevicePage> createState() => _CustomerDevicePageState();
}

class _CustomerDevicePageState extends State<CustomerDevicePage> {
  final DeviceCustomerPageController deviceCustomerPageController =
      DeviceCustomerPageController();

  @override
  void initState() {
    super.initState();
    deviceCustomerPageController.init(widget.deviceId);
  }

  @override
  Widget build(BuildContext context) {
    return InheritedDeviceCustomerController(
      controller: deviceCustomerPageController,
      child: WsScaffold(
        alignment: Alignment.topLeft,
        child: ValueListenableBuilder(
          valueListenable: deviceCustomerPageController.isLoading,
          builder: (context, value, child) {
            if (value) {
              return const Center(child: CircularProgressIndicator());
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomerDeviceInfosWidget(),
                  SizedBox(height: 16),
                  DeviceTabsWidget(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
