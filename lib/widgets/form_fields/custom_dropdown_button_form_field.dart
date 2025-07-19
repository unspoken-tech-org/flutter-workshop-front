import 'package:flutter/material.dart';

class CustomDropdownButtonFormField extends StatelessWidget {
  final String? headerLabel;
  final String? fieldLabel;
  final String? hintText;
  final List<String> items;
  final String? value;
  final void Function(String value)? onSave;
  final void Function(String? value)? onChanged;
  final String? Function(String? value)? validator;
  final bool enabled;

  const CustomDropdownButtonFormField({
    super.key,
    this.headerLabel,
    this.fieldLabel,
    this.hintText,
    required this.items,
    this.onSave,
    this.value,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headerLabel != null) ...[
          Text(
            headerLabel!,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            labelText: fieldLabel,
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
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
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 14,
                      ),
                    ),
                  ))
              .toList(),
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 14,
          ),
          onChanged: !enabled ? null : (onChanged ?? (value) {}),
          validator: validator,
          onSaved: (value) {
            onSave?.call(value ?? '');
          },
        ),
      ],
    );
  }
}
