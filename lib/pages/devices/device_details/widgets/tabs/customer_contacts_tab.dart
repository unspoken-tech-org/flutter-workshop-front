import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/customer_contacts_list_widget.dart';
import 'package:provider/provider.dart';

class CustomerContactsTab extends StatefulWidget {
  const CustomerContactsTab({super.key});

  @override
  State<CustomerContactsTab> createState() => _CustomerContactsTabState();
}

class _CustomerContactsTabState extends State<CustomerContactsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Selector<DeviceCustomerPageController, DeviceCustomer>(
      selector: (context, controller) => controller.deviceCustomer,
      builder: (context, deviceCustomer, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: CustomerContactsListWidget(
              scrollController: _scrollController,
              customerContacts: deviceCustomer.customerContacts,
            )),
          ],
        );
      },
    );
  }
}
