import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/date_time_extension.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_contact.dart';
import 'package:flutter_workshop_front/widgets/hoverable_card.dart';
import 'package:flutter_workshop_front/widgets/shared/status_cell.dart';

class ContactCard extends StatelessWidget {
  final CustomerContact contact;

  const ContactCard({
    super.key,
    required this.contact,
  });

  (String, Color, Color) _getStatus() {
    if (contact.hasMadeContact) {
      return ('Contatado', Colors.green, Colors.green.shade100);
    }
    return ('Pendente', Colors.red, Colors.red.shade100);
  }

  @override
  Widget build(BuildContext context) {
    final (statusText, statusColor, backgroundColor) = _getStatus();

    return HoverableCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Data: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                DateTime.tryParse(contact.lastContact)
                                        ?.formatDate() ??
                                    contact.lastContact,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline,
                                size: 16,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Tipo: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(contact.type.capitalizeAllWords),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.person_outline,
                                size: 16,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Técnico: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(contact.technicianName.capitalizeAllWords),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 100,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      contact.conversation!,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 8,
            children: [
              Chip(
                label: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: backgroundColor,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.transparent),
                ),
              ),
              StatusCell(status: contact.deviceStatus),
            ],
          ),
        ],
      ),
    );
  }
}
