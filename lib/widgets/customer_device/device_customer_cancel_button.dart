import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';

class DeviceCustomerCancelButton extends StatelessWidget {
  final VoidCallback onCancel;
  const DeviceCustomerCancelButton({super.key, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onCancel,
      icon: const Icon(Icons.close),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.grey.shade500,
        iconColor: Colors.white,
      ),
      label: Text('Cancelar',
          style: WsTextStyles.body1.copyWith(color: Colors.white)),
    );
  }
}
