import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/inherited_device_customer_controller.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_dropdown_button_form_field.dart';

class CustomerDeviceTechnicalInfoWidget extends StatelessWidget {
  final bool isEditing;
  const CustomerDeviceTechnicalInfoWidget({
    super.key,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceCustomerController.of(context);
    final technicians = controller.technicians;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isEditing ? Colors.blue.shade300 : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.engineering, color: Color(0xFF4B5563)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Técnico Responsável',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CustomDropdownButtonFormField(
            headerLabel: 'Técnico',
            value: controller
                .deviceCustomer.value.technicianName?.capitalizeAllWords,
            items: technicians.map((e) => e.name.capitalizeAllWords).toList(),
            enabled: isEditing,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Selecione um técnico';
              }
              return null;
            },
            onSave: (value) {
              final technician = technicians.firstWhere(
                (e) => e.name.capitalizeAllWords == value,
              );
              controller.updateNewDeviceCustomer(
                controller.deviceCustomer.value.copyWith(
                  technicianId: technician.id,
                  technicianName: technician.name,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
