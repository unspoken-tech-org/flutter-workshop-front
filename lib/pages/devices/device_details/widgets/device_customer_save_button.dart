import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';

class DeviceCustomerSaveButton extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onSave;
  final VoidCallback onEdit;
  const DeviceCustomerSaveButton({
    super.key,
    required this.onSave,
    required this.onEdit,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: isEditing ? onSave : onEdit,
      icon: Icon(isEditing ? Icons.save : Icons.edit),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: isEditing ? Colors.blueAccent : Colors.grey,
        iconColor: Colors.white,
      ),
      label: Text(isEditing ? 'Salvar' : 'Editar',
          style: WsTextStyles.body1.copyWith(color: Colors.white)),
    );
  }
}
