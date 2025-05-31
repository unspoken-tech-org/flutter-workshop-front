import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/widgets/customer_device/contact_card.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/widgets/customer_device/customer_device_text_field.dart';
import 'package:flutter_workshop_front/widgets/customer_device/date_picker.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/inherited_device_customer_controller.dart';
import 'package:flutter_workshop_front/utils/phone_utils.dart';
import 'package:flutter_workshop_front/widgets/shared/custom_dropdown_widget.dart';

class CustomerContactsList extends StatefulWidget {
  const CustomerContactsList({super.key});

  @override
  State<CustomerContactsList> createState() => _CustomerContactsListState();
}

class _CustomerContactsListState extends State<CustomerContactsList> {
  final ScrollController _scrollController = ScrollController();
  bool isAddContact = false;

  void _toggleAddContact() {
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
                        onClose: _toggleAddContact,
                        onSave: _toggleAddContact,
                      )
                    : Column(
                        key: const ValueKey('contact_list'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton.icon(
                            onPressed: _toggleAddContact,
                            icon: const Icon(Icons.add),
                            label: const Text('Adicionar Contato'),
                          ),
                          Expanded(
                            child: Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: true,
                              child: ListView.separated(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(8),
                                itemBuilder: (context, index) {
                                  return ContactCard(
                                    contact:
                                        deviceCustomer.customerContacts[index],
                                  );
                                },
                                separatorBuilder: (context, index) {
                                  return const SizedBox(height: 8);
                                },
                                itemCount:
                                    deviceCustomer.customerContacts.length,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
