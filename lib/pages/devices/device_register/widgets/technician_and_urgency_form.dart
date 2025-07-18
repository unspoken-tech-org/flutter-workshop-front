import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/controller/device_register_controller.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/widgets/urgency_switch.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_dropdown_button_form_field.dart';

class TechnicianAndUrgencyForm extends StatelessWidget {
  final DeviceRegisterController controller;
  const TechnicianAndUrgencyForm({super.key, required this.controller});

  List<Technician> _getTechnicianSuggestions(
      DeviceRegisterController controller) {
    return controller.technicians.value;
  }

  @override
  Widget build(BuildContext context) {
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
              Icon(Icons.warning_amber_rounded),
              Text(
                'Responsável e Prioridade',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Row(
            spacing: 20,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: CustomDropdownButtonFormField(
                  hintText: 'Selecione um técnico',
                  items: _getTechnicianSuggestions(controller)
                      .map((technician) => technician.name.capitalizeAllWords)
                      .toList(),
                  onSave: (value) {
                    final technicianId = controller.technicians.value
                        .firstWhereOrNull(
                            (t) => t.name.toLowerCase() == value.toLowerCase())
                        ?.id;

                    controller.inputDevice = controller.inputDevice.copyWith(
                      technicianId: technicianId,
                    );
                  },
                ),
              ),
              Flexible(child: UrgencySwitch(onSaved: (value) {
                controller.inputDevice = controller.inputDevice.copyWith(
                  hasUrgency: value,
                );
              })),
            ],
          ),
        ],
      ),
    );
  }
}
