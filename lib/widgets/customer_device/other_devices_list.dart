import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/widgets/customer_device/customer_device_card.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/inherited_device_customer_controller.dart';

class OtherDevicesList extends StatelessWidget {
  const OtherDevicesList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceCustomerController.of(context);
    final deviceCustomer = controller.newDeviceCustomer.value;
    return ListView.separated(
      itemCount: deviceCustomer.otherDevices.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final device = deviceCustomer.otherDevices[index];
        return CustomerDeviceCard(
          device: device,
          onTap: (id) {
            controller.init(id);
          },
        );
      },
      separatorBuilder: (context, index) {
        return const SizedBox(height: 16);
      },
    );
  }
}
