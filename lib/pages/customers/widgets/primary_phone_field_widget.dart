import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/phone_number_formatter.dart';

class PrimaryPhoneFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  const PrimaryPhoneFieldWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Telefone Principal',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.phone,
      inputFormatters: [PhoneNumberFormatter()],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, insira o telefone';
        }
        final int digitCount = value.replaceAll(RegExp(r'\D'), '').length;
        if (digitCount < 10) {
          return 'Telefone incompleto';
        }
        return null;
      },
    );
  }
}
