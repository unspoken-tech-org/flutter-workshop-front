import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_text_field.dart';
import 'package:provider/provider.dart';

class CustomerDeviceObservationWidget extends StatelessWidget {
  final bool isEditing;
  const CustomerDeviceObservationWidget({
    super.key,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
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
          Selector<DeviceCustomerPageController, DeviceCustomer>(
            selector: (context, controller) => controller.deviceCustomer,
            builder: (context, deviceCustomer, child) => CustomTextField(
              controller:
                  TextEditingController(text: deviceCustomer.observation),
              readOnly: !isEditing,
              hintText: 'Descreva a observação...',
              maxLines: 4,
              onSave: (value) {
                final controller = context.read<DeviceCustomerPageController>();
                final newDeviceCustomer =
                    controller.deviceCustomer.copyWith(observation: value);
                controller.updateNewDeviceCustomer(newDeviceCustomer);
              },
            ),
          ),
        ],
      ),
    );
  }
}
