import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_contact.dart';
import 'package:flutter_workshop_front/widgets/customer_device/customer_device_text_field.dart';
import 'package:flutter_workshop_front/utils/phone_utils.dart';
import 'package:flutter_workshop_front/widgets/shared/status_cell.dart';

class ContactCard extends StatelessWidget {
  final CustomerContact contact;

  const ContactCard({
    super.key,
    required this.contact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(50),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Id: ${contact.id}'),
              const SizedBox(height: 8),
              Text('Data: ${contact.lastContact}'),
              const SizedBox(height: 8),
              if (contact.phoneNumber != null) ...[
                Text('Número: ${PhoneUtils.formatPhone(contact.phoneNumber!)}'),
                const SizedBox(height: 8),
              ],
              Text('Tipo: ${contact.type.capitalizeAllWords}'),
              const SizedBox(height: 8),
              Text('Técnico: ${contact.technicianName.capitalizeAllWords}'),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(
                    label: Text(
                      contact.hasMadeContact ? 'Contatado' : 'Não contatado',
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor:
                        contact.hasMadeContact ? Colors.green : Colors.red,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color:
                            contact.hasMadeContact ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      StatusCell(status: contact.deviceStatus),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                child: CustomerDeviceTextField(
                  initialValue: contact.conversation,
                  enabled: false,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
