import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_contact.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/dialogs/add_contact_modal_dialog.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/contact_card.dart';
import 'package:flutter_workshop_front/widgets/shared/empty_list_widget.dart';
import 'package:provider/provider.dart';

class CustomerContactsListWidget extends StatelessWidget {
  final List<CustomerContact> customerContacts;
  final ScrollController scrollController;

  const CustomerContactsListWidget({
    super.key,
    required this.customerContacts,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.read<DeviceCustomerPageController>();
    return Column(
      key: const ValueKey('contact_list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => ChangeNotifierProvider.value(
                    value: controller,
                    child: const AddContactModalDialog(),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 18,
                  ),
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Contato'),
              ),
            ],
          ),
        ),
        Visibility(
          visible: customerContacts.isNotEmpty,
          replacement: const EmptyListWidget(
            message: 'Não foram encontrado contatos para este aparelho',
          ),
          child: Expanded(
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: ListView.separated(
                controller: scrollController,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                itemBuilder: (context, index) {
                  return ContactCard(
                    contact: customerContacts[index],
                  );
                },
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 16);
                },
                itemCount: customerContacts.length,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
