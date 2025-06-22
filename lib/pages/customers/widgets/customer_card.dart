import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/cpf_formatter.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/phone_number_formatter.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';

class CustomerCard extends StatelessWidget {
  final MinifiedCustomerModel customer;
  final Function(int) onTap;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String formatedPhone = PhoneNumberFormatter()
        .formatEditUpdate(
          TextEditingValue(text: customer.mainPhone),
          TextEditingValue(text: customer.mainPhone),
        )
        .text;
    String formatedCpf = CpfFormatter()
        .formatEditUpdate(
          TextEditingValue(text: customer.cpf),
          TextEditingValue(text: customer.cpf),
        )
        .text;
    return Card(
      child: InkWell(
        onTap: () => onTap(customer.customerId),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 130,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name.capitalizeAllWords,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.numbers, size: 16),
                    const SizedBox(width: 8),
                    Text('ID: ${customer.customerId}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 8),
                    Text('CPF: $formatedCpf'),
                  ],
                ),
                if (customer.email != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 16),
                      const SizedBox(width: 8),
                      Text('Email: ${customer.email}'),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16),
                    const SizedBox(width: 8),
                    Text('Telefone: $formatedPhone'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
