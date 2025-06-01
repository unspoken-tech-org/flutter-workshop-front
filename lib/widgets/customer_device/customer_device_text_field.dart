import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/debouncer.dart';

class CustomerDeviceTextField extends StatefulWidget {
  final String? initialValue;
  final void Function(String value)? onUpdate;
  final bool enabled;
  final bool expandHeight;
  final bool isInvalid;

  const CustomerDeviceTextField({
    super.key,
    required this.initialValue,
    this.onUpdate,
    this.enabled = true,
    this.expandHeight = false,
    this.isInvalid = false,
  });

  @override
  State<CustomerDeviceTextField> createState() =>
      _CustomerDeviceTextFieldState();
}

class _CustomerDeviceTextFieldState extends State<CustomerDeviceTextField> {
  final TextEditingController _textEditingController = TextEditingController();
  final Debouncer _debouncer = Debouncer(milliseconds: 200);

  @override
  void didUpdateWidget(CustomerDeviceTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_textEditingController.text != widget.initialValue) {
      _textEditingController.text = widget.initialValue ?? '';
      setState(() {});
    }
  }

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
          borderSide: BorderSide(
            color: widget.isInvalid ? Colors.red : Colors.grey,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.isInvalid ? Colors.red : Colors.grey,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.isInvalid ? Colors.red : Colors.blue,
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.all(6),
      ),
    );
  }
}
