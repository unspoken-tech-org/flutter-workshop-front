import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/date_time_extension.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_contact.dart';
import 'package:flutter_workshop_front/widgets/shared/status_cell.dart';

class ContactCard extends StatelessWidget {
  final CustomerContact contact;

  const ContactCard({
    super.key,
    required this.contact,
  });

  (String, Color) _getStatus() {
    if (contact.hasMadeContact) {
      return ('Contatado', Colors.green);
    }
    return ('Não contatado', Colors.red);
  }

  @override
  Widget build(BuildContext context) {
    final (statusText, statusColor) = _getStatus();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Data: ${DateTime.tryParse(contact.lastContact)?.formatDate() ?? contact.lastContact}',
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
                    color: Color.lerp(statusColor, Colors.black, 0.6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: statusColor,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide.none,
                ),
              ),
              StatusCell(status: contact.deviceStatus),
            ],
          ),
        ],
      ),
    );
    // StatusCell(status: contact.deviceStatus),
  }
}
