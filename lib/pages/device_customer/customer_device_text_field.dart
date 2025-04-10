import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/debouncer.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/device_customer/inherited_device_customer_controller.dart';

class CustomerDeviceTextField extends StatefulWidget {
  final String? initialValue;
  final void Function(String value) onUpdate;

  const CustomerDeviceTextField({
    super.key,
    required this.initialValue,
    required this.onUpdate,
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
      maxLines: 4,
      controller: _textEditingController,
      onChanged: (value) {
        _debouncer.run(() {
          widget.onUpdate(value);
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
