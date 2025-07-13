import 'package:flutter/material.dart';

class CustomDropdownButtonFormField extends StatelessWidget {
  final String label;
  final List<String> items;
  final String? value;
  final void Function(String value) onSave;
  final String? Function(String? value)? validator;

  const CustomDropdownButtonFormField({
    super.key,
    required this.label,
    required this.items,
    required this.onSave,
    this.value,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
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
      dropdownColor: Colors.white,
      isExpanded: true,
      borderRadius: BorderRadius.circular(8),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: (value) {},
      validator: validator,
      onSaved: (value) {
        onSave(value ?? '');
      },
    );
  }
}
