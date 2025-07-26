import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/inherited_device_customer_controller.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/customer_device_infos_widget.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/customer_device_page_shimmer.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/customer_device_payments.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/tabs/device_tabs_widget.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';

class DeviceDetailsPage extends StatefulWidget {
  static const route = 'device-details';
  final int deviceId;
  const DeviceDetailsPage({super.key, required this.deviceId});

  @override
  State<DeviceDetailsPage> createState() => _DeviceDetailsPageState();
}

class _DeviceDetailsPageState extends State<DeviceDetailsPage> {
  final _scrollController = ScrollController();

  final DeviceCustomerPageController deviceCustomerPageController =
      DeviceCustomerPageController();

  @override
  void initState() {
    super.initState();
    deviceCustomerPageController.init(widget.deviceId);
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InheritedDeviceCustomerController(
      controller: deviceCustomerPageController,
      child: WsScaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.white70,
          onPressed: _scrollToTop,
          child: const Icon(Icons.arrow_upward, color: Colors.black87),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        child: ValueListenableBuilder(
          valueListenable: deviceCustomerPageController.isLoading,
          builder: (context, isLoading, child) {
            if (isLoading) return const CustomerDevicePageShimmer();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 1010,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 20,
                          children: [
                            Flexible(
                              flex: 2,
                              child: CustomerDeviceInfosWidget(),
                            ),
                            Flexible(
                              flex: 1,
                              child: CustomerDevicePayments(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 514,
                        child: DeviceTabsWidget(),
                      ),
                    ),
                    SizedBox(height: 16),
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
