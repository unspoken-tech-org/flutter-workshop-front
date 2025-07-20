import 'package:flutter/material.dart';

class SwitchFormField extends StatefulWidget {
  final bool? initialValue;
  final FormFieldSetter<bool>? onSaved;
  final void Function(bool value)? onChanged;
  final FormFieldValidator<bool>? validator;

  const SwitchFormField({
    super.key,
    this.initialValue,
    this.onSaved,
    this.onChanged,
    this.validator,
  });

  @override
  State<SwitchFormField> createState() => _SwitchFormFieldState();
}

class _SwitchFormFieldState extends State<SwitchFormField> {
  final _key = GlobalKey<FormFieldState<bool>>();

  @override
  void didUpdateWidget(covariant SwitchFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _key.currentState?.didChange(widget.initialValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<bool>(
      key: _key,
      initialValue: widget.initialValue ?? false,
      onSaved: widget.onSaved,
      validator: widget.validator,
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
            widget.onChanged?.call(value);
          },
        );
      },
    );
  }
}
