import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/widgets/customer_device/form_fields/custom_text_field.dart';

class DeviceDetailsWidget extends StatelessWidget {
  final DeviceCustomer deviceCustomer;
  const DeviceDetailsWidget({super.key, required this.deviceCustomer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.build_outlined, color: Color(0xFF4B5563)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Detalhes do Aparelho',
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
          CustomTextField(
            label: 'Aparelho',
            readOnly: true,
            maxLines: 1,
            value:
                '${deviceCustomer.typeName} ${deviceCustomer.brandName} | ${deviceCustomer.modelName}',
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Cores',
            readOnly: true,
            value: deviceCustomer.deviceColors.join(', '),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Data de entrada',
                  readOnly: true,
                  maxLines: 1,
                  value: deviceCustomer.entryDate,
                  icon: Icons.calendar_today_outlined,
                ),
              ),
              if (deviceCustomer.departureDate != null) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    label: 'Data de saída',
                    readOnly: true,
                    maxLines: 1,
                    value: deviceCustomer.departureDate ?? '',
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}
