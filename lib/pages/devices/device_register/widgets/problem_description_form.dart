import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/controller/inherited_device_register_controller.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_text_field.dart';

class ProblemDescriptionForm extends StatelessWidget {
  const ProblemDescriptionForm({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceRegisterController.of(context);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            spacing: 8,
            children: [
              Icon(Icons.description_outlined),
              Text(
                'Descrição do Problema',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          CustomTextField(
            headerLabel: 'Problema',
            hintText: 'Descreva o problema relatado pelo cliente...',
            maxLines: 3,
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return 'O campo problema é obrigatório';
              }
              return null;
            },
            onSave: (value) {
              controller.inputDevice =
                  controller.inputDevice.copyWith(problem: value);
            },
          ),
          CustomTextField(
            headerLabel: 'Observações (Opcional)',
            hintText: 'Observações adicionais...',
            maxLines: 3,
            onSave: (value) {
              controller.inputDevice =
                  controller.inputDevice.copyWith(observation: value);
            },
          ),
        ],
      ),
    );
  }
}
