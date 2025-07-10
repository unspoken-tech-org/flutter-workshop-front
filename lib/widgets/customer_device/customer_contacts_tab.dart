import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/inherited_device_customer_controller.dart';
import 'package:flutter_workshop_front/widgets/customer_device/add_contact_widget.dart';
import 'package:flutter_workshop_front/widgets/customer_device/customer_contacts_list_widget.dart';

class CustomerContactsTab extends StatefulWidget {
  const CustomerContactsTab({super.key});

  @override
  State<CustomerContactsTab> createState() => _CustomerContactsTabState();
}

class _CustomerContactsTabState extends State<CustomerContactsTab> {
  final ScrollController _scrollController = ScrollController();
  bool isAddContact = false;

  void _toggleAddContact(DeviceCustomerPageController controller) {
    controller.clearNewPayment();
    setState(() {
      isAddContact = !isAddContact;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceCustomerController.of(context);

    return ValueListenableBuilder(
      valueListenable: controller.newDeviceCustomer,
      builder: (context, value, child) {
        var deviceCustomer = value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-1.0, 0.0),
                      end: const Offset(0.0, 0.0),
                    ).animate(animation),
                    child: child,
                  );
                },
                child: isAddContact
                    ? AddContactWidget(
                        deviceId: deviceCustomer.deviceId,
                        onClose: () => _toggleAddContact(controller),
                        onSave: () => _toggleAddContact(controller),
                      )
                    : CustomerContactsListWidget(
                        scrollController: _scrollController,
                        customerContacts:
                            controller.newDeviceCustomer.value.customerContacts,
                        onAddContact: () => _toggleAddContact(controller),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
