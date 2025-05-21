import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/inherited_device_customer_controller.dart';
import 'package:flutter_workshop_front/pages/device_customer/widgets/customer_device_payments.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';
import 'package:flutter_workshop_front/widgets/customer_device/customer_device_infos_widget.dart';
import 'package:flutter_workshop_front/widgets/customer_device/device_tabs_widget.dart';

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
        child: ValueListenableBuilder(
          valueListenable: deviceCustomerPageController.isLoading,
          builder: (context, value, child) {
            if (value) {
              return const Center(child: CircularProgressIndicator());
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 460,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 20,
                          children: [
                            CustomerDeviceInfosWidget(),
                            Expanded(child: CustomerDevicePayments()),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16).copyWith(
                        bottom: 16,
                      ),
                      child: const DeviceTabsWidget(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
