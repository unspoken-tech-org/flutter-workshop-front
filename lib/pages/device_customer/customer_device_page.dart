import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/inherited_device_customer_controller.dart';
import 'package:flutter_workshop_front/pages/device_customer/widgets/customer_device_payments.dart';
import 'package:flutter_workshop_front/pages/device_customer/widgets/new_payment_widget.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';
import 'package:flutter_workshop_front/widgets/customer_device/customer_device_infos_widget.dart';
import 'package:flutter_workshop_front/widgets/customer_device/device_tabs_widget.dart';

class CustomerDevicePage extends StatefulWidget {
  static const route = 'device';
  final int deviceId;
  const CustomerDevicePage({super.key, required this.deviceId});

  @override
  State<CustomerDevicePage> createState() => _CustomerDevicePageState();
}

class _CustomerDevicePageState extends State<CustomerDevicePage>
    with SingleTickerProviderStateMixin {
  final DeviceCustomerPageController deviceCustomerPageController =
      DeviceCustomerPageController();
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    deviceCustomerPageController.init(widget.deviceId);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 330),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: -0.4,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    deviceCustomerPageController.isPaymentsWidgetVisible
        .addListener(_toggleNewPaymentWidget);
  }

  @override
  void dispose() {
    deviceCustomerPageController.isPaymentsWidgetVisible
        .removeListener(_toggleNewPaymentWidget);
    _animationController.dispose();
    super.dispose();
  }

  void _toggleNewPaymentWidget() {
    bool isNewPaymentVisible =
        deviceCustomerPageController.isPaymentsWidgetVisible.value;
    if (isNewPaymentVisible) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InheritedDeviceCustomerController(
      controller: deviceCustomerPageController,
      child: WsScaffold(
        backgroundColor: const Color(0xFFF5F5F5),
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
                        height: 550,
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
                      child: SizedBox(
                        height: 514,
                        child: Stack(
                          alignment: Alignment.bottomLeft,
                          children: [
                            Align(
                              alignment: Alignment.bottomRight,
                              child: AnimatedBuilder(
                                animation: _animation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                      MediaQuery.of(context).size.width *
                                          _animation.value,
                                      0,
                                    ),
                                    child: ValueListenableBuilder(
                                      valueListenable:
                                          deviceCustomerPageController
                                              .newPayment,
                                      builder: (context, payment, child) {
                                        return NewPaymentWidget(
                                          deviceId: widget.deviceId,
                                          isEditing: payment != null,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            const DeviceTabsWidget(),
                          ],
                        ),
                      ),
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
