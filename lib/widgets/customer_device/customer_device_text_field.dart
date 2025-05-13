import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/debouncer.dart';

class CustomerDeviceTextField extends StatefulWidget {
  final String? initialValue;
  final void Function(String value)? onUpdate;
  final bool enabled;
  final bool expandHeight;

  const CustomerDeviceTextField({
    super.key,
    required this.initialValue,
    this.onUpdate,
    this.enabled = true,
    this.expandHeight = false,
  });

  @override
  State<CustomerDeviceTextField> createState() =>
      _CustomerDeviceTextFieldState();
}

class _CustomerDeviceTextFieldState extends State<CustomerDeviceTextField> {
  final TextEditingController _textEditingController = TextEditingController();
  final Debouncer _debouncer = Debouncer(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _textEditingController.text = widget.initialValue ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: widget.expandHeight ? null : 4,
      expands: widget.expandHeight,
      controller: _textEditingController,
      enabled: widget.enabled,
      textAlignVertical: TextAlignVertical.top,
      onChanged: (value) {
        _debouncer.run(() {
          widget.onUpdate?.call(value);
        });
      },
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.all(6),
      ),
    );
  }
}
