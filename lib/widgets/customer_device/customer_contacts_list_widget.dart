import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_contact.dart';
import 'package:flutter_workshop_front/widgets/customer_device/contact_card.dart';
import 'package:flutter_workshop_front/widgets/shared/empty_list_widget.dart';

class CustomerContactsListWidget extends StatelessWidget {
  final List<CustomerContact> customerContacts;
  final VoidCallback onAddContact;
  final ScrollController scrollController;

  const CustomerContactsListWidget({
    super.key,
    required this.customerContacts,
    required this.onAddContact,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('contact_list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: TextButton.icon(
            onPressed: onAddContact,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 18,
              ),
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Contato'),
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
                padding: const EdgeInsets.all(8),
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
