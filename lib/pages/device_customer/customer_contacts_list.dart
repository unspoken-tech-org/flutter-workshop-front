import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/pages/device_customer/contact_card.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/device_customer/customer_device_text_field.dart';
import 'package:flutter_workshop_front/pages/device_customer/date_picker.dart';
import 'package:flutter_workshop_front/pages/device_customer/inherited_device_customer_controller.dart';
import 'package:flutter_workshop_front/utils/phone_utils.dart';

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

class AddContactWidget extends StatefulWidget {
  final int deviceId;
  final Function() onClose;
  final VoidCallback onSave;

  const AddContactWidget({
    super.key,
    required this.deviceId,
    required this.onClose,
    required this.onSave,
  });

  @override
  State<AddContactWidget> createState() => _AddContactWidgetState();
}

class _AddContactWidgetState extends State<AddContactWidget> {
  late InputCustomerContact inputCustomerContact;

  void _saveContact(
      DeviceCustomerPageController controller, InputCustomerContact input) {
    controller.createCustomerContact(input).then((value) {
      widget.onSave();
    });
  }

  @override
  void initState() {
    super.initState();
    inputCustomerContact = InputCustomerContact.empty(widget.deviceId);
  }

  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceCustomerController.of(context);
    var deviceCustomer = controller.newDeviceCustomer.value;
    var technicians = controller.technicians;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: widget.onClose,
          icon: const Icon(Icons.close, size: 18),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tipo de contato'),
                                const SizedBox(height: 8),
                                Container(
                                  width: 170,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  child: DropdownButton(
                                    value: inputCustomerContact.contactType,
                                    borderRadius: BorderRadius.circular(8),
                                    underline: Container(),
                                    isExpanded: true,
                                    items: InputCustomerContact.contactTypes
                                        .map((e) => DropdownMenuItem(
                                            value: e,
                                            child: Row(
                                              children: [
                                                const SizedBox(width: 8),
                                                Text(e),
                                              ],
                                            )))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        inputCustomerContact.contactType =
                                            value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text('Número de telefone'),
                                const SizedBox(height: 8),
                                Container(
                                  width: 170,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  child: DropdownButton<int?>(
                                    value: inputCustomerContact.phoneNumberId,
                                    borderRadius: BorderRadius.circular(8),
                                    underline: Container(),
                                    isExpanded: true,
                                    items: deviceCustomer.customerPhones
                                        .map(
                                          (e) => DropdownMenuItem<int>(
                                            value: e.id,
                                            child: Row(
                                              children: [
                                                const SizedBox(width: 8),
                                                Text(PhoneUtils.formatPhone(
                                                    e.number)),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged:
                                        inputCustomerContact.contactType !=
                                                'Pessoalmente'
                                            ? (value) {
                                                setState(() {
                                                  inputCustomerContact
                                                      .phoneNumberId = value;
                                                });
                                              }
                                            : null,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text('Status do contato'),
                                const SizedBox(height: 8),
                                Container(
                                  width: 170,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  child: DropdownButton(
                                    value: inputCustomerContact.contactStatus,
                                    borderRadius: BorderRadius.circular(8),
                                    underline: Container(),
                                    isExpanded: true,
                                    items: InputCustomerContact.contactStatuses
                                        .map((e) => DropdownMenuItem<String>(
                                            value: e,
                                            child: Row(
                                              children: [
                                                const SizedBox(width: 8),
                                                Text(e),
                                              ],
                                            )))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        inputCustomerContact.contactStatus =
                                            value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Contatante'),
                                const SizedBox(height: 8),
                                Container(
                                  width: 170,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  child: DropdownButton(
                                    value: inputCustomerContact.technicianId,
                                    borderRadius: BorderRadius.circular(8),
                                    underline: Container(),
                                    isExpanded: true,
                                    items: technicians
                                        .map((e) => DropdownMenuItem(
                                            value: e.id,
                                            child: Row(
                                              children: [
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(e.name,
                                                      overflow: TextOverflow
                                                          .ellipsis),
                                                ),
                                              ],
                                            )))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        inputCustomerContact.technicianId =
                                            value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text('Status do aparelho'),
                                const SizedBox(height: 8),
                                Container(
                                  width: 170,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  child: DropdownButton(
                                    value: inputCustomerContact.deviceStatus,
                                    borderRadius: BorderRadius.circular(8),
                                    underline: Container(),
                                    isExpanded: true,
                                    items: StatusEnum.values
                                        .map((e) => DropdownMenuItem(
                                            value: e.value,
                                            child: Row(
                                              children: [
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(e.name,
                                                      overflow: TextOverflow
                                                          .ellipsis),
                                                ),
                                              ],
                                            )))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        inputCustomerContact.deviceStatus =
                                            value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text('Data do contato'),
                                const SizedBox(height: 8),
                                DatePicker(
                                  onDateSelected: (date) {
                                    setState(() {
                                      inputCustomerContact.contactDate = date;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Dialogo'),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: CustomerDeviceTextField(
                                      initialValue:
                                          inputCustomerContact.message,
                                      expandHeight: true,
                                      onUpdate: (value) {
                                        setState(() {
                                          inputCustomerContact.message = value;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  inputCustomerContact =
                      InputCustomerContact.empty(widget.deviceId);
                });
              },
              child: const Text('Limpar'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                _saveContact(controller, inputCustomerContact);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.save),
              label: const Text('Salvar'),
            ),
          ],
        ),
      ],
    );
  }
}
