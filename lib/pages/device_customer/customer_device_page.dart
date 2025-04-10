import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/device_customer/customer_device_infos_widget.dart';
import 'package:flutter_workshop_front/pages/device_customer/device_tabs_widget.dart';
import 'package:flutter_workshop_front/pages/device_customer/inherited_device_customer_controller.dart';
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
    deviceCustomerPageController.getDeviceCustomer(widget.deviceId);
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
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
            // TODO: fix scroll
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomerDeviceInfosWidget(
                    deviceCustomerPageController: deviceCustomerPageController,
                    width: width,
                  ),
                  const SizedBox(height: 16),
                  DeviceTabsWidget(width: width),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
