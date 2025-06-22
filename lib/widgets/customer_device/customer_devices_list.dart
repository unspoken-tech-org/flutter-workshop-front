import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer_device/minified_customer_device.dart';
import 'package:flutter_workshop_front/widgets/customer_device/customer_device_card.dart';

class CustomerDevicesList extends StatelessWidget {
  final List<MinifiedCustomerDevice> customerDevices;
  final Function(int) onTap;
  const CustomerDevicesList({
    super.key,
    required this.customerDevices,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: customerDevices.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final device = customerDevices[index];
        return CustomerDeviceCard(
          device: device,
          onTap: (id) {
            onTap(id);
          },
        );
      },
      separatorBuilder: (context, index) {
        return const SizedBox(height: 16);
      },
    );
  }
}
