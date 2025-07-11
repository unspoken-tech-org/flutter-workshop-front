import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomerDeviceDetailTextField extends StatelessWidget {
  final String? label;
  final String? value;
  final IconData? icon;
  final TextEditingController? controller;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final String? prefixText;
  final int? maxLines;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(String?)? onSave;

  const CustomerDeviceDetailTextField({
    super.key,
    this.label,
    this.value,
    this.icon,
    this.controller,
    this.readOnly = false,
    this.inputFormatters,
    this.keyboardType,
    this.prefixText,
    this.maxLines,
    this.hintText,
    this.validator,
    this.onSave,
  }) : assert(value != null || controller != null,
            'Either value or controller must be provided.');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller ?? TextEditingController(text: value),
          readOnly: readOnly,
          inputFormatters: inputFormatters,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          onSaved: onSave,
          decoration: InputDecoration(
            hintText: hintText,
            prefixText: prefixText,
            prefixIcon: icon != null
                ? Icon(icon, size: 20, color: Colors.grey.shade600)
                : null,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
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
            fillColor: Colors.white,
            filled: true,
          ),
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
