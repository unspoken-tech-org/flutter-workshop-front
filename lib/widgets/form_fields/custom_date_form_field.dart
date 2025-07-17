import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDateFormField extends StatelessWidget {
  final TextEditingController dateController;
  final BuildContext context;
  final void Function(String value) onSave;
  final String? Function(String? value)? validator;
  final String label;
  final String? value;

  const CustomDateFormField({
    super.key,
    required this.dateController,
    required this.context,
    required this.onSave,
    required this.label,
    this.validator,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: dateController,
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.blue.shade300, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      validator: validator,
      onSaved: (value) {
        onSave(value ?? '');
      },
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          dateController.text = DateFormat('dd/MM/yyyy').format(date);
        }
      },
    );
  }
}
