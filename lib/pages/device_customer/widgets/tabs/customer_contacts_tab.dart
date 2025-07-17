import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/inherited_device_customer_controller.dart';
import 'package:flutter_workshop_front/pages/device_customer/widgets/customer_contacts_list_widget.dart';

class CustomerContactsTab extends StatefulWidget {
  const CustomerContactsTab({super.key});

  @override
  State<CustomerContactsTab> createState() => _CustomerContactsTabState();
}

class _CustomerContactsTabState extends State<CustomerContactsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceCustomerController.of(context);

    return ValueListenableBuilder(
      valueListenable: controller.deviceCustomer,
      builder: (context, value, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: CustomerContactsListWidget(
              scrollController: _scrollController,
              customerContacts:
                  controller.deviceCustomer.value.customerContacts,
            )),
          ],
        );
      },
    );
  }
}
