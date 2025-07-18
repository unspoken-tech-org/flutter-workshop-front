import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_text_field.dart';

class CustomerInfos extends StatelessWidget {
  final int customerId;
  final String customerName;
  const CustomerInfos(
      {super.key, required this.customerId, required this.customerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        spacing: 16,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline),
              SizedBox(width: 16),
              Text(
                'Informações do Cliente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Row(
            spacing: 16,
            children: [
              Expanded(
                child: CustomTextField(
                  headerLabel: 'ID do Cliente',
                  value: customerId.toString(),
                  readOnly: true,
                ),
              ),
              Expanded(
                child: CustomTextField(
                  headerLabel: 'Nome do Cliente',
                  value: customerName,
                  readOnly: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
