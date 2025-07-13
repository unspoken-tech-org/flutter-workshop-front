import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/inherited_device_customer_controller.dart';
import 'package:flutter_workshop_front/widgets/customer_device/form_fields/custom_text_field.dart';

class CustomerDeviceObservationWidget extends StatelessWidget {
  final String observation;
  final bool isEditing;
  const CustomerDeviceObservationWidget({
    super.key,
    required this.observation,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceCustomerController.of(context);
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
              Icon(Icons.remove_red_eye_outlined, color: Color(0xFF4B5563)),
              SizedBox(width: 12),
              Text(
                'Observações',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CustomTextField(
            controller: TextEditingController(text: observation),
            readOnly: !isEditing,
            hintText: 'Descreva a observação...',
            maxLines: 4,
            onSave: (value) {
              controller.updateNewDeviceCustomer(
                controller.deviceCustomer.value.copyWith(observation: value),
              );
            },
          ),
        ],
      ),
    );
  }
}
