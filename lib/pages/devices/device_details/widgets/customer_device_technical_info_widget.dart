import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_dropdown_button_form_field.dart';
import 'package:provider/provider.dart';

class CustomerDeviceTechnicalInfoWidget extends StatelessWidget {
  final bool isEditing;
  const CustomerDeviceTechnicalInfoWidget({
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
          Selector<DeviceCustomerPageController,
              (DeviceCustomer, List<Technician>)>(
            selector: (context, controller) =>
                (controller.deviceCustomer, controller.technicians),
            builder: (context, values, child) {
              final (deviceCustomer, technicians) = values;

              return CustomDropdownButtonFormField(
                headerLabel: 'Técnico',
                value: deviceCustomer.technicianName?.capitalizeAllWords,
                items:
                    technicians.map((e) => e.name.capitalizeAllWords).toList(),
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
                  final controller =
                      context.read<DeviceCustomerPageController>();
                  final newDeviceCustomer = controller.deviceCustomer.copyWith(
                    technicianId: technician.id,
                    technicianName: technician.name,
                  );
                  controller.updateNewDeviceCustomer(newDeviceCustomer);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
