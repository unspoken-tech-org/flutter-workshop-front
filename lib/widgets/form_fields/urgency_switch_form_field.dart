import 'package:flutter/material.dart';

class UrgencySwitchFormField extends StatelessWidget {
  final bool? initialValue;
  final FormFieldSetter<bool>? onSaved;
  final FormFieldValidator<bool>? validator;

  const UrgencySwitchFormField({
    super.key,
    this.initialValue,
    this.onSaved,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<bool>(
      initialValue: initialValue ?? false,
      onSaved: onSaved,
      validator: validator,
      builder: (FormFieldState<bool> field) {
        bool value = field.value ?? false;

        return Switch(
          thumbColor: WidgetStateProperty.all(Colors.white),
          activeTrackColor: Colors.black87,
          trackOutlineColor: WidgetStateProperty.all(
            value ? Colors.black87 : Colors.blueGrey.shade100,
          ),
          trackColor: WidgetStateProperty.all(
            value ? Colors.black87 : Colors.blueGrey.shade100,
          ),
          hoverColor: Colors.transparent,
          activeColor: Colors.white,
          inactiveTrackColor: Colors.blueGrey.shade100,
          value: field.value ?? false,
          onChanged: (value) {
            field.didChange(value);
          },
        );
      },
    );
  }
}
