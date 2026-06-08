import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_colors.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';

class ActionButtonsWidget extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController dateController;
  final void Function() onSave;

  const ActionButtonsWidget({
    super.key,
    required this.formKey,
    required this.dateController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () {
            formKey.currentState?.reset();
            dateController.clear();
          },
          child: const Text('Limpar'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: WsColors.dark,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              formKey.currentState?.save();
              onSave();
              Navigator.of(context).pop();
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class SectionTileWidget extends StatelessWidget {
  const SectionTileWidget({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(title, style: WsTextStyles.h4),
      ],
    );
  }
}
