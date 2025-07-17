import 'package:flutter/material.dart';

class CustomerInfoFormField extends StatelessWidget {
  final int customerId;
  final String customerName;
  const CustomerInfoFormField(
      {super.key, required this.customerId, required this.customerName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: customerId.toString(),
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'ID do Cliente',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            initialValue: customerName,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Nome do Cliente',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
