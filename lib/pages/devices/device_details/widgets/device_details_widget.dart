import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_text_field.dart';
import 'package:provider/provider.dart';

class DeviceDetailsWidget extends StatelessWidget {
  const DeviceDetailsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Selector<DeviceCustomerPageController, DeviceCustomer>(
        selector: (context, controller) => controller.deviceCustomer,
        builder: (context, deviceCustomer, child) => Column(
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
              headerLabel: 'Aparelho',
              readOnly: true,
              maxLines: 1,
              value:
                  '${deviceCustomer.typeName} ${deviceCustomer.brandName} | ${deviceCustomer.modelName}',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              headerLabel: 'Cores',
              readOnly: true,
              value: deviceCustomer.deviceColors.join(', '),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextField(
                    headerLabel: 'Data de entrada',
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
                      headerLabel: 'Data de saída',
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
      ),
    );
  }
}
