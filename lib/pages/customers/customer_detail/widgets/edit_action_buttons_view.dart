import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/controllers/customer_detail_controller.dart';
import 'package:provider/provider.dart';

class EditActionButtons extends StatelessWidget {
  const EditActionButtons({
    super.key,
    required this.customerId,
    required this.onCancel,
    required this.onSave,
  });

  final int customerId;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CustomerDetailController>();
    final isEditing = controller.isEditing;

    if (isEditing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () {
              onCancel();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              foregroundColor: Colors.black87,
              backgroundColor: Colors.white.withAlpha(230),
            ),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () async {
              onSave();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salvar'),
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () => controller.setEditing(true),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            foregroundColor: Colors.black87,
            backgroundColor: Colors.white.withAlpha(230),
          ),
          child: const Text('Editar'),
        ),
      ],
    );
  }
}
