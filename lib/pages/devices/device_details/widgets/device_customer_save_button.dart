import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';

class DeviceCustomerSaveButton extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onSave;
  final VoidCallback onEdit;

  /// Salvamento em andamento: desabilita o botão e troca o ícone por progresso.
  final bool isSaving;
  const DeviceCustomerSaveButton({
    super.key,
    required this.onSave,
    required this.onEdit,
    this.isEditing = false,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: isEditing ? 'deviceDetail.save' : 'deviceDetail.edit',
      child: TextButton.icon(
        onPressed: isSaving ? null : (isEditing ? onSave : onEdit),
        icon: isSaving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(isEditing ? Icons.save : Icons.edit),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: isEditing ? Colors.blueAccent : Colors.grey,
          disabledBackgroundColor: Colors.blueAccent.withAlpha(150),
          iconColor: Colors.white,
        ),
        label: Text(
          isEditing ? 'Salvar' : 'Editar',
          style: WsTextStyles.body1.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
